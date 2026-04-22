import 'dart:math' as math;


import 'package:flutter/material.dart';


/// A premium status indicator dot.
///
/// When [active] is `true`, the dot renders with a breathing core, concentric
/// soft-filled pulse rings, and an ambient glow — conveying an "operational / live"
/// status with high-end aesthetic.
///
/// When `false`, the dot shows an "off" LED state with subtle depth.
class StatusDot extends StatefulWidget {
  const StatusDot({
    super.key,
    required this.active,
    this.size = 8,
  });

  final bool active;
  final double size;

  @override
  State<StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<StatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Premium Neo-morphic / Glassy Emerald palette
  static const _coreColor = Colors.green;
  static const _glowColor = Colors.greenAccent;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(StatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) {
      if (widget.active) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 3.5, // Generous hit area / animation bounds
      height: widget.size * 3.5,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _StatusDotPainter(
              active: widget.active,
              progress: _controller.value,
              dotSize: widget.size,
              coreColor: _coreColor,
              glowColor: _glowColor,
              inactiveColor: Theme.of(context).colorScheme.outlineVariant,
            ),
            size: Size(widget.size * 3.5, widget.size * 3.5),
          );
        },
      ),
    );
  }
}

class _StatusDotPainter extends CustomPainter {
  _StatusDotPainter({
    required this.active,
    required this.progress,
    required this.dotSize,
    required this.coreColor,
    required this.glowColor,
    required this.inactiveColor,
  });

  final bool active;
  final double progress;
  final double dotSize;
  final Color coreColor;
  final Color glowColor;
  final Color inactiveColor;

  static const _ringCount = 2; // Two continuous soft pulses

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final coreRadius = dotSize / 2;

    if (!active) {
      // ── "Off" LED State ──
      // Recessed look with inner shadow effect
      final offPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            inactiveColor.withValues(alpha: 0.2), // Bright center
            inactiveColor.withValues(alpha: 0.6), // Darker edge simulates depth
          ],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: coreRadius));
      canvas.drawCircle(center, coreRadius, offPaint);

      // Outer rim for the recessed hole
      final rimPaint = Paint()
        ..color = inactiveColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(center, coreRadius, rimPaint);
      return;
    }

    final maxRippleRadius = size.width / 2;

    // ── 1. Draw soft filled ripples ──
    for (int i = 0; i < _ringCount; i++) {
      final stagger = i / _ringCount;
      final rippleProgress = (progress + stagger) % 1.0;

      // Soft easing expands quickly then slows down (Circ Out)
      final eased = Curves.easeOutCirc.transform(rippleProgress);
      final rippleRadius = coreRadius + (maxRippleRadius - coreRadius) * eased;

      // Opacity decays non-linearly to favor a soft long fade
      final fadeOut = math.pow(1.0 - eased, 2.5).toDouble();
      // Swift fade-in to prevent harsh popping
      final fadeIn = (rippleProgress * 15.0).clamp(0.0, 1.0);

      final opacity = (0.45 * fadeIn * fadeOut).clamp(0.0, 1.0);

      if (opacity > 0.01) {
        final ripplePaint = Paint()
          ..color = glowColor.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, rippleRadius, ripplePaint);
      }
    }

    // ── 2. Ambient base glow ──
    // Constant blurry glow behind the core, breathing slightly
    final breathPhase = math.sin(progress * 2 * math.pi);
    final ambientRadius = coreRadius * 2.5;
    final ambientOpacity = 0.25 + 0.1 * breathPhase;

    final ambientPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          glowColor.withValues(alpha: ambientOpacity),
          glowColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: ambientRadius));
    canvas.drawCircle(center, ambientRadius, ambientPaint);

    // ── 3. Glossy Core Dot ──
    // The core dot itself is styled like a glassy gemstone
    final coreScale = 1.0 + 0.05 * breathPhase;
    final animatedCoreRadius = coreRadius * coreScale;

    final corePaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.white, // Specular highlight
              coreColor, // Base emerald
              coreColor.withValues(alpha: 0.7), // Shadowed edge
            ],
            stops: const [0.0, 0.45, 1.0],
            focal: const Alignment(-0.3, -0.3),
            focalRadius: animatedCoreRadius * 0.15,
          ).createShader(
            Rect.fromCircle(center: center, radius: animatedCoreRadius),
          );

    // Add a tiny ambient drop shadow just under the core
    canvas.drawShadow(
      Path()
        ..addOval(Rect.fromCircle(center: center, radius: animatedCoreRadius)),
      coreColor.withValues(alpha: 0.5),
      3.0,
      false,
    );

    canvas.drawCircle(center, animatedCoreRadius, corePaint);
  }

  @override
  bool shouldRepaint(_StatusDotPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.active != active;
}
