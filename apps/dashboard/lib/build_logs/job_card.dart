import 'package:flutter/material.dart';

class JobCard extends StatefulWidget {
  const JobCard({
    super.key,
    required this.child,
    this.onTap,
  });

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: _isHovered ? const Color(0xFFFAFBFC) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isHovered
              ? const Color(0xFF5856D6).withValues(alpha: 0.25)
              : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: _isHovered
                ? const Color(0x14101828)
                : const Color(0x0F101828),
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
          splashColor: const Color(0xFF5856D6).withValues(alpha: 0.04),
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
