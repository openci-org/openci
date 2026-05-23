import 'package:dashboard/build_logs/chips/job_chip.dart';
import 'package:dashboard/build_logs/chips/job_status.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ArrowRightIcon extends StatelessWidget {
  const ArrowRightIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 24,
      child: Icon(
        CupertinoIcons.arrow_right,
        size: 10,
        color: Color(0xFFB8C0CC),
      ),
    );
  }
}

class BranchLine extends StatelessWidget {
  const BranchLine({super.key, required this.index, required this.total});
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 32,
      child: CustomPaint(
        painter: BranchLinePainter(index: index, total: total),
      ),
    );
  }
}

class BranchLinePainter extends CustomPainter {
  BranchLinePainter({required this.index, required this.total});
  final int index;
  final int total;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB8C0CC).withValues(alpha: 0.6)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final halfWidth = size.width / 2;
    final halfHeight = size.height / 2;

    if (total <= 1) {
      // 単一ジョブの場合は単なる水平接続線
      path.moveTo(0, halfHeight);
      path.lineTo(size.width, halfHeight);
    } else if (index == 0) {
      // 最初のジョブ: 直進 ＋ 中央から下へ分岐
      path.moveTo(0, halfHeight);
      path.lineTo(size.width, halfHeight);

      path.moveTo(halfWidth, halfHeight);
      path.lineTo(halfWidth, size.height);
    } else if (index == total - 1) {
      // 最後のジョブ: 上から中央、そして右へ曲がる
      path.moveTo(halfWidth, 0);
      path.lineTo(halfWidth, halfHeight);
      path.lineTo(size.width, halfHeight);
    } else {
      // 中間のジョブ: 縦に貫通 ＋ 中央から右へ分岐
      path.moveTo(halfWidth, 0);
      path.lineTo(halfWidth, size.height);

      path.moveTo(halfWidth, halfHeight);
      path.lineTo(size.width, halfHeight);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant BranchLinePainter oldDelegate) =>
      oldDelegate.index != index || oldDelegate.total != total;
}

class BranchJobRow extends StatelessWidget {
  const BranchJobRow({
    super.key,
    required this.label,
    required this.status,
    required this.index,
    required this.total,
    this.onTap,
  });

  final String label;
  final ChipStatus status;
  final int index;
  final int total;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        BranchLine(index: index, total: total),
        const SizedBox(width: 4),
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: JobChip(label: label, status: status),
        ),
      ],
    );
  }
}
