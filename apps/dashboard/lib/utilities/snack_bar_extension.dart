import 'dart:async';

import 'package:dashboard/utilities/breakpoint.dart';
import 'package:flutter/material.dart';

const double _snackBarMaxWidth = 420;
const double _snackBarHorizontalMargin = 16;
const double _desktopToastEdgeMargin = 24;
const Duration _snackBarDefaultDuration = Duration(milliseconds: 4000);
const Duration _desktopToastAnimationDuration = Duration(milliseconds: 180);

OverlayEntry? _activeDesktopToastEntry;

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
  final width = MediaQuery.sizeOf(context).width;
  final breakpoint = Breakpoint.fromWidth(width);
  final overlay = Overlay.maybeOf(context);

  if (breakpoint == Breakpoint.desktop && overlay != null) {
    ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
    _activeDesktopToastEntry?.remove();

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _DesktopToastSnackBar(
        content: content,
        duration: effectiveDuration,
        onDismissed: () {
          if (_activeDesktopToastEntry == entry) {
            _activeDesktopToastEntry = null;
          }
          entry.remove();
        },
      ),
    );
    _activeDesktopToastEntry = entry;
    overlay.insert(entry);
    return;
  }

  _activeDesktopToastEntry?.remove();
  _activeDesktopToastEntry = null;
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

class _DesktopToastSnackBar extends StatefulWidget {
  const _DesktopToastSnackBar({
    required this.content,
    required this.duration,
    required this.onDismissed,
  });

  final Widget content;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_DesktopToastSnackBar> createState() => _DesktopToastSnackBarState();
}

class _DesktopToastSnackBarState extends State<_DesktopToastSnackBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  Timer? _dismissTimer;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _desktopToastAnimationDuration,
      reverseDuration: _desktopToastAnimationDuration,
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    unawaited(_controller.forward());
    _dismissTimer = Timer(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (_dismissing) {
      return;
    }
    _dismissing = true;
    await _controller.reverse();
    if (mounted) {
      widget.onDismissed();
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final textStyle =
        Theme.of(context).snackBarTheme.contentTextStyle ??
        Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white) ??
        const TextStyle(color: Colors.white);

    return Positioned(
      top: padding.top + _desktopToastEdgeMargin,
      right: padding.right + _desktopToastEdgeMargin,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _opacity,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            color:
                Theme.of(context).snackBarTheme.backgroundColor ??
                const Color(0xFF323232),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _snackBarMaxWidth),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: DefaultTextStyle(
                  style: textStyle,
                  child: IconTheme(
                    data: const IconThemeData(color: Colors.white),
                    child: widget.content,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
