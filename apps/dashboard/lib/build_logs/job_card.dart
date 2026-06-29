import 'package:flutter/material.dart';
import 'package:openci_shared/openci_shared.dart' show BuildJobStatus;

class JobCard extends StatefulWidget {
  const JobCard({
    super.key,
    required this.child,
    this.onTap,
    this.status = BuildJobStatus.SUCCESS,
  });

  final Widget child;
  final VoidCallback? onTap;
  final BuildJobStatus status;

  @override
  State<JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> {
  bool _isHovered = false;

  bool get _isError =>
      widget.status == BuildJobStatus.FAILURE ||
      widget.status == BuildJobStatus.TIMED_OUT;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor;
    final Color borderColor;
    final Color shadowColor;
    final Color hoverShadowColor;
    final Color splashColor;

    if (_isError) {
      backgroundColor = _isHovered
          ? const Color(0xFFFFF0F0)
          : const Color(0xFFFFF8F8);
      borderColor = _isHovered
          ? const Color(0xFFEF4444)
          : const Color(0xFFFCA5A5);
      shadowColor = const Color(0x1FDC2626);
      hoverShadowColor = const Color(0x28DC2626);
      splashColor = const Color(0xFFEF4444).withValues(alpha: 0.04);
    } else {
      backgroundColor = _isHovered ? const Color(0xFFFAFBFC) : Colors.white;
      borderColor = _isHovered
          ? const Color(0xFF5856D6).withValues(alpha: 0.25)
          : const Color(0xFFE5E7EB);
      shadowColor = const Color(0x0F101828);
      hoverShadowColor = const Color(0x14101828);
      splashColor = const Color(0xFF5856D6).withValues(alpha: 0.04);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: _isHovered ? hoverShadowColor : shadowColor,
            blurRadius: _isHovered ? 20 : 16,
            offset: Offset(0, _isHovered ? 10 : 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: widget.onTap,
          mouseCursor: widget.onTap != null
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onHover: (hovered) {
            if (widget.onTap != null) {
              setState(() => _isHovered = hovered);
            }
          },
          hoverColor: Colors.transparent,
          splashColor: splashColor,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
