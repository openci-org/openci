import 'package:flutter/material.dart';

class BaseChip extends StatelessWidget {
  const BaseChip({
    super.key,
    required this.child,
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
    this.onTap,
  });

  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = DefaultTextStyle.merge(
      style: TextStyle(
        color: foregroundColor,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      child: IconTheme.merge(
        data: IconThemeData(color: foregroundColor),
        child: child,
      ),
    );

    return Material(
      color: backgroundColor,
      shape: StadiumBorder(side: BorderSide(color: borderColor)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        mouseCursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        hoverColor: foregroundColor.withValues(alpha: 0.08),
        splashColor: foregroundColor.withValues(alpha: 0.12),
        highlightColor: foregroundColor.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: content,
        ),
      ),
    );
  }
}
