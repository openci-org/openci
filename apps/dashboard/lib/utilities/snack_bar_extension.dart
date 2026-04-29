import 'package:flutter/material.dart';

const double _snackBarMaxWidth = 420;
const double _snackBarHorizontalMargin = 16;
const Duration _snackBarDefaultDuration = Duration(milliseconds: 4000);

double? responsiveSnackBarWidth(BuildContext context) {
  final availableWidth =
      MediaQuery.sizeOf(context).width - (_snackBarHorizontalMargin * 2);
  return availableWidth > _snackBarMaxWidth ? _snackBarMaxWidth : null;
}

SnackBar responsiveSnackBar(
  BuildContext context, {
  required Widget content,
  Duration? duration,
}) {
  return SnackBar(
    content: content,
    behavior: SnackBarBehavior.floating,
    width: responsiveSnackBarWidth(context),
    duration: duration ?? _snackBarDefaultDuration,
  );
}

extension SnackBarExtension on BuildContext {
  void showSnackBarMessage(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      responsiveSnackBar(
        this,
        content: Text(message),
      ),
    );
  }
}
