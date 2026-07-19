import 'package:flutter/material.dart';

extension CircularProgressIndicatorExtensions on CircularProgressIndicator {
  Widget withCenter() => Center(child: this);

  Widget withScaffoldCenter() => Scaffold(
    body: withCenter(),
  );
}
