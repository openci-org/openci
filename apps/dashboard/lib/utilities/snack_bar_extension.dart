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

void showResponsiveSnackBar(
  BuildContext context, {
  required Widget content,
  Duration? duration,
}) {
  final effectiveDuration = duration ?? _snackBarDefaultDuration;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      responsiveSnackBar(
        context,
        content: content,
        duration: effectiveDuration,
      ),
    );
}

extension SnackBarExtension on BuildContext {
  void showSnackBarMessage(String message) {
    showResponsiveSnackBar(
      this,
      content: Text(message),
    );
  }
}
