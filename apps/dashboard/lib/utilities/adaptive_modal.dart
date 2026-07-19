import 'package:flutter/material.dart';

Future<T?> showAdaptiveFormModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double? maxWidth,
  double? maxHeight,
}) {
  return showModalBottomSheet<T>(
    showDragHandle: true,
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    builder: builder,
  );
}

bool usesBottomSheetFormModal(BuildContext context) {
  return true;
}
