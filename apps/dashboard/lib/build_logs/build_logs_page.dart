import 'package:dashboard/build_logs/build_jobs_provider.dart';
import 'package:dashboard/build_logs/synced_spinner.dart';
import 'package:dashboard/extensions/date_time_extensions.dart';
import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

// ── Curated status palette ──────────────────────────────────────────────────

Color _statusColor(String status, ColorScheme scheme) => switch (status) {
  'success' => const Color(0xFF2DA44E),
  'failure' => const Color(0xFFCF222E),
  'in_progress' => const Color(0xFF1F6FEB),
  'queued' => const Color(0xFF6E40C9),
  'cancelled' => const Color(0xFFBF8700),
  'waiting' => const Color(0xFFBF8700),
  'skipped' => scheme.onSurfaceVariant.withValues(alpha: 0.6),
  _ => scheme.onSurfaceVariant.withValues(alpha: 0.6),
};

IconData _statusIcon(String status) => switch (status) {
  'success' => Icons.check_circle_rounded,
  'failure' => Icons.cancel_rounded,
  'queued' => Icons.schedule_rounded,
  'cancelled' => Icons.block_rounded,
  'waiting' => Icons.adjust_rounded,
  'skipped' => Icons.skip_next_rounded,
  _ => Icons.help_outline_rounded,
};

String _statusLabel(String status) => switch (status) {
  'success' => t.buildLogs.status.success,
  'failure' => t.buildLogs.status.failed,
  'in_progress' => t.buildLogs.status.inProgress,
  'queued' => t.buildLogs.status.queued,
  'cancelled' => t.buildLogs.status.cancelled,
  'waiting' => 'Waiting',
  'skipped' => 'Skipped',
  _ => status,
};

// ─────────────────────────────────────────────────────────────────────────────

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
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.inbox_rounded,
                    size: 40,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  t.buildLogs.noJobs,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
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

        return SyncedSpinnerScope(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
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
    final scheme = Theme.of(context).colorScheme;
    final workflowNameAsync = ref.watch(workflowNameProvider(buildJob));

    final color = _statusColor(buildJob.status, scheme);
    final statusLabel = _statusLabel(buildJob.status);
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
                          child: _StatusIndicator(
                            status: buildJob.status,
                            color: color,
                            tooltip: statusLabel,
                            size: 18,
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
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                            loading: () => Skeletonizer(
                              child: Text(
                                buildJob.jobKey != null
                                    ? '${buildJob.owner}/${buildJob.repo} (${buildJob.jobKey})'
                                    : '${buildJob.owner}/${buildJob.repo}',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            error: asyncErrorWidget,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          buildJob.createdAt.toTimeAgo(),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: scheme.onSurfaceVariant.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
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
                  color: scheme.onSurfaceVariant,
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

    final scheme = Theme.of(context).colorScheme;
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

    final color = _statusColor(overallStatus, scheme);
    final statusLabel = _statusLabel(overallStatus);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ───────────────────────────────────────────────────
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
                      child: _StatusIndicator(
                        status: overallStatus,
                        color: color,
                        tooltip: statusLabel,
                        size: 18,
                      ),
                    ),
                    Expanded(
                      child: workflowNameAsync.when(
                        data: (name) => Text(
                          name ?? '${mainJob.owner}/${mainJob.repo}',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        loading: () => Skeletonizer(
                          child: Text(
                            '${mainJob.owner}/${mainJob.repo}',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        error: asyncErrorWidget,
                      ),
                    ),
                    Text(
                      mainJob.createdAt.toTimeAgo(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
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
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
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
          // ── Jobs tree ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: _JobTree(jobs: _sortedJobs),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status indicator widget ─────────────────────────────────────────────────

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({
    required this.status,
    required this.color,
    required this.tooltip,
    this.size = 18,
  });

  final String status;
  final Color color;
  final String tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (status == 'in_progress') {
      return Tooltip(
        message: tooltip,
        child: SyncedSpinner(
          color: color,
          size: size - 4,
        ),
      );
    }

    return Tooltip(
      message: tooltip,
      child: Icon(
        _statusIcon(status),
        color: color,
        size: size,
      ),
    );
  }
}

// ── Shared utility widgets ──────────────────────────────────────────────────

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
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon is! SizedBox) ...[
            IconTheme(
              data: IconThemeData(
                size: 10,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              child: icon,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: scheme.onSurfaceVariant,
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
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_tree_outlined,
            size: 11,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
          for (int i = 0; i < needs.length; i++) ...[
            Text(
              needs[i],
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (i < needs.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Icon(
                  Icons.add,
                  size: 9,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// ジョブをneeds依存関係に基づいてツリー構造で表示するウィジェット
class _JobTree extends ConsumerWidget {
  const _JobTree({required this.jobs});
  final List<BuildJob> jobs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // jobKeyからジョブへのマップ
    final byKey = <String, BuildJob>{};
    for (final job in jobs) {
      if (job.jobKey != null) {
        byKey[job.jobKey!] = job;
      }
    }

    // 親→子のマップを構築
    final children = <String, List<BuildJob>>{};
    final hasParent = <String>{};

    for (final job in jobs) {
      if (job.needs != null && job.needs!.isNotEmpty && job.jobKey != null) {
        for (final parentKey in job.needs!) {
          children.putIfAbsent(parentKey, () => []).add(job);
          hasParent.add(job.jobKey!);
        }
      }
    }

    // ルートジョブ = 親を持たないジョブ
    final rootJobs =
        jobs.where((j) => j.jobKey == null || !hasParent.contains(j.jobKey!)).toList();

    final widgets = <Widget>[];
    var globalIndex = 0;
    final totalCount = jobs.length;

    void buildTree(BuildJob job, int depth, bool isLastInParent) {
      final currentIndex = globalIndex++;
      final isFirst = currentIndex == 0;
      final isLast = globalIndex == totalCount;

      widgets.add(
        _JobTreeRow(
          job: job,
          depth: depth,
          isFirst: isFirst,
          isLast: isLast,
        ),
      );

      if (!isLast) {
        widgets.add(
          Divider(
            height: 1,
            indent: 16 + (depth * 24.0) + 32,
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        );
      }

      final childJobs = job.jobKey != null ? children[job.jobKey!] ?? [] : <BuildJob>[];
      for (var i = 0; i < childJobs.length; i++) {
        buildTree(childJobs[i], depth + 1, i == childJobs.length - 1);
      }
    }

    for (var i = 0; i < rootJobs.length; i++) {
      buildTree(rootJobs[i], 0, i == rootJobs.length - 1);
    }

    return Column(children: widgets);
  }
}

class _JobTreeRow extends ConsumerWidget {
  const _JobTreeRow({
    required this.job,
    required this.depth,
    required this.isFirst,
    required this.isLast,
  });

  final BuildJob job;
  final int depth;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final jobColor = _statusColor(job.status, scheme);
    final jobLabel = _statusLabel(job.status);
    final isRunning = job.status == 'in_progress' || job.status == 'queued';

    return InkWell(
      borderRadius: isFirst
          ? const BorderRadius.vertical(top: Radius.circular(12))
          : (isLast
                ? const BorderRadius.vertical(bottom: Radius.circular(12))
                : BorderRadius.zero),
      onTap: () {
        context.push('/runs/${Uri.encodeComponent(job.id)}');
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: 16 + (depth * 24.0),
          right: 8,
          top: 12,
          bottom: 12,
        ),
        child: Row(
          children: [
            // 依存関係の視覚的コネクター
            if (depth > 0) ...[
              Icon(
                Icons.subdirectory_arrow_right_rounded,
                size: 16,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
              ),
              const SizedBox(width: 8),
            ],
            _StatusIndicator(
              status: job.status,
              color: jobColor,
              tooltip: jobLabel,
              size: 16,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.jobKey ?? 'Unnamed Job',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: depth > 0 ? 13 : 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _RunDurationBadge(buildJob: job),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                size: 18,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
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
                      leading: const Icon(
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
