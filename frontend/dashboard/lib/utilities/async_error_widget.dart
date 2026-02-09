import 'package:flutter/material.dart';

Widget asyncErrorWidget(Object error, StackTrace stackTrace) {
  debugPrint('Error: $error');
  debugPrint('Stack Trace: $stackTrace');
  return Center(
    child: Text('Error: $error'),
  );
}
