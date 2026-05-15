import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/build_logs/build_jobs_provider.dart';
import 'package:dashboard/build_logs/build_logs_detail_page.dart';
import 'package:dashboard/build_logs/synced_spinner.dart';
import 'package:dashboard/extensions/date_time_extensions.dart';
import 'package:dashboard/firebase/firestore.dart' show BuildJobStatus;
import 'package:dashboard/app_strings.dart';
import 'package:dashboard/theme/app_colors.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:dashboard/utilities/function_error_message.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _recentBuildLogWindow = Duration(hours: 24);
const buildLogsSplitViewBreakpoint = 1040.0;

Color _statusColor(BuildJobStatus status) => switch (status) {
  BuildJobStatus.SUCCESS => const Color(0xFF2DA44E),
  BuildJobStatus.FAILURE => const Color(0xFFCF222E),
  BuildJobStatus.IN_PROGRESS => const Color(0xFF1F6FEB),
  BuildJobStatus.QUEUED => const Color(0xFF6E40C9),
  BuildJobStatus.CANCELLED => const Color(0xFFBF8700),
  BuildJobStatus.WAITING => const Color(0xFFBF8700),
  BuildJobStatus.SKIPPED => const Color(0xFFA1A1AA),
  BuildJobStatus.TIMED_OUT => const Color(0xFFCF222E),
};

IconData _statusIcon(BuildJobStatus status) => switch (status) {
  BuildJobStatus.SUCCESS => Icons.check_circle_rounded,
  BuildJobStatus.FAILURE => Icons.cancel_rounded,
  BuildJobStatus.IN_PROGRESS => Icons.help_outline_rounded,
  BuildJobStatus.QUEUED => Icons.schedule_rounded,
  BuildJobStatus.CANCELLED => Icons.block_rounded,
  BuildJobStatus.WAITING => Icons.adjust_rounded,
  BuildJobStatus.SKIPPED => Icons.skip_next_rounded,
  BuildJobStatus.TIMED_OUT => Icons.timer_off_rounded,
};

String _statusLabel(BuildJobStatus status) => switch (status) {
  BuildJobStatus.SUCCESS => t.buildLogs.status.success,
  BuildJobStatus.FAILURE => t.buildLogs.status.failed,
  BuildJobStatus.IN_PROGRESS => t.buildLogs.status.inProgress,
  BuildJobStatus.QUEUED => t.buildLogs.status.queued,
  BuildJobStatus.CANCELLED => t.buildLogs.status.cancelled,
  BuildJobStatus.WAITING => 'Waiting',
  BuildJobStatus.SKIPPED => 'Skipped',
  BuildJobStatus.TIMED_OUT => 'Timed out',
};

bool _isRunningStatus(BuildJobStatus status) =>
    status == BuildJobStatus.IN_PROGRESS || status == BuildJobStatus.QUEUED;

bool _isTerminalStatus(BuildJobStatus status) =>
    status == BuildJobStatus.SUCCESS ||
    status == BuildJobStatus.FAILURE ||
    status == BuildJobStatus.CANCELLED ||
    status == BuildJobStatus.SKIPPED ||
    status == BuildJobStatus.TIMED_OUT;

BuildJobStatus _overallBuildStatus(List<BuildJob> jobs) {
  if (jobs.any((job) => job.status == BuildJobStatus.IN_PROGRESS)) {
    return BuildJobStatus.IN_PROGRESS;
  }
  if (jobs.any((job) => job.status == BuildJobStatus.QUEUED)) {
    return BuildJobStatus.QUEUED;
  }
  if (jobs.any((job) => job.status == BuildJobStatus.FAILURE)) {
    return BuildJobStatus.FAILURE;
  }
  if (jobs.any((job) => job.status == BuildJobStatus.TIMED_OUT)) {
    return BuildJobStatus.TIMED_OUT;
  }
  if (jobs.any((job) => job.status == BuildJobStatus.WAITING)) {
    return BuildJobStatus.WAITING;
  }
  if (jobs.any((job) => job.status == BuildJobStatus.CANCELLED)) {
    return BuildJobStatus.CANCELLED;
  }
  if (jobs.every((job) => job.status == BuildJobStatus.SKIPPED)) {
    return BuildJobStatus.SKIPPED;
  }
  if (jobs.every(
    (job) =>
        job.status == BuildJobStatus.SUCCESS ||
        job.status == BuildJobStatus.SKIPPED,
  )) {
    return BuildJobStatus.SUCCESS;
  }
  return BuildJobStatus.SUCCESS;
}

String _workflowRunGroupKey(BuildJob job) {
  final runId = job.workflowRunId;
  if (runId == null || runId.isEmpty) return job.id;
  return '$runId:${job.workflowFileName ?? ''}';
}

void _showMaterialDefaultSnackBar(BuildContext context, String message) {
  showResponsiveSnackBar(
    context,
    content: Text(message),
  );
}

class LogsBody extends HookConsumerWidget {
  const LogsBody({super.key, this.initialBuildJobId});

  final String? initialBuildJobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedBuildJobId = useState<String?>(null);
    final state = ref.watch(buildJobsProvider);
    return state.when(
      data: (buildJobs) {
        if (buildJobs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.of(context).borderSubtle,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.of(context).divider,
                    ),
                  ),
                  child: Icon(
                    Icons.inbox_outlined,
                    size: 32,
                    color: AppColors.of(context).textTertiary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  t.buildLogs.noJobs,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.of(context).textSecondary,
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
            final groupKey = _workflowRunGroupKey(job);
            if (!groups.containsKey(groupKey)) {
              final list = <BuildJob>[];
              groups[groupKey] = list;
              orderedDisplayList.add(list);
            }
            groups[groupKey]!.add(job);
          } else {
            orderedDisplayList.add([job]);
          }
        }

        final cutoff = DateTime.now().subtract(_recentBuildLogWindow);
        final recentDisplayList = orderedDisplayList
            .where(
              (jobs) => jobs.any((job) => !job.createdAt.isBefore(cutoff)),
            )
            .toList();
        final recentStatuses = recentDisplayList
            .map(_overallBuildStatus)
            .toList();
        final runningCount = recentStatuses.where(_isRunningStatus).length;
        final successCount = recentStatuses
            .where((status) => status == BuildJobStatus.SUCCESS)
            .length;
        final failedCount = recentStatuses
            .where(
              (status) =>
                  status == BuildJobStatus.FAILURE ||
                  status == BuildJobStatus.TIMED_OUT,
            )
            .length;

        return SyncedSpinnerScope(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final usesSplitView =
                  constraints.maxWidth >= buildLogsSplitViewBreakpoint;
              final currentSelectedId =
                  selectedBuildJobId.value ?? initialBuildJobId;
              final selectedBuildJob =
                  _selectedBuildJob(buildJobs, currentSelectedId) ??
                  buildJobs.first;

              void openBuildJob(BuildJob buildJob) {
                if (usesSplitView) {
                  selectedBuildJobId.value = buildJob.id;
                  return;
                }

                context.push('/runs/${Uri.encodeComponent(buildJob.id)}');
              }

              final list = _BuildLogsList(
                orderedDisplayList: orderedDisplayList,
                recentRunCount: recentDisplayList.length,
                successCount: successCount,
                runningCount: runningCount,
                failedCount: failedCount,
                latestRunAt: buildJobs.first.createdAt,
                selectedBuildJobId: usesSplitView ? selectedBuildJob.id : null,
                onOpenBuildJob: openBuildJob,
              );

              if (!usesSplitView) {
                return list;
              }

              final listWidth = constraints.maxWidth < 1180 ? 400.0 : 440.0;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: listWidth, child: list),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: AppColors.of(context).divider,
                  ),
                  Expanded(
                    child: BuildLogsDetailPage(
                      key: ValueKey(selectedBuildJob.id),
                      buildJob: selectedBuildJob,
                      showBackButton: false,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: asyncErrorWidget,
    );
  }
}

BuildJob? _selectedBuildJob(List<BuildJob> buildJobs, String? buildJobId) {
  if (buildJobId == null || buildJobId.isEmpty) {
    return null;
  }
  for (final buildJob in buildJobs) {
    if (buildJob.id == buildJobId) {
      return buildJob;
    }
  }
  return null;
}

class _BuildLogsList extends StatelessWidget {
  const _BuildLogsList({
    required this.orderedDisplayList,
    required this.recentRunCount,
    required this.successCount,
    required this.runningCount,
    required this.failedCount,
    required this.latestRunAt,
    required this.selectedBuildJobId,
    required this.onOpenBuildJob,
  });

  final List<List<BuildJob>> orderedDisplayList;
  final int recentRunCount;
  final int successCount;
  final int runningCount;
  final int failedCount;
  final DateTime latestRunAt;
  final String? selectedBuildJobId;
  final ValueChanged<BuildJob> onOpenBuildJob;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 420 ? 12.0 : 16.0;
        final topPadding = constraints.maxWidth >= 840 ? 28.0 : 20.0;

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            topPadding,
            horizontalPadding,
            24,
          ),
          itemCount: orderedDisplayList.length + 1,
          itemBuilder: (_, index) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: index == 0
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _BuildLogsOverview(
                          runCount: recentRunCount,
                          successCount: successCount,
                          runningCount: runningCount,
                          failedCount: failedCount,
                          latestRunAt: latestRunAt,
                        ),
                      )
                    : _BuildRunCard(
                        jobs: orderedDisplayList[index - 1],
                        selectedBuildJobId: selectedBuildJobId,
                        onOpenBuildJob: onOpenBuildJob,
                      ),
              ),
            );
          },
        );
      },
    );
  }
}

class _BuildLogsOverview extends StatelessWidget {
  const _BuildLogsOverview({
    required this.runCount,
    required this.successCount,
    required this.runningCount,
    required this.failedCount,
    required this.latestRunAt,
  });

  final int runCount;
  final int successCount;
  final int runningCount;
  final int failedCount;
  final DateTime latestRunAt;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colors.accentSubtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.history_rounded,
                  color: colors.accent,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.buildLogs.overviewTitle,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      t.buildLogs.latestRun(time: latestRunAt.toTimeAgo()),
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _BuildLogSummaryPill(
                icon: Icons.format_list_bulleted_rounded,
                label: t.buildLogs.summaryRuns,
                value: runCount.toString(),
                color: colors.textSecondary,
              ),
              _BuildLogSummaryPill(
                icon: Icons.check_circle_outline_rounded,
                label: t.buildLogs.summarySuccess,
                value: successCount.toString(),
                color: colors.success,
              ),
              _BuildLogSummaryPill(
                icon: Icons.play_circle_outline_rounded,
                label: t.buildLogs.summaryRunning,
                value: runningCount.toString(),
                color: colors.accent,
              ),
              _BuildLogSummaryPill(
                icon: Icons.error_outline_rounded,
                label: t.buildLogs.summaryFailed,
                value: failedCount.toString(),
                color: colors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BuildLogSummaryPill extends StatelessWidget {
  const _BuildLogSummaryPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      constraints: const BoxConstraints(minWidth: 112),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BuildRunCard extends StatelessWidget {
  const _BuildRunCard({
    required this.jobs,
    required this.selectedBuildJobId,
    required this.onOpenBuildJob,
  });

  final List<BuildJob> jobs;
  final String? selectedBuildJobId;
  final ValueChanged<BuildJob> onOpenBuildJob;

  @override
  Widget build(BuildContext context) {
    if (jobs.length == 1) {
      final buildJob = jobs.first;
      return BuildJobCard(
        buildJob: buildJob,
        selected: selectedBuildJobId == buildJob.id,
        onOpenBuildJob: onOpenBuildJob,
      );
    }
    return WorkflowRunCard(
      jobs: jobs,
      selectedBuildJobId: selectedBuildJobId,
      onOpenBuildJob: onOpenBuildJob,
    );
  }
}

class BuildJobCard extends HookConsumerWidget {
  const BuildJobCard({
    super.key,
    required this.buildJob,
    this.selected = false,
    this.onOpenBuildJob,
  });

  final BuildJob buildJob;
  final bool selected;
  final ValueChanged<BuildJob>? onOpenBuildJob;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _statusColor(buildJob.status);
    final statusLabel = _statusLabel(buildJob.status);
    final isRunning = _isRunningStatus(buildJob.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.of(context).accentSubtle.withValues(alpha: 0.35)
            : AppColors.of(context).surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? AppColors.of(context).borderFocused
              : AppColors.of(context).border,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final onOpen = onOpenBuildJob;
            if (onOpen == null) {
              context.push('/runs/${Uri.encodeComponent(buildJob.id)}');
              return;
            }
            onOpen(buildJob);
          },
          borderRadius: BorderRadius.circular(12),
          hoverColor: AppColors.of(context).borderSubtle,
          splashColor: AppColors.of(context).borderSubtle,
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
                            child: Text(
                              buildJob.jobKey != null
                                  ? '${buildJob.workflowName} (${buildJob.jobKey})'
                                  : buildJob.workflowName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.of(context).textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            buildJob.createdAt.toTimeAgo(),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.of(context).textTertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _StatusBadge(
                            status: buildJob.status,
                            color: color,
                            label: statusLabel,
                          ),
                          _LiveDurationBadge(buildJob: buildJob),
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
                const SizedBox(width: 4),
                _MoreMenuButton(
                  onSelected: (value) async {
                    switch (value) {
                      case 'details':
                        final onOpen = onOpenBuildJob;
                        if (onOpen == null) {
                          await context.push(
                            '/runs/${Uri.encodeComponent(buildJob.id)}',
                          );
                          return;
                        }
                        onOpen(buildJob);
                      case 'retry':
                        try {
                          await ref
                              .read(buildJobsProvider.notifier)
                              .retryBuildJob(buildJob.id);
                          if (context.mounted) {
                            _showMaterialDefaultSnackBar(
                              context,
                              t.buildLogs.detail.retrySuccess,
                            );
                          }
                        } on FirebaseFunctionsException catch (e, s) {
                          final errorMessage =
                              await FunctionErrorMessage.capture(
                                e,
                                stackTrace: s,
                              );
                          if (context.mounted) {
                            _showMaterialDefaultSnackBar(
                              context,
                              errorMessage.message,
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            debugPrint('failed to retry: $e');
                            _showMaterialDefaultSnackBar(
                              context,
                              t.buildLogs.detail.failedToRetry(
                                error: e.toString(),
                              ),
                            );
                          }
                        }
                      case 'cancel':
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: AppColors.of(context).surfaceHover,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: AppColors.of(context).border,
                              ),
                            ),
                            title: Text(
                              t.buildLogs.detail.cancelBuild,
                              style: TextStyle(
                                color: AppColors.of(context).textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            content: Text(
                              t.buildLogs.detail.cancelConfirm,
                              style: TextStyle(
                                color: AppColors.of(context).textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(
                                  t.buildLogs.detail.cancelNo,
                                  style: TextStyle(
                                    color: AppColors.of(context).textSecondary,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFEF4444),
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
                            showResponsiveSnackBar(
                              context,
                              content: Text(
                                t.buildLogs.detail.buildCancelled,
                              ),
                            );
                          }
                        } on FirebaseFunctionsException catch (e, s) {
                          final errorMessage =
                              await FunctionErrorMessage.capture(
                                e,
                                stackTrace: s,
                              );
                          if (context.mounted) {
                            showResponsiveSnackBar(
                              context,
                              content: Text(errorMessage.message),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            showResponsiveSnackBar(
                              context,
                              content: Text(
                                t.buildLogs.detail.failedToCancel(
                                  error: e.toString(),
                                ),
                              ),
                            );
                          }
                        }
                    }
                  },
                  items: [
                    _MenuItemData(
                      value: 'details',
                      icon: Icons.arrow_outward_rounded,
                      label: t.buildLogs.detail.viewDetails,
                    ),
                    _MenuItemData(
                      value: 'retry',
                      icon: Icons.refresh_rounded,
                      label: t.buildLogs.detail.retry,
                    ),
                    if (isRunning)
                      _MenuItemData(
                        value: 'cancel',
                        icon: Icons.stop_circle_outlined,
                        label: t.common.cancel,
                        isDestructive: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WorkflowRunCard extends HookConsumerWidget {
  const WorkflowRunCard({
    super.key,
    required this.jobs,
    this.selectedBuildJobId,
    this.onOpenBuildJob,
  });

  final List<BuildJob> jobs;
  final String? selectedBuildJobId;
  final ValueChanged<BuildJob>? onOpenBuildJob;

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

    final mainJob = jobs.first;

    final overallStatus = _overallBuildStatus(jobs);
    final color = _statusColor(overallStatus);
    final statusLabel = _statusLabel(overallStatus);
    final selected = jobs.any((job) => job.id == selectedBuildJobId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.of(context).accentSubtle.withValues(alpha: 0.28)
            : AppColors.of(context).surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? AppColors.of(context).borderFocused
              : AppColors.of(context).border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        mainJob.workflowName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.of(context).textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      mainJob.createdAt.toTimeAgo(),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.of(context).textTertiary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    _MoreMenuButton(
                      onSelected: (value) async {
                        if (value == 'retry_all') {
                          try {
                            await ref
                                .read(buildJobsProvider.notifier)
                                .retryWorkflowRun(
                                  mainJob.workflowRunId!,
                                  workflowFileName: mainJob.workflowFileName,
                                );
                            if (context.mounted) {
                              _showMaterialDefaultSnackBar(
                                context,
                                t.buildLogs.detail.retrySuccess,
                              );
                            }
                          } on FirebaseFunctionsException catch (e, s) {
                            final errorMessage =
                                await FunctionErrorMessage.capture(
                                  e,
                                  stackTrace: s,
                                );
                            if (context.mounted) {
                              _showMaterialDefaultSnackBar(
                                context,
                                errorMessage.message,
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              _showMaterialDefaultSnackBar(
                                context,
                                t.buildLogs.detail.failedToRetry(
                                  error: e.toString(),
                                ),
                              );
                            }
                          }
                        }
                      },
                      items: [
                        _MenuItemData(
                          value: 'retry_all',
                          icon: Icons.refresh_rounded,
                          label: t.buildLogs.detail.retry,
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
                    _StatusBadge(
                      status: overallStatus,
                      color: color,
                      label: statusLabel,
                    ),
                    _WorkflowDurationBadge(
                      jobs: jobs,
                      overallStatus: overallStatus,
                    ),
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
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.of(context).borderSubtle,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.of(context).divider,
                ),
              ),
              child: _JobTree(
                jobs: _sortedJobs,
                selectedBuildJobId: selectedBuildJobId,
                onOpenBuildJob: onOpenBuildJob,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status pill badge ────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
    required this.color,
    required this.label,
  });

  final BuildJobStatus status;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == BuildJobStatus.IN_PROGRESS)
            SyncedSpinner(color: color, size: 10)
          else
            Icon(_statusIcon(status), color: color, size: 12),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status indicator (for tree rows) ────────────────────────────────────────

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({
    required this.status,
    required this.color,
    required this.tooltip,
    this.size = 18,
  });

  final BuildJobStatus status;
  final Color color;
  final String tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (status == BuildJobStatus.IN_PROGRESS) {
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

String _formatDurationCompact(Duration duration) {
  final totalSeconds = duration.inSeconds;
  if (totalSeconds < 60) return '${totalSeconds}s';
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  final ss = seconds.toString().padLeft(2, '0');
  if (minutes < 60) return '${minutes}m ${ss}s';
  final hours = minutes ~/ 60;
  final mm = (minutes % 60).toString().padLeft(2, '0');
  return '${hours}h ${mm}m';
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.of(context).borderSubtle,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.of(context).border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon is! SizedBox) ...[
            IconTheme(
              data: IconThemeData(
                size: 10,
                color: AppColors.of(context).textTertiary,
              ),
              child: icon,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
              color: AppColors.of(context).textSecondary,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.of(context).borderSubtle,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.of(context).border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_tree_outlined,
            size: 11,
            color: AppColors.of(context).textTertiary,
          ),
          const SizedBox(width: 4),
          for (int i = 0; i < needs.length; i++) ...[
            Text(
              needs[i],
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                fontFamily: 'monospace',
                color: AppColors.of(context).textSecondary,
              ),
            ),
            if (i < needs.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Icon(
                  Icons.add,
                  size: 9,
                  color: AppColors.of(context).textTertiary,
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
  const _JobTree({
    required this.jobs,
    required this.selectedBuildJobId,
    required this.onOpenBuildJob,
  });

  final List<BuildJob> jobs;
  final String? selectedBuildJobId;
  final ValueChanged<BuildJob>? onOpenBuildJob;

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
    final rootJobs = jobs
        .where((j) => j.jobKey == null || !hasParent.contains(j.jobKey!))
        .toList();

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
          selected: job.id == selectedBuildJobId,
          onOpenBuildJob: onOpenBuildJob,
        ),
      );

      if (!isLast) {
        widgets.add(
          Divider(
            height: 1,
            indent: 16 + (depth * 24.0) + 32,
            color: AppColors.of(context).borderSubtle,
          ),
        );
      }

      final childJobs = job.jobKey != null
          ? children[job.jobKey!] ?? []
          : <BuildJob>[];
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
    required this.selected,
    required this.onOpenBuildJob,
  });

  final BuildJob job;
  final int depth;
  final bool isFirst;
  final bool isLast;
  final bool selected;
  final ValueChanged<BuildJob>? onOpenBuildJob;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobColor = _statusColor(job.status);
    final jobLabel = _statusLabel(job.status);
    final isRunning = _isRunningStatus(job.status);

    return InkWell(
      borderRadius: isFirst
          ? const BorderRadius.vertical(top: Radius.circular(10))
          : (isLast
                ? const BorderRadius.vertical(bottom: Radius.circular(10))
                : BorderRadius.zero),
      hoverColor: AppColors.of(context).borderSubtle,
      splashColor: AppColors.of(context).borderSubtle,
      onTap: () {
        final onOpen = onOpenBuildJob;
        if (onOpen == null) {
          context.push('/runs/${Uri.encodeComponent(job.id)}');
          return;
        }
        onOpen(job);
      },
      child: ColoredBox(
        color: selected
            ? AppColors.of(context).accentSubtle.withValues(alpha: 0.55)
            : Colors.transparent,
        child: Padding(
          padding: EdgeInsets.only(
            left: 16 + (depth * 24.0),
            right: 8,
            top: 10,
            bottom: 10,
          ),
          child: Row(
            children: [
              // 依存関係の視覚的コネクター
              if (depth > 0) ...[
                Icon(
                  Icons.subdirectory_arrow_right_rounded,
                  size: 14,
                  color: AppColors.of(context).border,
                ),
                const SizedBox(width: 8),
              ],
              _StatusIndicator(
                status: job.status,
                color: jobColor,
                tooltip: jobLabel,
                size: 16,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.jobKey ?? 'Unnamed Job',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: AppColors.of(context).textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _LiveDurationBadge(buildJob: job),
                        if (job.status == BuildJobStatus.FAILURE &&
                            job.failureSummaryStatus == 'generating') ...[
                          const SizedBox(width: 8),
                          _AiGeneratingBadge(),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              _MoreMenuButton(
                size: 18,
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
                items: [
                  _MenuItemData(
                    value: 'retry',
                    icon: Icons.refresh_rounded,
                    label: t.buildLogs.detail.retry,
                  ),
                  if (isRunning)
                    _MenuItemData(
                      value: 'cancel',
                      icon: Icons.stop_circle_outlined,
                      label: t.common.cancel,
                      isDestructive: true,
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

class _LiveDurationBadge extends HookConsumerWidget {
  const _LiveDurationBadge({required this.buildJob});
  final BuildJob buildJob;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRunning = buildJob.status == BuildJobStatus.IN_PROGRESS;
    final isTerminal = _isTerminalStatus(buildJob.status);

    // Tick every second while running
    final tick = useState(0);
    useEffect(() {
      if (!isRunning) return null;
      final timer = Stream.periodic(const Duration(seconds: 1)).listen((_) {
        tick.value++;
      });
      return timer.cancel;
    }, [isRunning]);

    // While running: show elapsed from createdAt
    if (isRunning) {
      // Suppress unused variable warning; tick.value read forces rebuild
      tick.value;
      final elapsed = DateTime.now().toUtc().difference(buildJob.createdAt);
      return _InfoBadge(
        icon: const Icon(Icons.timer_outlined, size: 10),
        label: _formatDurationCompact(elapsed),
      );
    }

    // Terminal: use the run's actual duration when it is available.
    if (isTerminal) {
      final durationAsync = ref.watch(runDurationProvider(buildJob));
      return durationAsync.when(
        data: (duration) {
          if (duration == null) return const SizedBox.shrink();
          return _InfoBadge(
            icon: const Icon(Icons.timer_outlined, size: 10),
            label: _formatDurationCompact(duration),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
      );
    }

    return const SizedBox.shrink();
  }
}

class _WorkflowDurationBadge extends HookWidget {
  const _WorkflowDurationBadge({
    required this.jobs,
    required this.overallStatus,
  });
  final List<BuildJob> jobs;
  final BuildJobStatus overallStatus;

  @override
  Widget build(BuildContext context) {
    final isRunning = _isRunningStatus(overallStatus);
    final isTerminal = _isTerminalStatus(overallStatus);

    // Tick every second while running
    final tick = useState(0);
    useEffect(() {
      if (!isRunning) return null;
      final timer = Stream.periodic(const Duration(seconds: 1)).listen((_) {
        tick.value++;
      });
      return timer.cancel;
    }, [isRunning]);

    final earliestCreatedAt = jobs
        .map((j) => j.createdAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);

    if (isRunning) {
      tick.value;
      final elapsed = DateTime.now().toUtc().difference(earliestCreatedAt);
      return _InfoBadge(
        icon: const Icon(Icons.timer_outlined, size: 10),
        label: _formatDurationCompact(elapsed),
      );
    }

    if (isTerminal) {
      final latestUpdatedAt = jobs
          .map((j) => j.completedAt ?? j.updatedAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      final duration = latestUpdatedAt.difference(earliestCreatedAt);
      if (duration.isNegative || duration.inSeconds == 0) {
        return const SizedBox.shrink();
      }
      return _InfoBadge(
        icon: const Icon(Icons.timer_outlined, size: 10),
        label: _formatDurationCompact(duration),
      );
    }

    return const SizedBox.shrink();
  }
}

// ── AI Generating badge ─────────────────────────────────────────────────────

class _AiGeneratingBadge extends StatefulWidget {
  @override
  State<_AiGeneratingBadge> createState() => _AiGeneratingBadgeState();
}

class _AiGeneratingBadgeState extends State<_AiGeneratingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const aiColor = Color(0xFFD29922);
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: aiColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: aiColor.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 10,
              color: aiColor.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 4),
            Text(
              t.buildLogs.detail.generatingSummary,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: aiColor.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared menu components ──────────────────────────────────────────────────

class _MenuItemData {
  const _MenuItemData({
    required this.value,
    required this.icon,
    required this.label,
    this.isDestructive = false,
  });

  final String value;
  final IconData icon;
  final String label;
  final bool isDestructive;
}

class _MoreMenuButton extends StatelessWidget {
  const _MoreMenuButton({
    required this.onSelected,
    required this.items,
    this.size = 20,
  });

  final ValueChanged<String> onSelected;
  final List<_MenuItemData> items;
  final double size;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz_rounded,
        size: size,
        color: AppColors.of(context).textTertiary,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      color: AppColors.of(context).surfaceHover,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: AppColors.of(context).border,
        ),
      ),
      onSelected: onSelected,
      itemBuilder: (_) => items.map((item) {
        final color = item.isDestructive
            ? const Color(0xFFEF4444)
            : AppColors.of(context).textPrimary;
        return PopupMenuItem<String>(
          value: item.value,
          height: 36,
          child: Row(
            children: [
              Icon(item.icon, size: 16, color: color),
              const SizedBox(width: 10),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
