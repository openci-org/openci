import 'package:dashboard/build_logs/chips/base_chip.dart';
import 'package:dashboard/build_logs/chips/job_status.dart';
import 'package:flutter/material.dart';

class JobChip extends StatelessWidget {
  const JobChip({super.key, required this.label, required this.status});

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
