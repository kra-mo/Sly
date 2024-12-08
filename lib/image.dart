import 'dart:typed_data';
import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:image/image.dart' as img;

import '/io.dart';

enum SlyImageFlipDirection { horizontal, vertical, both }

enum SlyImageFormat { png, jpeg75, jpeg90, jpeg100, tiff }

class SlyImageAttribute {
  final String name;
  double value;
  final double anchor;
  final double min;
  final double max;

  SlyImageAttribute(this.name, this.value, this.anchor, this.min, this.max);

  SlyImageAttribute.copy(SlyImageAttribute imageAttribute)
      : this(
          imageAttribute.name,
          imageAttribute.value,
          imageAttribute.anchor,
          imageAttribute.min,
          imageAttribute.max,
        );
}

class SlyImage {
  StreamController<String> controller = StreamController<String>();

  img.Image _originalImage;
  img.Image _image;
  num _editsApplied = 0;
  int _loading = 0;

  Map<String, SlyImageAttribute> lightAttributes = {
    'exposure': SlyImageAttribute('Exposure', 0, 0, 0, 1),
    'brightness': SlyImageAttribute('Brightness', 1, 1, 0.2, 1.8),
    'contrast': SlyImageAttribute('Contrast', 1, 1, 0.4, 1.6),
    'blacks': SlyImageAttribute('Blacks', 0, 0, 0, 127.5),
    'whites': SlyImageAttribute('Whites', 255, 255, 76.5, 255),
    'mids': SlyImageAttribute('Midtones', 127.5, 127.5, 25.5, 229.5),
  };

  Map<String, SlyImageAttribute> colorAttributes = {
    'saturation': SlyImageAttribute('Saturation', 1, 1, 0, 2),
    'temp': SlyImageAttribute('Temperature', 0, 0, -1, 1),
    'tint': SlyImageAttribute('Tint', 0, 0, -1, 1),
  };

  Map<String, SlyImageAttribute> effectAttributes = {
    'denoise': SlyImageAttribute('Noise Reduction', 0, 0, 0, 1),
    'sharpness': SlyImageAttribute('Sharpness', 0, 0, 0, 1),
    'sepia': SlyImageAttribute('Sepia', 0, 0, 0, 1),
    'vignette': SlyImageAttribute('Vignette', 0, 0, 0, 1),
    'border': SlyImageAttribute('Border', 0, 0, -1, 1),
  };

  int get width {
    return _image.width;
  }

  int get height {
    return _image.height;
  }

  bool get loading {
    return _loading > 0;
  }

  /// True if the image is small enough and the device is powerful enough to load it.
  bool get canLoadFullRes {
    return (!kIsWeb && _originalImage.height <= 2000) ||
        _originalImage.height <= 500;
  }

  /// Creates a new `SlyImage` from another `src`.
  ///
  /// Note that if `src` is in the process of loading, the copied image might stay at a lower resolution
  /// until `applyEdits` or `applyEditsProgressive` is called on `this`.
  SlyImage.from(SlyImage src)
      : _image = img.Image.from(src._image),
        _originalImage = img.Image.from(src._originalImage) {
    copyEditsFrom(src);
  }

  /// Creates a new `SlyImage` from `image`.
  ///
  /// The `image` object is reused, so calling `.from`
  /// before invoking this constructor might be necessary
  /// if you plan on reuising `image`.
  SlyImage._fromImage(img.Image image)
      : _image = img.Image.from(image),
        _originalImage = image;

  /// Creates a new `SlyImage` from `data`.
  static Future<SlyImage?> fromData(Uint8List data) async {
    final imgImage = await loadImgImage(data);
    if (imgImage == null) return null;

    return SlyImage._fromImage(imgImage);
  }

  /// Applies changes to the image's attrubutes.
  Future<void> applyEdits() async {
    _loading += 1;
    final applied = DateTime.now().millisecondsSinceEpoch;
    _editsApplied = applied;

    final editedImage =
        (await _buildEditCommand(_originalImage).executeThread()).outputImage;

    _loading -= 1;

    if (editedImage == null) return;

    if (_editsApplied > applied) return;

    if (controller.isClosed) return;

    _image = editedImage;
    controller.add('updated');
  }

  /// Applies changes to the image's attrubutes, progressively.
  ///
  /// The edits will first be applied to a <=500px tall thumbnail for fast preview.
  ///
  /// Finally, when ready, the image will be returned at the original size
  /// if the device can render such a large image.
  ///
  /// You can check this with `this.canLoadFullRes`.
  Future<void> applyEditsProgressive() async {
    _loading += 1;
    final applied = DateTime.now().millisecondsSinceEpoch;
    _editsApplied = applied;

    final List<Future<img.Image>> images = [];

    if (_originalImage.height > 700 ||
        (kIsWeb && _originalImage.height > 500)) {
      images.add(_getResizedImage(_originalImage, null, 500));
    }

    if (canLoadFullRes) {
      images.add(Future.value(_originalImage));
    } else if (!kIsWeb) {
      images.add(_getResizedImage(_originalImage, null, 1500));
    }

    for (Future<img.Image> editableImage in images) {
      if (_editsApplied > applied) {
        _loading -= 1;
        return;
      }

      final editedImage =
          (await _buildEditCommand(await editableImage).executeThread())
              .outputImage;
      if (editedImage == null) {
        _loading -= 1;
        return;
      }

      if (_editsApplied > applied) {
        _loading -= 1;
        return;
      }

      if (controller.isClosed) {
        _loading -= 1;
        return;
      }

      _image = editedImage;
      controller.add('updated');
    }

    _loading -= 1;
  }

  /// Copies Exif metadata from `src` to the image.
  void copyMetadataFrom(SlyImage src) {
    _image.exif = img.ExifData.from(src._image.exif);
    _originalImage.exif = img.ExifData.from(src._originalImage.exif);
  }

  /// Copies edits from `src` to the image.
  ///
  /// Note that if you want to see the changes,
  /// you need to call `applyEdits` or `applyEditsProgressive` yourself.
  void copyEditsFrom(SlyImage src) {
    for (int i = 0; i < 3; i++) {
      for (MapEntry<String, SlyImageAttribute> entry in [
        src.lightAttributes,
        src.colorAttributes,
        src.effectAttributes,
      ][i]
          .entries) {
        [lightAttributes, colorAttributes, effectAttributes][i][entry.key] =
            SlyImageAttribute.copy(entry.value);
      }
    }
  }

  /// Removes Exif metadata from the image.
  void removeMetadata() {
    _image.exif = img.ExifData();
    _originalImage.exif = img.ExifData();
  }

  /// Flips the image in `direction`.
  void flip(SlyImageFlipDirection direction) {
    final img.FlipDirection imgFlipDirection;

    switch (direction) {
      case SlyImageFlipDirection.horizontal:
        imgFlipDirection = img.FlipDirection.horizontal;
      case SlyImageFlipDirection.vertical:
        imgFlipDirection = img.FlipDirection.vertical;
      case SlyImageFlipDirection.both:
        imgFlipDirection = img.FlipDirection.both;
    }

    img.flip(_image, direction: imgFlipDirection);
    img.flip(_originalImage, direction: imgFlipDirection);
  }

  /// Rotates the image by `degree`
  void rotate(num degree) {
    if (degree == 360) return;

    _image = img.copyRotate(
      _image,
      angle: degree,
      interpolation: img.Interpolation.cubic,
    );
    _originalImage = img.copyRotate(
      _originalImage,
      angle: degree,
      interpolation: img.Interpolation.cubic,
    );
  }

  /// Crops the image to `rect`, normalized between 0 and 1.
  ///
  /// Note that the original image can never be recovered after this method call
  /// so it is recommended to make a copy of it if that is needed.
  ///
  /// Also note that if you want to see the changes,
  /// you need to call `applyEdits` or `applyEditsProgressive` yourself.
  Future<void> crop(Rect rect) async {
    final cmd = img.Command()
      ..image(_originalImage)
      ..copyCrop(
        x: (rect.left * width).round(),
        y: (rect.top * height).round(),
        width: (rect.width * width).round(),
        height: (rect.height * height).round(),
      );

    final croppedImage = (await cmd.executeThread()).outputImage;
    if (croppedImage == null) return;

    _originalImage = croppedImage;
  }

  /// Returns the image encoded as `format`.
  ///
  /// Available formats are:
  /// - `png`
  /// - `jpeg100` - Quality 100
  /// - `jpeg90` - Quality 90
  /// - `jpeg75` - Quality 75
  /// - `tiff`
  ///
  /// If `fullRes` is not true, a lower resolution image might be returned
  /// if it looks like the device could not handle loading the entire image.
  ///
  /// You can check this with `this.canLoadFullRes`.
  ///
  /// `maxSideLength` defines the maximum length of the shorter side
  /// of the image in pixels. Unlimited (depending on `fullRes`) if omitted.
  Future<Uint8List> encode({
    SlyImageFormat? format = SlyImageFormat.png,
    bool fullRes = false,
    int? maxSideLength,
  }) async {
    if (fullRes && !canLoadFullRes) {
      await applyEdits();
    }

    final cmd = img.Command()..image(_image);

    if (maxSideLength != null &&
        (height > maxSideLength || width < maxSideLength)) {
      if (height > width) {
        cmd.copyResize(
          height: maxSideLength,
          interpolation: img.Interpolation.average,
        );
      } else {
        cmd.copyResize(
          width: maxSideLength,
          interpolation: img.Interpolation.average,
        );
      }
    }

    switch (format) {
      case SlyImageFormat.png:
        cmd.encodePng();
      case SlyImageFormat.jpeg75:
        cmd.encodeJpg(quality: 75);
      case SlyImageFormat.jpeg90:
        cmd.encodeJpg(quality: 90);
      case SlyImageFormat.jpeg100:
        cmd.encodeJpg(quality: 100);
      case SlyImageFormat.tiff:
        cmd.encodeTiff();
      default:
        cmd.encodePng();
    }

    return (await cmd.executeThread()).outputBytes!;
  }

  /// Returns a short list representing the RGB colors across the image,
  /// useful for building a histogram.
  Future<Uint8List> getHistogramData() async {
    final cmd = img.Command()
      ..image(_image)
      ..copyResize(width: 20, height: 20)
      ..convert(numChannels: 3);

    return (await cmd.executeThread()).outputImage!.buffer.asUint8List();
  }

  void dispose() {
    controller.close();
    _editsApplied = double.infinity;
  }

  img.Command _buildEditCommand(img.Image editableImage) {
    final cmd = img.Command()
      ..image(editableImage)
      ..copy();

    final temp = colorAttributes['temp']!;
    final tint = colorAttributes['tint']!;

    for (SlyImageAttribute attribute in [temp, tint]) {
      if (attribute.value != attribute.anchor) {
        cmd.colorOffset(
          red: 50 * temp.value,
          green: 50 * tint.value * -1,
          blue: 50 * temp.value * -1,
        );
        break;
      }
    }

    final exposure = lightAttributes['exposure']!;
    final brightness = lightAttributes['brightness']!;
    final contrast = lightAttributes['contrast']!;
    final saturation = colorAttributes['saturation']!;
    final blacks = lightAttributes['blacks']!;
    final whites = lightAttributes['whites']!;
    final mids = lightAttributes['mids']!;

    for (SlyImageAttribute attribute in [
      exposure,
      brightness,
      contrast,
      saturation,
      blacks,
      whites,
      mids,
    ]) {
      if (attribute.value != attribute.anchor) {
        final b = blacks.value.round();
        final w = whites.value.round();
        final m = mids.value.round();

        cmd.adjustColor(
          exposure: exposure.value != exposure.anchor ? exposure.value : null,
          brightness:
              brightness.value != brightness.anchor ? brightness.value : null,
          contrast: contrast.value != contrast.anchor ? contrast.value : null,
          saturation:
              saturation.value != saturation.anchor ? saturation.value : null,
          blacks: img.ColorUint8.rgb(b, b, b),
          whites: img.ColorUint8.rgb(w, w, w),
          mids: img.ColorUint8.rgb(m, m, m),
        );
        break;
      }
    }

    final sepia = effectAttributes['sepia']!;
    if (sepia.value != sepia.anchor) {
      cmd.sepia(amount: sepia.value);
    }

    final denoise = effectAttributes['denoise']!;
    if (denoise.value != denoise.anchor) {
      cmd.convolution(
        filter: [
          1 / 16,
          2 / 16,
          1 / 16,
          2 / 16,
          4 / 16,
          2 / 16,
          1 / 16,
          2 / 16,
          1 / 16,
        ],
        amount: denoise.value,
      );
    }

    final sharpness = effectAttributes['sharpness']!;
    if (sharpness.value != sharpness.anchor) {
      cmd.convolution(
        filter: [0, -1, 0, -1, 5, -1, 0, -1, 0],
        amount: sharpness.value,
      );
    }

    final vignette = effectAttributes['vignette']!;
    if (vignette.value != vignette.anchor) {
      cmd.vignette(amount: vignette.value);
    }

    final border = effectAttributes['border']!;
    if (border.value != border.anchor) {
      cmd.copyExpandCanvas(
          backgroundColor: border.value > 0
              ? img.ColorRgb8(255, 255, 255)
              : img.ColorRgb8(0, 0, 0),
          padding: (border.value.abs() * (editableImage.width / 3)).round());
    }

    return cmd;
  }
}

Future<img.Image> _getResizedImage(
  img.Image image,
  int? width,
  int? height,
) async {
  final cmd = img.Command()
    ..image(image)
    ..copyResize(
      width: width,
      height: height,
      interpolation: img.Interpolation.average,
    );

  return (await cmd.executeThread()).outputImage!;
}
