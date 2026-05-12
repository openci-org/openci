import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/build_logs/build_jobs_provider.dart';
import 'package:dashboard/build_logs/build_logs_provider.dart';
import 'package:dashboard/build_logs/synced_spinner.dart';
import 'package:dashboard/firebase/firestore.dart' show BuildJobStatus;
import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/theme/app_colors.dart';
import 'package:dashboard/utilities/function_error_message.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum _ActionState { idle, loading, done }

void _showMaterialDefaultSnackBar(BuildContext context, String message) {
  showResponsiveSnackBar(
    context,
    content: Text(message),
  );
}

class BuildLogsDetailPage extends HookConsumerWidget {
  const BuildLogsDetailPage({super.key, required this.buildJob});
  final BuildJob buildJob;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workflowName = buildJob.workflowName;
    final detailT = t.buildLogs.detail;
    final retryState = useState(_ActionState.idle);

    final statusColor = switch (buildJob.status) {
      BuildJobStatus.SUCCESS => const Color(0xFF3FB950),
      BuildJobStatus.FAILURE => const Color(0xFFF85149),
      BuildJobStatus.IN_PROGRESS => const Color(0xFF58A6FF),
      BuildJobStatus.QUEUED => const Color(0xFFBC8CFF),
      BuildJobStatus.CANCELLED => const Color(0xFFD29922),
      BuildJobStatus.WAITING => const Color(0xFFD29922),
      BuildJobStatus.SKIPPED => AppColors.of(context).textTertiary,
      BuildJobStatus.TIMED_OUT => const Color(0xFFF85149),
    };

    final statusIcon = switch (buildJob.status) {
      BuildJobStatus.SUCCESS => Icons.check_circle_rounded,
      BuildJobStatus.FAILURE => Icons.cancel_rounded,
      BuildJobStatus.IN_PROGRESS => Icons.help_outline_rounded,
      BuildJobStatus.QUEUED => Icons.schedule_rounded,
      BuildJobStatus.CANCELLED => Icons.block_rounded,
      BuildJobStatus.WAITING => Icons.adjust_rounded,
      BuildJobStatus.SKIPPED => Icons.skip_next_rounded,
      BuildJobStatus.TIMED_OUT => Icons.timer_off_rounded,
    };

    final statusLabel = switch (buildJob.status) {
      BuildJobStatus.SUCCESS => t.buildLogs.status.success,
      BuildJobStatus.FAILURE => t.buildLogs.status.failed,
      BuildJobStatus.IN_PROGRESS => t.buildLogs.status.inProgress,
      BuildJobStatus.QUEUED => t.buildLogs.status.queued,
      BuildJobStatus.CANCELLED => t.buildLogs.status.cancelled,
      BuildJobStatus.WAITING => 'Waiting',
      BuildJobStatus.SKIPPED => 'Skipped',
      BuildJobStatus.TIMED_OUT => 'Timed out',
    };

    final canCancel =
        buildJob.status == BuildJobStatus.QUEUED ||
        buildJob.status == BuildJobStatus.IN_PROGRESS;

    return SyncedSpinnerScope(
      child: Scaffold(
        backgroundColor: AppColors.of(context).scaffold,
        appBar: AppBar(
          backgroundColor: AppColors.of(context).surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: AppColors.of(context).textSecondary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            workflowName,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppColors.of(context).textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          actions: [
            if (canCancel)
              IconButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppColors.of(context).surfaceHover,
                      surfaceTintColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: AppColors.of(context).border,
                        ),
                      ),
                      title: Text(
                        detailT.cancelBuild,
                        style: TextStyle(
                          color: AppColors.of(context).textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      content: Text(
                        detailT.cancelConfirm,
                        style: TextStyle(
                          color: AppColors.of(context).textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            detailT.cancelNo,
                            style: TextStyle(
                              color: AppColors.of(context).textSecondary,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFF85149),
                          ),
                          child: Text(detailT.cancelBuild),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
                  try {
                    if (!context.mounted) return;
                    context.showSnackBarMessage(detailT.cancelling);
                    await ref
                        .read(buildJobsProvider.notifier)
                        .cancelBuildJob(buildJob.id);
                    if (context.mounted) {
                      context.showSnackBarMessage(detailT.buildCancelled);
                    }
                  } on FirebaseFunctionsException catch (e, s) {
                    final errorMessage = await FunctionErrorMessage.capture(
                      e,
                      stackTrace: s,
                    );
                    if (context.mounted) {
                      context.showSnackBarMessage(errorMessage.message);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      context.showSnackBarMessage(
                        detailT.failedToCancel(error: e.toString()),
                      );
                    }
                  }
                },
                icon: Icon(
                  Icons.cancel_outlined,
                  size: 18,
                  color: const Color(0xFFD29922).withValues(alpha: 0.7),
                ),
                tooltip: t.common.cancel,
              ),
            IconButton(
              onPressed: retryState.value != _ActionState.idle
                  ? null
                  : () async {
                      retryState.value = _ActionState.loading;
                      try {
                        await ref
                            .read(buildJobsProvider.notifier)
                            .retryBuildJob(buildJob.id);
                        retryState.value = _ActionState.done;
                        Future.delayed(const Duration(milliseconds: 1500), () {
                          if (context.mounted) {
                            retryState.value = _ActionState.idle;
                          }
                        });
                        if (context.mounted) {
                          _showMaterialDefaultSnackBar(
                            context,
                            detailT.retrySuccess,
                          );
                        }
                      } on FirebaseFunctionsException catch (e, s) {
                        final errorMessage = await FunctionErrorMessage.capture(
                          e,
                          stackTrace: s,
                        );
                        if (context.mounted) {
                          retryState.value = _ActionState.idle;
                        }
                        if (context.mounted) {
                          _showMaterialDefaultSnackBar(
                            context,
                            errorMessage.message,
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          retryState.value = _ActionState.idle;
                        }
                        if (context.mounted) {
                          _showMaterialDefaultSnackBar(
                            context,
                            detailT.failedToRetry(error: e.toString()),
                          );
                        }
                      }
                    },
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: switch (retryState.value) {
                  _ActionState.loading => SizedBox(
                    key: const ValueKey('retry-loading'),
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppColors.of(context).textTertiary,
                    ),
                  ),
                  _ActionState.done => const Icon(
                    Icons.check_rounded,
                    key: ValueKey('retry-check'),
                    size: 18,
                    color: Color(0xFF3FB950),
                  ),
                  _ActionState.idle => Icon(
                    Icons.replay_rounded,
                    key: const ValueKey('retry-icon'),
                    size: 18,
                    color: AppColors.of(context).textSecondary,
                  ),
                },
              ),
              tooltip: '再実行',
            ),
            const SizedBox(width: 8),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: AppColors.of(context).divider,
            ),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status bar ────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.of(context).surface,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.of(context).divider,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Status pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (buildJob.status == BuildJobStatus.IN_PROGRESS)
                              SyncedSpinner(
                                size: 14,
                                strokeWidth: 1.5,
                                color: statusColor,
                              )
                            else
                              Icon(statusIcon, color: statusColor, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${buildJob.owner}/${buildJob.repo}',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: AppColors.of(context).textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (buildJob.branch != null)
                        _DetailGitChip(
                          icon: FontAwesomeIcons.codeBranch,
                          label: buildJob.branch!,
                          color: const Color(0xFFBC8CFF),
                        ),
                      if (buildJob.pullRequestNumber != null)
                        _DetailGitChip(
                          icon: FontAwesomeIcons.codePullRequest,
                          label: '#${buildJob.pullRequestNumber}',
                          color: const Color(0xFF3FB950),
                        ),
                      if (buildJob.tagName != null)
                        _DetailGitChip(
                          icon: FontAwesomeIcons.tag,
                          label: buildJob.tagName!,
                          color: const Color(0xFFD29922),
                        ),
                      if (buildJob.commitSha != null)
                        _DetailGitChip(
                          icon: FontAwesomeIcons.codeCommit,
                          label: buildJob.commitSha!.substring(0, 7),
                          color: AppColors.of(context).textTertiary,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // ── AI Failure Summary ─────────────────────────────────────────
            Consumer(
              builder: (context, ref, _) {
                final aiEnabled =
                    ref.watch(teamStateProvider).value?.aiEnabled ?? true;
                if (!aiEnabled) return const SizedBox.shrink();
                if (buildJob.status != BuildJobStatus.FAILURE ||
                    buildJob.failureSummaryStatus == null) {
                  return const SizedBox.shrink();
                }
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: _FailureSummaryCard(
                    status: buildJob.failureSummaryStatus!,
                    summary: buildJob.failureSummary,
                    model: buildJob.failureSummaryModel,
                    durationMs: buildJob.failureSummaryDurationMs,
                  ),
                );
              },
            ),
            // ── Log content ───────────────────────────────────────────────
            Expanded(
              child: buildJob.latestRunId != null
                  ? _DetailLogsView(
                      buildJobId: buildJob.id,
                      runId: buildJob.latestRunId!,
                      buildStatus: buildJob.status,
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.of(context).borderSubtle,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.hourglass_empty_rounded,
                              size: 28,
                              color: AppColors.of(context).border,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            detailT.noRuns,
                            style: TextStyle(
                              color: AppColors.of(context).textTertiary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailGitChip extends StatelessWidget {
  const _DetailGitChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final FaIconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          FaIcon(icon, size: 11, color: color.withValues(alpha: 0.7)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: AppColors.of(context).textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailLogsView extends HookConsumerWidget {
  const _DetailLogsView({
    required this.buildJobId,
    required this.runId,
    required this.buildStatus,
  });

  final String buildJobId;
  final String runId;
  final BuildJobStatus buildStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(buildLogsProvider(buildJobId, runId));
    final detailT = t.buildLogs.detail;
    final scrollController = useScrollController();
    final showScrollToBottom = useState(false);
    final copyDone = useState(false);
    final isNearBottom = useRef(true);
    final prevLogCount = useRef(0);

    useEffect(() {
      void listener() {
        if (!scrollController.hasClients) return;
        final maxScroll = scrollController.position.maxScrollExtent;
        final currentScroll = scrollController.position.pixels;
        final nearBottom = (maxScroll - currentScroll) <= 200;
        showScrollToBottom.value = !nearBottom;
        isNearBottom.value = nearBottom;
      }

      scrollController.addListener(listener);
      return () => scrollController.removeListener(listener);
    }, [scrollController]);

    return logsAsync.when(
      data: (logs) {
        if (logs.length != prevLogCount.value) {
          final wasNearBottom = isNearBottom.value;
          prevLogCount.value = logs.length;
          if (wasNearBottom && scrollController.hasClients) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (scrollController.hasClients) {
                scrollController.animateTo(
                  scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                );
              }
            });
          }
        }

        if (logs.isEmpty) {
          final isTerminal =
              buildStatus == BuildJobStatus.SUCCESS ||
              buildStatus == BuildJobStatus.FAILURE ||
              buildStatus == BuildJobStatus.CANCELLED ||
              buildStatus == BuildJobStatus.SKIPPED ||
              buildStatus == BuildJobStatus.TIMED_OUT;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isTerminal)
                  Icon(
                    Icons.subject_rounded,
                    size: 22,
                    color: AppColors.of(context).textTertiary,
                  )
                else
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppColors.of(context).textTertiary,
                    ),
                  ),
                const SizedBox(height: 14),
                Text(
                  isTerminal ? detailT.noLogsAvailable : detailT.waitingForLogs,
                  style: TextStyle(
                    color: AppColors.of(context).textTertiary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            Column(
              children: [
                // ── Toolbar ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.of(context).surface,
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.of(context).divider,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.terminal_rounded,
                        size: 14,
                        color: AppColors.of(context).textTertiary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        detailT.logEntries(count: logs.length.toString()),
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: AppColors.of(context).textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      _ToolbarButton(
                        icon: copyDone.value
                            ? Icons.check_rounded
                            : Icons.copy_all_rounded,
                        iconColor: copyDone.value
                            ? const Color(0xFF3FB950)
                            : AppColors.of(context).textTertiary,
                        tooltip: detailT.copyAll,
                        onPressed: copyDone.value
                            ? null
                            : () {
                                final allLogs = logs
                                    .map((l) => l.message)
                                    .join('\n');
                                Clipboard.setData(ClipboardData(text: allLogs));
                                copyDone.value = true;
                                Future.delayed(
                                  const Duration(milliseconds: 1500),
                                  () {
                                    if (context.mounted) {
                                      copyDone.value = false;
                                    }
                                  },
                                );
                                if (context.mounted) {
                                  context.showSnackBarMessage(
                                    detailT.logsCopied,
                                  );
                                }
                              },
                      ),
                    ],
                  ),
                ),
                // ── Log list ─────────────────────────────────────────
                Expanded(
                  child: Scrollbar(
                    controller: scrollController,
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 8,
                      ),
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        return _DetailLogLine(
                          log: log,
                          lineNumber: index + 1,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            // ── Scroll-to-bottom button ──────────────────────────────
            if (showScrollToBottom.value)
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  heroTag: 'build-log-scroll-to-bottom',
                  tooltip: 'ログの末尾へ移動',
                  backgroundColor: AppColors.of(context).accent,
                  foregroundColor: Colors.white,
                  onPressed: () {
                    scrollController.animateTo(
                      scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                  child: const Icon(Icons.keyboard_double_arrow_down_rounded),
                ),
              ),
          ],
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(
          color: AppColors.of(context).border,
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF85149).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 28,
                color: Color(0xFFF85149),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                t.common.error(error: error.toString()),
                style: TextStyle(
                  color: const Color(0xFFF85149).withValues(alpha: 0.8),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.iconColor,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final Color iconColor;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: IconButton(
        onPressed: onPressed,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            icon,
            key: ValueKey(icon),
            size: 15,
            color: iconColor,
          ),
        ),
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}

class _DetailLogLine extends HookWidget {
  const _DetailLogLine({required this.log, required this.lineNumber});
  final BuildLog log;
  final int lineNumber;

  @override
  Widget build(BuildContext context) {
    final isExpanded = useState(false);
    final lines = log.message.split('\n');
    final isMultiLine = lines.length > 1;

    final levelColor = switch (log.level) {
      'error' => const Color(0xFFF85149),
      'warning' => const Color(0xFFD29922),
      'success' => const Color(0xFF3FB950),
      _ => AppColors.of(context).textSecondary,
    };

    final levelIcon = switch (log.level) {
      'error' => Icons.error_outline_rounded,
      'warning' => Icons.warning_amber_rounded,
      'success' => Icons.check_circle_outline_rounded,
      _ => Icons.circle,
    };

    // ── Single-line log ────────────────────────────────────────────────────
    if (!isMultiLine) {
      return _logLineHoverWrapper(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _lineNumberWidget(context),
              const SizedBox(width: 12),
              _levelIconWidget(levelIcon, levelColor),
              const SizedBox(width: 8),
              Expanded(
                child: SelectableText(
                  log.message,
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
                    color: levelColor,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Multi-line log (collapsible) ───────────────────────────────────────
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.of(context).borderSubtle,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.of(context).textPrimary.withValues(
              alpha: isExpanded.value ? 0.1 : 0.06,
            ),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => isExpanded.value = !isExpanded.value,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _lineNumberWidget(context),
                      const SizedBox(width: 12),
                      _levelIconWidget(levelIcon, levelColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          lines.first,
                          style: TextStyle(
                            fontSize: 13,
                            fontFamily: 'monospace',
                            color: levelColor,
                            height: 1.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.of(context).divider,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.of(context).border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isExpanded.value
                                  ? Icons.unfold_less_rounded
                                  : Icons.unfold_more_rounded,
                              size: 13,
                              color: AppColors.of(context).textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              t.buildLogs.detail.lines(
                                count: lines.length.toString(),
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: AppColors.of(context).textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: isExpanded.value
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.of(context).scaffold,
                  border: Border(
                    top: BorderSide(
                      color: AppColors.of(context).divider,
                    ),
                  ),
                ),
                padding: const EdgeInsets.all(14),
                child: SelectableText(
                  log.message,
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
                    color: levelColor.withValues(alpha: 0.9),
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logLineHoverWrapper({required Widget child}) {
    return _HoverHighlight(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: child,
      ),
    );
  }

  Widget _lineNumberWidget(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Text(
        '$lineNumber',
        style: TextStyle(
          fontSize: 12,
          fontFamily: 'monospace',
          color: AppColors.of(context).border,
          height: 1.5,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _levelIconWidget(IconData icon, Color color) {
    return SizedBox(
      width: 16,
      height: 20,
      child: Center(
        child: Icon(
          icon,
          size: log.level == 'info' ? 5 : 13,
          color: color.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

// ── Hover highlight for log lines ───────────────────────────────────────────

class _HoverHighlight extends StatefulWidget {
  const _HoverHighlight({required this.child});
  final Widget child;

  @override
  State<_HoverHighlight> createState() => _HoverHighlightState();
}

class _HoverHighlightState extends State<_HoverHighlight> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          color: _hovering
              ? AppColors.of(context).borderSubtle
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: widget.child,
      ),
    );
  }
}

// ── AI Failure Summary Card ─────────────────────────────────────────────────

class _FailureSummaryCard extends HookWidget {
  const _FailureSummaryCard({
    required this.status,
    this.summary,
    this.model,
    this.durationMs,
  });

  final String status;
  final String? summary;
  final String? model;
  final int? durationMs;

  @override
  Widget build(BuildContext context) {
    final isExpanded = useState(true);

    // Loading state: generating
    if (status == 'generating') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.of(context).surface,
          border: Border(
            bottom: BorderSide(
              color: AppColors.of(context).divider,
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: const Color(0xFFD29922).withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.auto_awesome_rounded,
              size: 14,
              color: const Color(0xFFD29922).withValues(alpha: 0.6),
            ),
            const SizedBox(width: 6),
            Text(
              t.buildLogs.detail.generatingSummary,
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFFD29922).withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // No summary available (error or no_logs)
    if (status != 'done' || summary == null) {
      return const SizedBox.shrink();
    }

    const accentColor = Color(0xFFF85149);

    String durationLabel = '';
    if (durationMs != null) {
      durationLabel = durationMs! < 1000
          ? '${durationMs}ms'
          : '${(durationMs! / 1000).toStringAsFixed(1)}s';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.of(context).divider,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => isExpanded.value = !isExpanded.value,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 14,
                      color: accentColor.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t.buildLogs.detail.failureSummaryTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.of(context).textPrimary,
                      ),
                    ),
                    if (model != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.of(context).borderSubtle,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.of(context).border,
                          ),
                        ),
                        child: Text(
                          model!,
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                            color: AppColors.of(context).textTertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    if (durationLabel.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        durationLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          color: AppColors.of(context).textTertiary,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Icon(
                      isExpanded.value
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 18,
                      color: AppColors.of(context).textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ── Body (collapsible) ──
          Flexible(
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: isExpanded.value
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left accent bar
                      Container(
                        width: 3,
                        constraints: const BoxConstraints(minHeight: 60),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              accentColor.withValues(alpha: 0.7),
                              accentColor.withValues(alpha: 0.2),
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                      ),
                      // Summary content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: MarkdownBody(
                            data: summary!,
                            selectable: true,
                            styleSheet: MarkdownStyleSheet(
                              p: TextStyle(
                                fontSize: 13,
                                color: AppColors.of(context).textSecondary,
                                height: 1.6,
                              ),
                              strong: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.of(context).textPrimary,
                              ),
                              code: TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                color: const Color(0xFF58A6FF),
                                backgroundColor: AppColors.of(context).divider,
                              ),
                              codeblockDecoration: BoxDecoration(
                                color: AppColors.of(context).scaffold,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.of(context).border,
                                ),
                              ),
                              blockquote: TextStyle(
                                color: AppColors.of(context).textTertiary,
                                fontStyle: FontStyle.italic,
                              ),
                              blockquoteDecoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: AppColors.of(context).border,
                                    width: 3,
                                  ),
                                ),
                              ),
                              listBullet: TextStyle(
                                color: AppColors.of(context).textTertiary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
