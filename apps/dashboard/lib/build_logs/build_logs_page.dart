import 'package:dashboard/build_logs/build_jobs_provider.dart';
import 'package:dashboard/build_logs/build_logs_detail_page.dart';
import 'package:dashboard/extensions/date_time_extensions.dart';
import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LogsPage extends HookConsumerWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(buildJobsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.buildLogs.title(date: DateTime.now().toFormattedDate()),
        ),
      ),
      body: state.when(
        data: (buildJobs) {
          if (buildJobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    t.buildLogs.noJobs,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Scrollbar(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  itemCount: buildJobs.length,
                  itemBuilder: (_, index) {
                    final job = buildJobs[index];
                    return BuildJobCard(buildJob: job);
                  },
                ),
              ),
            ),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: asyncErrorWidget,
      ),
    );
  }
}

class BuildJobCard extends ConsumerWidget {
  const BuildJobCard({super.key, required this.buildJob});
  final BuildJob buildJob;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workflowNameAsync = ref.watch(
      workflowNameProvider(buildJob.workflowId),
    );

    final statusColor = switch (buildJob.status) {
      'success' => Colors.green,
      'failure' => Colors.red,
      'in_progress' => Theme.of(context).colorScheme.primary,
      'queued' => Colors.blue,
      'cancelled' => Colors.orange,
      _ => Colors.grey,
    };

    final statusIcon = switch (buildJob.status) {
      'success' => Icons.check_circle,
      'failure' => Icons.cancel,
      'queued' => Icons.schedule,
      'cancelled' => Icons.block,
      _ => Icons.help_outline,
    };

    final statusLabel = switch (buildJob.status) {
      'success' => t.buildLogs.status.success,
      'failure' => t.buildLogs.status.failed,
      'in_progress' => t.buildLogs.status.inProgress,
      'queued' => t.buildLogs.status.queued,
      'cancelled' => t.buildLogs.status.cancelled,
      _ => buildJob.status,
    };

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BuildLogsDetailPage(buildJob: buildJob),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: workflowNameAsync.when(
                            data: (name) => Text(
                              name ?? '${buildJob.owner}/${buildJob.repo}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            loading: () => const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator.adaptive(
                                strokeWidth: 2,
                              ),
                            ),
                            error: asyncErrorWidget,
                          ),
                        ),
                        Text(
                          buildJob.createdAt.toTimeAgoEn(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (buildJob.status == 'in_progress')
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: statusColor,
                                  ),
                                )
                              else
                                Icon(statusIcon, color: statusColor, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                statusLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (buildJob.branch != null)
                          _GitChip(
                            icon: FontAwesomeIcons.codeBranch,
                            label: buildJob.branch!,
                            color: Colors.purple,
                          ),
                        if (buildJob.pullRequestNumber != null)
                          _GitChip(
                            icon: FontAwesomeIcons.codePullRequest,
                            label: '#${buildJob.pullRequestNumber}',
                            color: Colors.green,
                          ),
                        if (buildJob.tagName != null)
                          _GitChip(
                            icon: FontAwesomeIcons.tag,
                            label: buildJob.tagName!,
                            color: Colors.amber,
                          ),
                        if (buildJob.commitSha != null)
                          _GitChip(
                            icon: FontAwesomeIcons.codeCommit,
                            label: buildJob.commitSha!.substring(0, 7),
                            color: Colors.blueGrey,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GitChip extends StatelessWidget {
  const _GitChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            icon,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
