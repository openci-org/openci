import 'package:dashboard/build_logs/chips/base_chip.dart';
import 'package:dashboard/build_logs/chips/job_status.dart';
import 'package:flutter/material.dart';

class JobChip extends StatelessWidget {
  const JobChip({
    super.key,
    required this.label,
    required this.status,
    this.durationWidget,
  });

  final String label;
  final ChipStatus status;
  final Widget? durationWidget;

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
          if (durationWidget != null) ...[
            const SizedBox(width: 5),
            const Text('·', style: TextStyle(fontWeight: FontWeight.w300)),
            const SizedBox(width: 5),
            durationWidget!,
          ],
        ],
      ),
    );
  }
}
