import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:crop_image/crop_image.dart';
import 'package:image_picker/image_picker.dart';

import '/image.dart';
import '/widgets/spinner.dart';
import '/widgets/snack_bar.dart';
import '/widgets/unique/editor.dart';

/// Manages loading and switching between multiple images.
class SlyJuggler {
  StreamController<String> controller = StreamController<String>();
  final List<Map<String, dynamic>?> images = [];

  late final List<Widget> carouselChildren = [
    const ImageIcon(
      AssetImage('assets/icons/add.webp'),
      semanticLabel: 'Add Images',
    ),
  ];

  int _selected = 0;
  get selected => _selected;
  set selected(value) {
    _selected = value;
    editedImage ??= SlyImage.from(originalImage);
    controller.add('new image');
  }

  SlyImage get originalImage => images[selected]?['originalImage'];

  SlyImage? get editedImage => images[selected]?['editedImage'];
  set editedImage(value) {
    images[selected]?['editedImage'] = value;
    images[selected]?['cropController'] = cropController ?? CropController();
    subscription?.cancel();
    images[selected]?['subscription'] =
        editedImage!.controller.stream.listen((event) => controller.add(event));
  }

  CropController? get cropController => images[selected]?['cropController'];
  StreamSubscription<String>? get subscription =>
      images[selected]?['subscription'];

  /// Creates a Juggler without any initial images.
  ///
  /// Call `editImages` with a set of images to start editing.
  SlyJuggler();

  /// Adds an image to the Juggler and updates the Carousel.
  void addImage(SlyImage image) {
    images.insert(0, {'originalImage': image});
    carouselChildren.insert(
      1,
      FutureBuilder<Uint8List>(
        future: image.encode(
          format: SlyImageFormat.jpeg75,
          maxSideLength: 150,
        ),
        builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
          if (snapshot.hasData) {
            return Image.memory(snapshot.data!, fit: BoxFit.cover);
          } else if (snapshot.hasError) {
            return Container();
          } else {
            return const SizedBox(
              width: 24,
              height: 24,
              child: SlySpinner(),
            );
          }
        },
      ),
    );
    controller.add('image added');
  }

  /// Used to pick new images to edit or to select existing ones.
  ///
  /// When used *without* `newSelection`, it will prompt the user
  /// to pick a new set of images from their gallery.
  ///
  /// When used *with* `newSelection`, it will select
  /// the image at that index for editing.
  Future<void> editImages({
    required BuildContext context,
    VoidCallback? loadingCallback,
    VoidCallback? failedCallback,
    bool animate = true,
    int? newSelection,
  }) async {
    if (newSelection == null) {
      final ImagePicker picker = ImagePicker();
      final List<XFile> files = await picker.pickMultiImage();

      if (files.isEmpty) {
        if (failedCallback != null) failedCallback();
        return;
      }

      if (!context.mounted) {
        if (failedCallback != null) failedCallback();
        return;
      }
      if (loadingCallback != null) loadingCallback();

      final List<SlyImage> newImages = [];
      for (final file in files) {
        final image = await SlyImage.fromData(await file.readAsBytes());
        if (image == null) {
          if (failedCallback != null) failedCallback();

          if (!context.mounted) return;
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          showSlySnackBar(context, 'Couldn’t Load Image');
          return;
        }

        newImages.add(image);
      }

      if (!context.mounted) {
        if (failedCallback != null) failedCallback();
        return;
      }

      if (images.isEmpty) {
        for (final image in newImages) {
          addImage(image);
        }
        selected = 0;

        Navigator.pushReplacement(
          context,
          animate
              ? MaterialPageRoute(
                  builder: (context) => SlyEditorPage(juggler: this),
                )
              : PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      SlyEditorPage(juggler: this),
                ),
        );
      } else {
        for (final image in newImages) {
          addImage(image);
        }
        selected = 0;
      }
    } else {
      selected = newSelection;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }
}
