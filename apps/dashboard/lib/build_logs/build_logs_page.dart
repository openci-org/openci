import 'package:dashboard/build_logs/build_jobs_provider.dart';
import 'package:dashboard/extensions/date_time_extensions.dart';
import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

class LogsBody extends HookConsumerWidget {
  const LogsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(buildJobsProvider);
    return state.when(
      data: (buildJobs) {
        if (buildJobs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  t.buildLogs.noJobs,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final groups = <String, List<BuildJob>>{};
        final orderedDisplayList = <List<BuildJob>>[];

        for (final job in buildJobs) {
          if (job.workflowRunId != null) {
            if (!groups.containsKey(job.workflowRunId!)) {
              final list = <BuildJob>[];
              groups[job.workflowRunId!] = list;
              orderedDisplayList.add(list);
            }
            groups[job.workflowRunId!]!.add(job);
          } else {
            orderedDisplayList.add([job]);
          }
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              itemCount: orderedDisplayList.length,
              itemBuilder: (_, index) {
                final jobs = orderedDisplayList[index];
                if (jobs.length == 1) {
                  return BuildJobCard(buildJob: jobs.first);
                }
                return WorkflowRunCard(jobs: jobs);
              },
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: asyncErrorWidget,
    );
  }
}

class BuildJobCard extends HookConsumerWidget {
  const BuildJobCard({super.key, required this.buildJob});
  final BuildJob buildJob;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workflowNameAsync = ref.watch(
      workflowNameProvider(buildJob),
    );

    final statusColor = switch (buildJob.status) {
      'success' => Colors.green,
      'failure' => Colors.red,
      'in_progress' => Theme.of(context).colorScheme.primary,
      'queued' => Colors.blue,
      'cancelled' => Colors.orange,
      'waiting' => Colors.amber,
      'skipped' => Colors.grey,
      _ => Colors.grey,
    };

    final statusIcon = switch (buildJob.status) {
      'success' => Icons.check_circle,
      'failure' => Icons.cancel,
      'queued' => Icons.schedule,
      'cancelled' => Icons.block,
      'waiting' => Icons.hourglass_empty,
      'skipped' => Icons.skip_next,
      _ => Icons.help_outline,
    };

    final statusLabel = switch (buildJob.status) {
      'success' => t.buildLogs.status.success,
      'failure' => t.buildLogs.status.failed,
      'in_progress' => t.buildLogs.status.inProgress,
      'queued' => t.buildLogs.status.queued,
      'cancelled' => t.buildLogs.status.cancelled,
      'waiting' => 'Waiting',
      'skipped' => 'Skipped',
      _ => buildJob.status,
    };

    final isRunning =
        buildJob.status == 'in_progress' || buildJob.status == 'queued';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.push('/runs/${Uri.encodeComponent(buildJob.id)}');
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2, right: 12),
                          child: Tooltip(
                            message: statusLabel,
                            child: buildJob.status == 'in_progress'
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: statusColor,
                                    ),
                                  )
                                : Icon(
                                    statusIcon,
                                    color: statusColor,
                                    size: 18,
                                  ),
                          ),
                        ),
                        Expanded(
                          child: workflowNameAsync.when(
                            data: (name) {
                              final title =
                                  name ?? '${buildJob.owner}/${buildJob.repo}';
                              final displayTitle = buildJob.jobKey != null
                                  ? '$title (${buildJob.jobKey})'
                                  : title;
                              return Text(
                                displayTitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                            loading: () => Skeletonizer(
                              child: Text(
                                buildJob.jobKey != null
                                    ? '${buildJob.owner}/${buildJob.repo} (${buildJob.jobKey})'
                                    : '${buildJob.owner}/${buildJob.repo}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            error: asyncErrorWidget,
                          ),
                        ),
                        Text(
                          buildJob.createdAt.toTimeAgo(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _RunDurationBadge(buildJob: buildJob),
                        if (buildJob.needs != null &&
                            buildJob.needs!.isNotEmpty)
                          _NeedsBadge(needs: buildJob.needs!),
                        if (buildJob.pullRequestNumber != null)
                          _InfoBadge(
                            icon: FaIcon(
                              FontAwesomeIcons.codePullRequest,
                              size: 10,
                            ),
                            label: '#${buildJob.pullRequestNumber}',
                          ),
                        if (buildJob.tagName != null)
                          _InfoBadge(
                            icon: FaIcon(FontAwesomeIcons.tag, size: 10),
                            label: buildJob.tagName!,
                          ),
                        if (buildJob.commitSha != null)
                          _InfoBadge(
                            icon: FaIcon(
                              FontAwesomeIcons.codeCommit,
                              size: 10,
                            ),
                            label: buildJob.commitSha!.substring(0, 7),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onSelected: (value) async {
                  switch (value) {
                    case 'details':
                      await context.push(
                        '/runs/${Uri.encodeComponent(buildJob.id)}',
                      );
                    case 'retry':
                      try {
                        await ref
                            .read(buildJobsProvider.notifier)
                            .retryBuildJob(buildJob.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(t.buildLogs.detail.retrySuccess),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                t.buildLogs.detail.failedToRetry(
                                  error: e.toString(),
                                ),
                              ),
                            ),
                          );
                        }
                      }
                    case 'cancel':
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(t.buildLogs.detail.cancelBuild),
                          content: Text(t.buildLogs.detail.cancelConfirm),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(t.buildLogs.detail.cancelNo),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: Text(t.buildLogs.detail.cancelBuild),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                      try {
                        await ref
                            .read(buildJobsProvider.notifier)
                            .cancelBuildJob(buildJob.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(t.buildLogs.detail.buildCancelled),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                t.buildLogs.detail.failedToCancel(
                                  error: e.toString(),
                                ),
                              ),
                            ),
                          );
                        }
                      }
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'details',
                    child: ListTile(
                      leading: const Icon(Icons.info_outline, size: 20),
                      title: Text(t.buildLogs.detail.viewDetails),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'retry',
                    child: ListTile(
                      leading: const Icon(Icons.replay, size: 20),
                      title: Text(t.buildLogs.detail.retry),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  if (isRunning)
                    PopupMenuItem(
                      value: 'cancel',
                      child: ListTile(
                        leading: Icon(
                          Icons.cancel_outlined,
                          size: 20,
                          color: Colors.red,
                        ),
                        title: Text(
                          t.common.cancel,
                          style: const TextStyle(color: Colors.red),
                        ),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WorkflowRunCard extends HookConsumerWidget {
  const WorkflowRunCard({super.key, required this.jobs});
  final List<BuildJob> jobs;

  List<BuildJob> get _sortedJobs {
    final sorted = <BuildJob>[];
    final visited = <String>{};
    final itemsByKey = {for (final job in jobs) job.jobKey: job};

    void visit(BuildJob job) {
      if (job.jobKey != null && visited.contains(job.jobKey!)) return;

      if (job.needs != null) {
        for (final req in job.needs!) {
          final reqJob = itemsByKey[req];
          if (reqJob != null) {
            visit(reqJob);
          }
        }
      }

      if (job.jobKey != null) {
        visited.add(job.jobKey!);
      }
      if (!sorted.contains(job)) {
        sorted.add(job);
      }
    }

    // Process from the items that are mostly roots first (those without needs)
    final rootJobs = jobs
        .where((j) => j.needs == null || j.needs!.isEmpty)
        .toList();
    final dependentJobs = jobs
        .where((j) => j.needs != null && j.needs!.isNotEmpty)
        .toList();

    for (final job in [...rootJobs, ...dependentJobs]) {
      if (!sorted.contains(job)) {
        visit(job);
      }
    }

    return sorted;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (jobs.isEmpty) return const SizedBox.shrink();

    // Use the first job for general repository/workflow info
    final mainJob = jobs.first;
    final workflowNameAsync = ref.watch(workflowNameProvider(mainJob));

    String overallStatus = 'unknown';
    if (jobs.any((j) => j.status == 'in_progress')) {
      overallStatus = 'in_progress';
    } else if (jobs.any((j) => j.status == 'queued')) {
      overallStatus = 'queued';
    } else if (jobs.any((j) => j.status == 'waiting')) {
      overallStatus = 'waiting';
    } else if (jobs.any((j) => j.status == 'failure')) {
      overallStatus = 'failure';
    } else if (jobs.any((j) => j.status == 'cancelled')) {
      overallStatus = 'cancelled';
    } else if (jobs.every((j) => j.status == 'skipped')) {
      overallStatus = 'skipped';
    } else if (jobs.every(
      (j) => j.status == 'success' || j.status == 'skipped',
    )) {
      overallStatus = 'success';
    }

    final statusColor = switch (overallStatus) {
      'success' => Colors.green,
      'failure' => Colors.red,
      'in_progress' => Theme.of(context).colorScheme.primary,
      'queued' => Colors.blue,
      'cancelled' => Colors.orange,
      'waiting' => Colors.amber,
      'skipped' => Colors.grey,
      _ => Colors.grey,
    };

    final statusIcon = switch (overallStatus) {
      'success' => Icons.check_circle,
      'failure' => Icons.cancel,
      'queued' => Icons.schedule,
      'cancelled' => Icons.block,
      'waiting' => Icons.hourglass_empty,
      'skipped' => Icons.skip_next,
      _ => Icons.help_outline,
    };

    final statusLabel = switch (overallStatus) {
      'success' => t.buildLogs.status.success,
      'failure' => t.buildLogs.status.failed,
      'in_progress' => t.buildLogs.status.inProgress,
      'queued' => t.buildLogs.status.queued,
      'cancelled' => t.buildLogs.status.cancelled,
      'waiting' => 'Waiting',
      'skipped' => 'Skipped',
      _ => overallStatus,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2, right: 12),
                      child: Tooltip(
                        message: statusLabel,
                        child: overallStatus == 'in_progress'
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: statusColor,
                                ),
                              )
                            : Icon(
                                statusIcon,
                                color: statusColor,
                                size: 18,
                              ),
                      ),
                    ),
                    Expanded(
                      child: workflowNameAsync.when(
                        data: (name) => Text(
                          name ?? '${mainJob.owner}/${mainJob.repo}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        loading: () => Skeletonizer(
                          child: Text(
                            '${mainJob.owner}/${mainJob.repo}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        error: asyncErrorWidget,
                      ),
                    ),
                    Text(
                      mainJob.createdAt.toTimeAgo(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      padding: EdgeInsets.zero,
                      onSelected: (value) async {
                        if (value == 'retry_all') {
                          try {
                            await ref
                                .read(buildJobsProvider.notifier)
                                .retryWorkflowRun(
                                  mainJob.workflowRunId!,
                                );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    t.buildLogs.detail.retrySuccess,
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    t.buildLogs.detail.failedToRetry(
                                      error: e.toString(),
                                    ),
                                  ),
                                ),
                              );
                            }
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'retry_all',
                          child: ListTile(
                            leading: const Icon(
                              Icons.replay,
                              size: 20,
                            ),
                            title: Text(t.buildLogs.detail.retry),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (mainJob.pullRequestNumber != null)
                      _InfoBadge(
                        icon: const FaIcon(
                          FontAwesomeIcons.codePullRequest,
                          size: 10,
                        ),
                        label: '#${mainJob.pullRequestNumber}',
                      ),
                    if (mainJob.tagName != null)
                      _InfoBadge(
                        icon: const FaIcon(FontAwesomeIcons.tag, size: 10),
                        label: mainJob.tagName!,
                      ),
                    if (mainJob.commitSha != null)
                      _InfoBadge(
                        icon: const FaIcon(
                          FontAwesomeIcons.codeCommit,
                          size: 10,
                        ),
                        label: mainJob.commitSha!.substring(0, 7),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Jobs list wrapped in an inner container for visual nesting
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                children: _sortedJobs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final job = entry.value;
                  final isLast = index == _sortedJobs.length - 1;

                  final isRunning =
                      job.status == 'in_progress' || job.status == 'queued';

                  final statusColor = switch (job.status) {
                    'success' => Colors.green,
                    'failure' => Colors.red,
                    'in_progress' => Theme.of(context).colorScheme.primary,
                    'queued' => Colors.blue,
                    'cancelled' => Colors.orange,
                    'waiting' => Colors.amber,
                    'skipped' => Colors.grey,
                    _ => Colors.grey,
                  };

                  final statusIcon = switch (job.status) {
                    'success' => Icons.check_circle,
                    'failure' => Icons.cancel,
                    'queued' => Icons.schedule,
                    'cancelled' => Icons.block,
                    'waiting' => Icons.hourglass_empty,
                    'skipped' => Icons.skip_next,
                    _ => Icons.help_outline,
                  };

                  final statusLabel = switch (job.status) {
                    'success' => t.buildLogs.status.success,
                    'failure' => t.buildLogs.status.failed,
                    'in_progress' => t.buildLogs.status.inProgress,
                    'queued' => t.buildLogs.status.queued,
                    'cancelled' => t.buildLogs.status.cancelled,
                    'waiting' => 'Waiting',
                    'skipped' => 'Skipped',
                    _ => job.status,
                  };

                  return Column(
                    children: [
                      InkWell(
                        borderRadius: index == 0
                            ? const BorderRadius.vertical(
                                top: Radius.circular(12),
                              )
                            : (isLast
                                  ? const BorderRadius.vertical(
                                      bottom: Radius.circular(12),
                                    )
                                  : BorderRadius.zero),
                        onTap: () {
                          context.push('/runs/${Uri.encodeComponent(job.id)}');
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Tooltip(
                                message: statusLabel,
                                child: job.status == 'in_progress'
                                    ? SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: statusColor,
                                        ),
                                      )
                                    : Icon(
                                        statusIcon,
                                        color: statusColor,
                                        size: 16,
                                      ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      job.jobKey ?? 'Unnamed Job',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        _RunDurationBadge(buildJob: job),
                                        if (job.needs != null &&
                                            job.needs!.isNotEmpty)
                                          _NeedsBadge(needs: job.needs!),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 20),
                                padding: EdgeInsets.zero,
                                onSelected: (value) async {
                                  if (value == 'retry') {
                                    await ref
                                        .read(buildJobsProvider.notifier)
                                        .retryBuildJob(job.id);
                                  } else if (value == 'cancel') {
                                    await ref
                                        .read(buildJobsProvider.notifier)
                                        .cancelBuildJob(job.id);
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'retry',
                                    child: ListTile(
                                      leading: const Icon(
                                        Icons.replay,
                                        size: 20,
                                      ),
                                      title: Text(t.buildLogs.detail.retry),
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  if (isRunning)
                                    PopupMenuItem(
                                      value: 'cancel',
                                      child: ListTile(
                                        leading: const Icon(
                                          Icons.cancel_outlined,
                                          size: 20,
                                          color: Colors.red,
                                        ),
                                        title: Text(
                                          t.common.cancel,
                                          style: const TextStyle(
                                            color: Colors.red,
                                          ),
                                        ),
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          indent: 48,
                          color: Theme.of(
                            context,
                          ).colorScheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final durationT = t.buildLogs.duration;
  final totalMinutes = duration.inMinutes;
  if (totalMinutes < 1) return durationT.lessThanMinute;
  if (totalMinutes < 60) {
    return durationT.minutes(count: totalMinutes.toString());
  }
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  return minutes > 0
      ? durationT.hoursAndMinutes(
          hours: hours.toString(),
          minutes: minutes.toString(),
        )
      : durationT.hours(count: hours.toString());
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.icon,
    required this.label,
  });

  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final textColor = theme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: theme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon is! SizedBox) ...[
            icon,
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _NeedsBadge extends StatelessWidget {
  const _NeedsBadge({required this.needs});

  final List<String> needs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    final children = <Widget>[
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.segment, size: 14, color: theme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            'Needs',
            style: TextStyle(
              fontSize: 11,
              color: theme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ];

    for (final n in needs) {
      children.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: theme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: theme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Text(
            n,
            style: TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              color: theme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}

class _RunDurationBadge extends ConsumerWidget {
  const _RunDurationBadge({required this.buildJob});
  final BuildJob buildJob;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final durationAsync = ref.watch(runDurationProvider(buildJob));
    return durationAsync.when(
      data: (duration) {
        if (duration == null) return const SizedBox.shrink();
        return _InfoBadge(
          icon: const Icon(Icons.timer_outlined, size: 10),
          label: _formatDuration(duration),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) {
        debugPrint('error: $e');
        debugPrint('stackTrace: $s');
        throw Exception('Failed to load run duration: $e');
      },
    );
  }
}
