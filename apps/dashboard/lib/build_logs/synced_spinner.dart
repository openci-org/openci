import 'package:flutter/material.dart';

class SyncedSpinnerScope extends StatefulWidget {
  const SyncedSpinnerScope({super.key, required this.child});
  final Widget child;

  @override
  State<SyncedSpinnerScope> createState() => _SyncedSpinnerScopeState();
}

class _SyncedSpinnerScopeState extends State<SyncedSpinnerScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SyncedSpinnerInherited(
      controller: _controller,
      child: widget.child,
    );
  }
}

class _SyncedSpinnerInherited extends InheritedWidget {
  const _SyncedSpinnerInherited({
    required this.controller,
    required super.child,
  });

  final AnimationController controller;

  static AnimationController? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_SyncedSpinnerInherited>()
        ?.controller;
  }

  @override
  bool updateShouldNotify(_SyncedSpinnerInherited oldWidget) =>
      controller != oldWidget.controller;
}

class SyncedSpinner extends StatelessWidget {
  const SyncedSpinner({
    super.key,
    required this.color,
    this.size = 18,
    this.strokeWidth = 2.0,
  });

  final Color color;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final controller = _SyncedSpinnerInherited.of(context);

    // Fallback: if no scope is present use a normal indicator
    if (controller == null) {
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: strokeWidth,
          color: color,
        ),
      );
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _SpinnerPainter(
              progress: controller.value,
              color: color,
              strokeWidth: strokeWidth,
            ),
          ),
        );
      },
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  _SpinnerPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;

    // Track (faint)
    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Arc
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const sweepAngle = 1.2; // ~70° arc
    final startAngle = progress * 2 * 3.14159265;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle - 1.5708, // offset by -90° so it starts at top
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_SpinnerPainter oldDelegate) =>
      progress != oldDelegate.progress || color != oldDelegate.color;
}
