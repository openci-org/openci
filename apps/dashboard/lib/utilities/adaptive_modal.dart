import 'package:dashboard/theme/app_colors.dart';
import 'package:flutter/material.dart';

Future<T?> showAdaptiveFormModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double? maxWidth,
  double? maxHeight,
}) {
  final colors = AppColors.of(context);

  return showModalBottomSheet<T>(
    showDragHandle: true,
    context: context,
    isScrollControlled: true,
    backgroundColor: colors.scaffold,
    builder: builder,
  );
}

bool usesBottomSheetFormModal(BuildContext context) {
  return true;
}
