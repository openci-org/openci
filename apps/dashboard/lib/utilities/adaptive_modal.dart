import 'package:dashboard/theme/app_colors.dart';
import 'package:dashboard/utilities/breakpoint.dart';
import 'package:flutter/material.dart';

const double _formDialogMaxWidth = 480;
const double _formDialogMaxHeight = 720;
const double _formDialogInset = 24;

Future<T?> showAdaptiveFormModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double maxWidth = _formDialogMaxWidth,
  double maxHeight = _formDialogMaxHeight,
}) {
  final colors = AppColors.of(context);

  if (usesBottomSheetFormModal(context)) {
    return showModalBottomSheet<T>(
      showDragHandle: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.scaffold,
      builder: builder,
    );
  }

  return showDialog<T>(
    context: context,
    builder: (dialogContext) {
      final availableHeight =
          MediaQuery.sizeOf(dialogContext).height - (_formDialogInset * 2);
      final effectiveMaxHeight =
          availableHeight > 0 && availableHeight < maxHeight
          ? availableHeight
          : maxHeight;

      return Dialog(
        backgroundColor: colors.scaffold,
        insetPadding: const EdgeInsets.all(_formDialogInset),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: effectiveMaxHeight,
          ),
          child: builder(dialogContext),
        ),
      );
    },
  );
}

bool usesBottomSheetFormModal(BuildContext context) {
  return Breakpoint.fromWidth(MediaQuery.sizeOf(context).width) ==
      Breakpoint.mobile;
}
