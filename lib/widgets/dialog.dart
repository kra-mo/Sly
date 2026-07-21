import 'package:flutter/material.dart';

import '/layout.dart';
import '/widgets/button.dart';

/// Presents a dialog with `title` and `children` underneath it.
///
/// On smaller screens, the dialog is presented as a bottom sheet.
///
/// If it is not required to complete the action inside the dialog,
/// consider adding a `SlyCancelButton` to the end of `children`
/// for the user to be able to exit the dialog conveniently.
///
/// Children have pre-baked spacing between them, if that is not desired,
/// consider passing in a single child with your own padding.
Future<void> showSlyDialog(
  BuildContext context,
  String title,
  List<Widget> children, {
  bool hideTitle = false,
}) async {
  if (isWide(context)) {
    await showGeneralDialog(
      barrierDismissible: true,
      barrierLabel: 'title',
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) {
        return SimpleDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 24,
          ),
          contentPadding: const EdgeInsets.only(
            bottom: 24,
            left: 24,
            right: 24,
          ),
          titlePadding: const EdgeInsets.only(
            top: 32,
            bottom: 20,
            left: 16,
            right: 16,
          ),
          title: hideTitle
              ? null
              : Center(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
          children: children
              .asMap()
              .entries
              .map(
                (entry) => entry.key == children.length - 1
                    ? entry.value
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: entry.value,
                      ),
              )
              .toList(),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, widget) {
        final animIn = animation.status == AnimationStatus.forward;

        return FadeTransition(
          opacity: animation.drive(
            Tween(begin: 0.0, end: 1.0).chain(
              CurveTween(
                curve: animIn ? Curves.easeOutExpo : Curves.easeInOutQuint,
              ),
            ),
          ),
          child: ScaleTransition(
            scale: animation.drive(
              Tween(begin: animIn ? 1.2 : 1.6, end: 1.0).chain(
                CurveTween(
                  curve: animIn ? Curves.easeOutBack : Curves.easeOutQuint,
                ),
              ),
            ),
            child: widget,
          ),
        );
      },
    );
  } else {
    await showModalBottomSheet(
      barrierLabel: title,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      constraints: const BoxConstraints(maxWidth: 480),
      isScrollControlled: true,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: [
            if (!hideTitle)
              Padding(
                padding: const EdgeInsets.only(
                  top: 32,
                  bottom: 20,
                  left: 16,
                  right: 16,
                ),
                child: Center(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            ListView.separated(
              padding: const EdgeInsets.only(bottom: 32, left: 24, right: 24),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: children.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) => children[index],
            ),
          ],
        );
      },
    );
  }
}

class SlyCancelButton extends StatelessWidget {
  final String? label;
  final bool suggested;

  /// A button to dismiss a dialog.
  ///
  /// If the `label` parameter is not provided, it will be 'Cancel'.
  const SlyCancelButton({super.key, this.label, this.suggested = true});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: SlyButton(
      suggested: suggested,
      onPressed: () => Navigator.pop(context),
      child: Text(label ?? 'Cancel'),
    ),
  );
}
