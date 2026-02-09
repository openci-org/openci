import 'package:flutter/material.dart';

extension SnackBarExtension on BuildContext {
  void showSnackBarMessage(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
