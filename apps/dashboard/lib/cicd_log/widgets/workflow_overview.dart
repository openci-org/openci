import 'package:dashboard/build_logs/chips/job_chip.dart';
import 'package:dashboard/cicd_log/widgets/build_job_status_to_chip_status.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openci_shared/openci_shared.dart';

class WorkflowOverview extends StatelessWidget {
  final CicdWorkflowGroup workflow;

  const WorkflowOverview({super.key, required this.workflow});

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    if (minutes > 0) {
      return '$minutes分$seconds秒';
    }
    return '$seconds秒';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (statusColor, statusIcon) = switch (workflow.status) {
      BuildJobStatus.SUCCESS => (Colors.green, Icons.check_rounded),
      BuildJobStatus.FAILURE ||
      BuildJobStatus.CANCELLED ||
      BuildJobStatus.TIMED_OUT => (Colors.red, Icons.close_rounded),
      _ => (
        Colors.blue,
        Icons.hourglass_empty_rounded,
      ),
    };

    final List<Widget> stageWidgets = [];
    for (var i = 0; i < workflow.stages.length; i++) {
      if (i > 0) {
        stageWidgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.0),
            child: Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Color(0xFFB8C0CC),
            ),
          ),
        );
      }

      final stageJobs = workflow.stages[i];
      stageWidgets.add(
        _Jobs(
          jobs: stageJobs,
          onJobTap: (jobId) {
            context.push('/runs/$jobId');
          },
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
                _formatDuration(workflow.duration),
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: stageWidgets,
            ),
          ),
        ],
      ),
    );
  }
}

class _Jobs extends StatelessWidget {
  const _Jobs({
    required this.jobs,
    required this.onJobTap,
  });

  final List<CicdJobGroup> jobs;
  final ValueChanged<String> onJobTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < jobs.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => onJobTap(jobs[i].id),
            child: JobChip(
              label: jobs[i].label,
              status: toChipStatus(jobs[i].status),
            ),
          ),
        ],
      ],
    );
  }
}
