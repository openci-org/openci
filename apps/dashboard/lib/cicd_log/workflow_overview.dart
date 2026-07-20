import 'package:dashboard/build_logs/chips/job_chip.dart';
import 'package:dashboard/cicd_log/cicd_mock_data.dart';
import 'package:flutter/material.dart';

class WorkflowOverview extends StatelessWidget {
  final MockWorkflowData workflow;

  const WorkflowOverview({super.key, required this.workflow});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (statusColor, statusIcon) = switch (workflow.status) {
      MockStatus.success => (Colors.green, Icons.check_rounded),
      MockStatus.failure => (Colors.red, Icons.close_rounded),
      MockStatus.inProgress => (
        Colors.blue,
        Icons.hourglass_empty_rounded,
      ),
    };

    // 1. 前段ステージのジョブチップ (フラットに並べるだけ)
    final dependencyWidgets = <Widget>[];
    for (final dep in workflow.dependencies) {
      dependencyWidgets.add(
        JobChip(
          label: dep.label,
          status: toChipStatus(dep.status),
        ),
      );
    }

    // 2. 後段ステージのジョブチップ (フラットに並べるだけ)
    final leafWidgets = <Widget>[];
    for (final leaf in workflow.leafJobs) {
      leafWidgets.add(
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('ジョブ "${leaf.label}" の詳細ログへ遷移します'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          child: JobChip(
            label: leaf.label,
            status: toChipStatus(leaf.status),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 18),
              const SizedBox(width: 8),
              Text(
                workflow.fileName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                workflow.duration,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ステージ列レイアウト (前段 ➔ 後段)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 前段ステージ
                if (dependencyWidgets.isNotEmpty) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < dependencyWidgets.length; i++) ...[
                        if (i > 0) const SizedBox(height: 6),
                        dependencyWidgets[i],
                      ],
                    ],
                  ),
                  // ステージ間の右矢印アイコン
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: Color(0xFFB8C0CC),
                    ),
                  ),
                ],
                // 後段ステージ
                if (leafWidgets.isNotEmpty) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < leafWidgets.length; i++) ...[
                        if (i > 0) const SizedBox(height: 6),
                        leafWidgets[i],
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
