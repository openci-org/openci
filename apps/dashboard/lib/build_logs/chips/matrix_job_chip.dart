import 'package:dashboard/build_logs/chips/base_chip.dart';
import 'package:dashboard/build_logs/chips/job_status.dart';
import 'package:flutter/cupertino.dart';

class MatrixJobChip extends StatelessWidget {
  const MatrixJobChip({
    super.key,
    required this.label,
    required this.count,
    required this.status,
    required this.isExpanded,
    required this.onTap,
  });

  final String label;
  final int count;
  final ChipStatus status;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BaseChip(
      backgroundColor: status.backgroundColor,
      borderColor: status.borderColor,
      foregroundColor: status.foregroundColor,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusIcon(status: status),
          const SizedBox(width: 5),
          const Icon(CupertinoIcons.square_grid_2x2, size: 10),
          const SizedBox(width: 5),
          Text('$label · $count'),
          const SizedBox(width: 5),
          Icon(
            isExpanded
                ? CupertinoIcons.chevron_up
                : CupertinoIcons.chevron_down,
            size: 9,
          ),
        ],
      ),
    );
  }
}

class VariantChips extends StatelessWidget {
  const VariantChips({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(10),
      child: const Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          VariantChip(label: 'ios / debug', status: ChipStatus.success),
          VariantChip(label: 'ios / release', status: ChipStatus.inProgress),
          VariantChip(label: 'macos / debug', status: ChipStatus.cancelled),
          VariantChip(label: 'macos / release', status: ChipStatus.fail),
          VariantChip(label: 'ios / queued', status: ChipStatus.queued),
          VariantChip(label: 'ios / nightly', status: ChipStatus.skipped),
        ],
      ),
    );
  }
}

class VariantChip extends StatelessWidget {
  const VariantChip({super.key, required this.label, required this.status});

  final String label;
  final ChipStatus status;

  @override
  Widget build(BuildContext context) {
    return BaseChip(
      backgroundColor: status.backgroundColor,
      borderColor: status.borderColor,
      foregroundColor: status.foregroundColor,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusIcon(status: status),
          const SizedBox(width: 5),
          Text(label),
        ],
      ),
    );
  }
}
