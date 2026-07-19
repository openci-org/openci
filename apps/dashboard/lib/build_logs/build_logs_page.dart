import 'package:dashboard/app_strings.dart';
import 'package:dashboard/build_logs/branch_job_row.dart';
import 'package:dashboard/build_logs/branch_matrix_variant_row.dart';
import 'package:dashboard/build_logs/build_job_log.dart';
import 'package:dashboard/build_logs/build_jobs_provider.dart';

import 'package:dashboard/build_logs/chips/job_chip.dart';
import 'package:dashboard/build_logs/chips/job_status.dart';
import 'package:dashboard/build_logs/chips/matrix_job_chip.dart';
import 'package:dashboard/build_logs/job_card.dart';
import 'package:dashboard/build_logs/synced_spinner.dart';
import 'package:dashboard/theme/app_colors.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _recentBuildLogWindow = Duration(hours: 24);

ChipStatus _toChipStatus(BuildJobStatus status) => switch (status) {
  BuildJobStatus.SUCCESS => ChipStatus.success,
  BuildJobStatus.FAILURE || BuildJobStatus.TIMED_OUT => ChipStatus.fail,
  BuildJobStatus.IN_PROGRESS => ChipStatus.inProgress,
  BuildJobStatus.QUEUED || BuildJobStatus.WAITING => ChipStatus.queued,
  BuildJobStatus.CANCELLED => ChipStatus.cancelled,
  BuildJobStatus.SKIPPED => ChipStatus.skipped,
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
          child: _BuildLogsList(
            orderedDisplayList: orderedDisplayList,
            recentRunCount: recentDisplayList.length,
            successCount: successCount,
            runningCount: runningCount,
            failedCount: failedCount,
            latestRunAt: buildJobs.first.createdAt,
            selectedBuildJobId: null,
            onOpenBuildJob: (buildJob) {
              context.push('/runs/${Uri.encodeComponent(buildJob.id)}');
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: asyncErrorWidget,
    );
  }
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
          itemCount: orderedDisplayList.length,
          itemBuilder: (_, index) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: _BuildRunCard(
                  jobs: orderedDisplayList[index],
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
    final Widget card;
    if (jobs.length == 1) {
      final buildJob = jobs.first;
      card = BuildJobCard(
        buildJob: buildJob,
        selected: selectedBuildJobId == buildJob.id,
        onOpenBuildJob: onOpenBuildJob,
      );
    } else {
      card = WorkflowRunCard(
        jobs: jobs,
        selectedBuildJobId: selectedBuildJobId,
        onOpenBuildJob: onOpenBuildJob,
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: card,
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
    return JobCard(
      onTap: () {
        final onOpen = onOpenBuildJob;
        if (onOpen == null) {
          context.push('/runs/${Uri.encodeComponent(buildJob.id)}');
          return;
        }
        onOpen(buildJob);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: BuildJobLogCard(
              buildJob: buildJob,
              title: buildJob.workflowName,
              durationWidget: _LiveDurationBadge(buildJob: buildJob),
              jobs: [
                JobChip(
                  label: _buildJobDisplayKey(buildJob),
                  status: _toChipStatus(buildJob.status),
                  durationWidget: _InlineLiveDuration(buildJob: buildJob),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
              }
            },
            items: [
              _MenuItemData(
                value: 'details',
                icon: Icons.arrow_outward_rounded,
                label: t.buildLogs.detail.viewDetails,
              ),
            ],
          ),
        ],
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (jobs.isEmpty) return const SizedBox.shrink();

    final mainJob = jobs.first;
    final overallStatus = _overallBuildStatus(jobs);
    final isExpanded = useState(false);

    // workflowJobKey (フォールバックとして jobKey) でグループ化
    final Map<String, List<BuildJob>> groups = {};
    for (final job in jobs) {
      final key = (job.workflowJobKey != null && job.workflowJobKey!.isNotEmpty)
          ? job.workflowJobKey!
          : (job.jobKey ?? 'unknown');
      groups.putIfAbsent(key, () => []).add(job);
    }
    final hasMatrix = groups.values.any((g) => g.length > 1);

    // 依存関係（needs）を持つジョブが1つでもあるか
    final hasNeeds = jobs.any(
      (job) => job.needs != null && job.needs!.isNotEmpty,
    );

    final usePatternB = hasNeeds || hasMatrix;

    if (!usePatternB) {
      // ── パターンA: 直線型（マトリックスなどはない単純直列） ───────────────────────
      final jobChips = <Widget>[];
      final groupKeys = groups.keys.toList();

      for (var i = 0; i < groupKeys.length; i++) {
        final key = groupKeys[i];
        final groupJobs = groups[key]!;
        final job = groupJobs.first;
        jobChips.add(
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => onOpenBuildJob?.call(job),
            child: JobChip(
              label: _buildJobDisplayKey(job),
              status: _toChipStatus(job.status),
              durationWidget: _InlineLiveDuration(buildJob: job),
            ),
          ),
        );

        if (i < groupKeys.length - 1) {
          jobChips.add(const ArrowRightIcon());
        }
      }

      return JobCard(
        status: overallStatus,
        onTap: () {
          onOpenBuildJob?.call(mainJob);
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: BuildJobLogCard(
                buildJob: mainJob,
                title: mainJob.workflowName,
                durationWidget: _WorkflowDurationBadge(
                  jobs: jobs,
                  overallStatus: overallStatus,
                ),
                isExpanded: isExpanded.value,
                jobs: jobChips,
              ),
            ),
          ],
        ),
      );
    } else {
      // ── パターンB: needs依存関係による並列分岐 ───────────────────
      final jobsMap = {
        for (final entry in groups.entries) entry.key: entry.value.first,
      };
      final requiredBy = <String>{};
      for (final job in jobs) {
        if (job.needs != null) {
          requiredBy.addAll(job.needs!);
        }
      }

      final leafJobKeys = groups.keys
          .where((key) => !requiredBy.contains(key))
          .toList();
      final effectiveLeafKeys = leafJobKeys.isEmpty
          ? groups.keys.toList()
          : leafJobKeys;

      // トポロジカルソート
      final depJobKeys = <String>[];
      final visited = <String>{};

      void visit(String key) {
        if (visited.contains(key)) return;
        final job = jobsMap[key];
        if (job == null) return;

        if (job.needs != null) {
          for (final reqKey in job.needs!) {
            visit(reqKey);
          }
        }

        if (!effectiveLeafKeys.contains(key)) {
          visited.add(key);
          depJobKeys.add(key);
        }
      }

      for (final key in groups.keys) {
        visit(key);
      }

      final dependencyWidgets = <Widget>[];
      for (final key in depJobKeys) {
        final groupJobs = groups[key]!;
        final groupOverallStatus = _overallBuildStatus(groupJobs);
        if (groupJobs.length > 1) {
          dependencyWidgets.add(
            MatrixJobChip(
              label: key,
              count: groupJobs.length,
              status: _toChipStatus(groupOverallStatus),
              isExpanded: isExpanded.value,
              onTap: () {
                isExpanded.value = !isExpanded.value;
              },
              durationWidget: _InlineWorkflowDuration(
                jobs: groupJobs,
                overallStatus: groupOverallStatus,
              ),
            ),
          );
        } else {
          final job = groupJobs.first;
          dependencyWidgets.add(
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => onOpenBuildJob?.call(job),
              child: JobChip(
                label: _buildJobDisplayKey(job),
                status: _toChipStatus(job.status),
                durationWidget: _InlineLiveDuration(buildJob: job),
              ),
            ),
          );
        }
      }

      final needWidgets = <Widget>[];
      final total = effectiveLeafKeys.length;
      final showConnection = !(dependencyWidgets.isEmpty && total == 1);
      for (var i = 0; i < total; i++) {
        final key = effectiveLeafKeys[i];
        final groupJobs = groups[key]!;
        final groupOverallStatus = _overallBuildStatus(groupJobs);

        if (groupJobs.length > 1) {
          needWidgets.add(
            BranchJobRow(
              label: key,
              status: _toChipStatus(groupOverallStatus),
              index: i,
              total: total,
              showConnection: showConnection,
              durationWidget: _InlineWorkflowDuration(
                jobs: groupJobs,
                overallStatus: groupOverallStatus,
              ),
              child: MatrixJobChip(
                label: key,
                count: groupJobs.length,
                status: _toChipStatus(groupOverallStatus),
                isExpanded: isExpanded.value,
                onTap: () {
                  isExpanded.value = !isExpanded.value;
                },
              ),
            ),
          );
          needWidgets.add(
            _AnimatedHeightVisibility(
              visible: isExpanded.value,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (
                    var variantIndex = 0;
                    variantIndex < groupJobs.length;
                    variantIndex++
                  )
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () =>
                          onOpenBuildJob?.call(groupJobs[variantIndex]),
                      child: BranchMatrixVariantRow(
                        variantLabel:
                            groupJobs[variantIndex].displayMatrixLabel ??
                            _buildJobDisplayKey(groupJobs[variantIndex]),
                        status: _toChipStatus(groupJobs[variantIndex].status),
                        parentIndex: i,
                        parentTotal: total,
                        variantIndex: variantIndex,
                        variantTotal: groupJobs.length,
                        showConnection: showConnection,
                        durationWidget: _InlineLiveDuration(
                          buildJob: groupJobs[variantIndex],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        } else {
          final job = groupJobs.first;
          needWidgets.add(
            BranchJobRow(
              label: _buildJobDisplayKey(job),
              status: _toChipStatus(job.status),
              index: i,
              total: total,
              showConnection: showConnection,
              onTap: () => onOpenBuildJob?.call(job),
              durationWidget: _InlineLiveDuration(buildJob: job),
            ),
          );
        }
      }

      final representativeJob =
          jobsMap[effectiveLeafKeys.firstOrNull ?? 'unknown'] ?? mainJob;

      return JobCard(
        status: overallStatus,
        onTap: () {
          onOpenBuildJob?.call(representativeJob);
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: BuildJobLogCard(
                buildJob: representativeJob,
                title: representativeJob.workflowName,
                durationWidget: _WorkflowDurationBadge(
                  jobs: jobs,
                  overallStatus: overallStatus,
                ),
                isExpanded: isExpanded.value,
                dependencies: dependencyWidgets,
                needs: needWidgets,
              ),
            ),
          ],
        ),
      );
    }
  }
}

// _WorkflowMoreMenu was removed since retry/cancel build features are deprecated

// ── Status pill badge ────────────────────────────────────────────────────────

// ── Shared utility widgets ──────────────────────────────────────────────────

String _formatDurationCompact(Duration duration) {
  final totalSeconds = duration.inSeconds;
  if (totalSeconds < 60) return '$totalSeconds秒';
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  if (minutes < 60) return '$minutes分$seconds秒';
  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  return '$hours時間$remainingMinutes分';
}

/// ジョブをneeds依存関係に基づいてツリー構造で表示するウィジェット
String _buildJobDisplayKey(BuildJob job) {
  final workflowJobKey = job.workflowJobKey;
  if (workflowJobKey != null && workflowJobKey.isNotEmpty) {
    return workflowJobKey;
  }
  final jobKey = job.jobKey;
  if (jobKey != null && jobKey.isNotEmpty) return jobKey;
  return 'Unnamed Job';
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

    // While running: show elapsed from when the worker picked up this job.
    if (isRunning) {
      tick.value;
      final elapsed = DateTime.now().toUtc().difference(buildJob.updatedAt);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.timer_outlined,
            size: 12,
            color: Color(0xFF98A2B3),
          ),
          const SizedBox(width: 4),
          Text(
            _formatDurationCompact(
              elapsed.isNegative ? Duration.zero : elapsed,
            ),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF667085),
            ),
          ),
        ],
      );
    }

    // Terminal: use the run's actual duration when it is available.
    if (isTerminal) {
      final durationAsync = ref.watch(runDurationProvider(buildJob));
      return durationAsync.when(
        data: (duration) {
          if (duration == null) return const SizedBox.shrink();
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.timer_outlined,
                size: 12,
                color: Color(0xFF98A2B3),
              ),
              const SizedBox(width: 4),
              Text(
                _formatDurationCompact(duration),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF667085),
                ),
              ),
            ],
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
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.timer_outlined,
            size: 12,
            color: Color(0xFF98A2B3),
          ),
          const SizedBox(width: 4),
          Text(
            _formatDurationCompact(elapsed),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF667085),
            ),
          ),
        ],
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
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.timer_outlined,
            size: 12,
            color: Color(0xFF98A2B3),
          ),
          const SizedBox(width: 4),
          Text(
            _formatDurationCompact(duration),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF667085),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

class _InlineLiveDuration extends HookConsumerWidget {
  const _InlineLiveDuration({required this.buildJob});
  final BuildJob buildJob;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRunning = buildJob.status == BuildJobStatus.IN_PROGRESS;
    final isTerminal = _isTerminalStatus(buildJob.status);

    final tick = useState(0);
    useEffect(() {
      if (!isRunning) return null;
      final timer = Stream.periodic(const Duration(seconds: 1)).listen((_) {
        tick.value++;
      });
      return timer.cancel;
    }, [isRunning]);

    if (isRunning) {
      tick.value;
      final elapsed = DateTime.now().toUtc().difference(buildJob.updatedAt);
      return Text(
        ' · ${_formatDurationCompact(elapsed.isNegative ? Duration.zero : elapsed)}',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    if (isTerminal) {
      final durationAsync = ref.watch(runDurationProvider(buildJob));
      return durationAsync.when(
        data: (duration) {
          if (duration == null ||
              duration.isNegative ||
              duration.inSeconds == 0) {
            return const SizedBox.shrink();
          }
          return Text(
            ' · ${_formatDurationCompact(duration)}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
      );
    }

    return const SizedBox.shrink();
  }
}

class _InlineWorkflowDuration extends HookWidget {
  const _InlineWorkflowDuration({
    required this.jobs,
    required this.overallStatus,
  });
  final List<BuildJob> jobs;
  final BuildJobStatus overallStatus;

  @override
  Widget build(BuildContext context) {
    final isRunning = overallStatus == BuildJobStatus.IN_PROGRESS;
    final isTerminal = _isTerminalStatus(overallStatus);

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
      return Text(
        ' · ${_formatDurationCompact(elapsed)}',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
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
      return Text(
        ' · ${_formatDurationCompact(duration)}',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
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
  });

  final String value;
  final IconData icon;
  final String label;
}

class _MoreMenuButton extends StatelessWidget {
  const _MoreMenuButton({
    required this.onSelected,
    required this.items,
  });

  final ValueChanged<String> onSelected;
  final List<_MenuItemData> items;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz_rounded,
        size: 20,
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
        final color = AppColors.of(context).textPrimary;
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

class _AnimatedHeightVisibility extends StatefulWidget {
  const _AnimatedHeightVisibility({
    required this.visible,
    required this.child,
  });

  final bool visible;
  final Widget child;

  @override
  State<_AnimatedHeightVisibility> createState() =>
      _AnimatedHeightVisibilityState();
}

class _AnimatedHeightVisibilityState extends State<_AnimatedHeightVisibility>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    if (widget.visible) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedHeightVisibility oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) {
      if (widget.visible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        if (_controller.isDismissed && !widget.visible) {
          return const SizedBox.shrink();
        }
        return SizeTransition(
          axis: Axis.vertical,
          sizeFactor: _animation,
          child: widget.child,
        );
      },
    );
  }
}
