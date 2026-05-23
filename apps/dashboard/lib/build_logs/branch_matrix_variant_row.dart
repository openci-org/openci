import 'package:dashboard/build_logs/chips/job_status.dart';
import 'package:dashboard/build_logs/chips/matrix_job_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class BranchMatrixVariantRow extends StatelessWidget {
  const BranchMatrixVariantRow({
    super.key,
    required this.variantLabel,
    required this.status,
    required this.parentIndex,
    required this.parentTotal,
    required this.variantIndex,
    required this.variantTotal,
    this.showConnection = true,
  });

  final String variantLabel;
  final ChipStatus status;
  final int parentIndex;
  final int parentTotal;
  final int variantIndex;
  final int variantTotal;
  final bool showConnection;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        MatrixVariantBranchLine(
          parentIndex: parentIndex,
          parentTotal: parentTotal,
          index: variantIndex,
          total: variantTotal,
          showConnection: showConnection,
        ),
        const SizedBox(width: 11),
        VariantChip(label: variantLabel, status: status),
      ],
    );
  }
}

class MatrixVariantBranchLine extends StatelessWidget {
  const MatrixVariantBranchLine({
    super.key,
    required this.parentIndex,
    required this.parentTotal,
    required this.index,
    required this.total,
    this.showConnection = true,
  });

  final int parentIndex;
  final int parentTotal;
  final int index;
  final int total;
  final bool showConnection;

  @override
  Widget build(BuildContext context) {
    final isParentSingle = parentTotal <= 1;
    final baseWidth = isParentSingle ? 52.0 : 59.0;
    final width = showConnection ? baseWidth : baseWidth - 28.0;
    return SizedBox(
      width: width,
      height: 32,
      child: CustomPaint(
        painter: MatrixVariantBranchLinePainter(
          parentIndex: parentIndex,
          parentTotal: parentTotal,
          index: index,
          total: total,
          showConnection: showConnection,
        ),
      ),
    );
  }
}

class MatrixVariantBranchLinePainter extends CustomPainter {
  MatrixVariantBranchLinePainter({
    required this.parentIndex,
    required this.parentTotal,
    required this.index,
    required this.total,
    required this.showConnection,
  });

  final int parentIndex;
  final int parentTotal;
  final int index;
  final int total;
  final bool showConnection;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB8C0CC).withValues(alpha: 0.6)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final halfHeight = size.height / 2;

    final double shift = showConnection ? 0.0 : 28.0;

    // 1. Parent level vertical line (Column 1, center is at x = 12)
    if (parentIndex < parentTotal - 1) {
      final double parentX = 12.0 - shift;
      if (parentX >= 0) {
        path.moveTo(parentX, 0);
        path.lineTo(parentX, size.height);
      }
    }

    // 2. Nested branch line (Column 2, center is at x = 38 or 45 depending on parentTotal)
    final double baseBranchX = parentTotal <= 1 ? 38.0 : 45.0;
    final double branchX = baseBranchX - shift;

    if (index == 0) {
      path.moveTo(branchX, 6);
    } else {
      path.moveTo(branchX, 0);
    }

    // Vertical line to center of variant row
    path.lineTo(branchX, halfHeight);

    // Horizontal line to the variant chip
    path.lineTo(size.width, halfHeight);

    // If not the last variant, continue vertical line down to the next row
    if (index < total - 1) {
      path.moveTo(branchX, halfHeight);
      path.lineTo(branchX, size.height);
    }

    // Draw an arrowhead at the right end of the horizontal line
    const double arrowSize = 3.0;
    path.moveTo(size.width - arrowSize, halfHeight - arrowSize);
    path.lineTo(size.width, halfHeight);
    path.lineTo(size.width - arrowSize, halfHeight + arrowSize);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant MatrixVariantBranchLinePainter oldDelegate) =>
      oldDelegate.parentIndex != parentIndex ||
      oldDelegate.parentTotal != parentTotal ||
      oldDelegate.index != index ||
      oldDelegate.total != total ||
      oldDelegate.showConnection != showConnection;
}
