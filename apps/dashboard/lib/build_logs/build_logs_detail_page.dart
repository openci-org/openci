import 'package:dashboard/build_logs/build_jobs_provider.dart';
import 'package:dashboard/build_logs/synced_spinner.dart';
import 'package:dashboard/build_logs/build_logs_provider.dart';
import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum _ActionState { idle, loading, done }

// ── Terminal colour palette ─────────────────────────────────────────────────
// GitHub-inspired dark terminal colours
const _kBg = Color(0xFF0D1117);
const _kSurface = Color(0xFF161B22);
const _kBorder = Color(0xFF30363D);
const _kMuted = Color(0xFF8B949E);
const _kText = Color(0xFFE6EDF3);

class BuildLogsDetailPage extends HookConsumerWidget {
  const BuildLogsDetailPage({super.key, required this.buildJob});
  final BuildJob buildJob;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workflowNameAsync = ref.watch(
      workflowNameProvider(buildJob),
    );
    final detailT = t.buildLogs.detail;
    final retryState = useState(_ActionState.idle);

    final statusColor = switch (buildJob.status) {
      'success' => const Color(0xFF3FB950),
      'failure' => const Color(0xFFF85149),
      'in_progress' => const Color(0xFF58A6FF),
      'queued' => const Color(0xFFBC8CFF),
      'cancelled' => const Color(0xFFD29922),
      'waiting' => const Color(0xFFD29922),
      'skipped' => _kMuted,
      _ => _kMuted,
    };

    final statusIcon = switch (buildJob.status) {
      'success' => Icons.check_circle_rounded,
      'failure' => Icons.cancel_rounded,
      'queued' => Icons.schedule_rounded,
      'cancelled' => Icons.block_rounded,
      'waiting' => Icons.pending_outlined,
      'skipped' => Icons.skip_next_rounded,
      _ => Icons.help_outline_rounded,
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

    final canCancel =
        buildJob.status == 'queued' || buildJob.status == 'in_progress';

    return SyncedSpinnerScope(
      child: Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: _kText,
          onPressed: () => Navigator.pop(context),
        ),
        title: workflowNameAsync.when(
          data: (name) => Text(
            name ?? '${buildJob.owner}/${buildJob.repo}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: _kText,
              letterSpacing: -0.3,
            ),
          ),
          loading: () => const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _kMuted,
            ),
          ),
          error: asyncErrorWidget,
        ),
        actions: [
          if (canCancel)
            IconButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(detailT.cancelBuild),
                    content: Text(detailT.cancelConfirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(detailT.cancelNo),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
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
                size: 20,
                color: const Color(0xFFD29922),
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
                        context.showSnackBarMessage(detailT.retrySuccess);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        retryState.value = _ActionState.idle;
                      }
                      if (context.mounted) {
                        context.showSnackBarMessage(
                          detailT.failedToRetry(error: e.toString()),
                        );
                      }
                    }
                  },
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: switch (retryState.value) {
                _ActionState.loading => const SizedBox(
                  key: ValueKey('retry-loading'),
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _kText,
                  ),
                ),
                _ActionState.done => const Icon(
                  Icons.check_rounded,
                  key: ValueKey('retry-check'),
                  size: 20,
                  color: Color(0xFF3FB950),
                ),
                _ActionState.idle => const Icon(
                  Icons.replay_rounded,
                  key: ValueKey('retry-icon'),
                  size: 20,
                  color: _kText,
                ),
              },
            ),
            tooltip: 'Retry',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status bar ────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: _kSurface,
              border: Border(bottom: BorderSide(color: _kBorder)),
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
                          if (buildJob.status == 'in_progress')
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
                      style: const TextStyle(
                        fontSize: 12,
                        color: _kMuted,
                        fontFamily: 'monospace',
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
                        color: const Color(0xFF8B949E),
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
              if (buildJob.status != 'failure' ||
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
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: _kBorder.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.hourglass_empty_rounded,
                            size: 32,
                            color: _kMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          detailT.noRuns,
                          style: const TextStyle(
                            color: _kMuted,
                            fontSize: 16,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 11, color: color.withValues(alpha: 0.9)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: color.withValues(alpha: 0.9),
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
  });

  final String buildJobId;
  final String runId;

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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _kMuted.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  detailT.waitingForLogs,
                  style: const TextStyle(
                    color: _kMuted,
                    fontSize: 14,
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
                  decoration: const BoxDecoration(
                    color: _kSurface,
                    border: Border(
                      bottom: BorderSide(color: _kBorder),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.terminal_rounded,
                        size: 16,
                        color: _kMuted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        detailT.logEntries(count: logs.length.toString()),
                        style: const TextStyle(
                          fontSize: 12,
                          color: _kMuted,
                          fontFamily: 'monospace',
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
                            : _kMuted,
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
            // ── Scroll-to-bottom FAB ─────────────────────────────────
            if (showScrollToBottom.value)
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton.small(
                  onPressed: () {
                    scrollController.animateTo(
                      scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                  backgroundColor: _kSurface,
                  foregroundColor: _kText,
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: _kBorder),
                  ),
                  child: const Icon(
                    Icons.keyboard_double_arrow_down_rounded,
                    size: 20,
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: _kMuted),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFF85149).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: Color(0xFFF85149),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                t.common.error(error: error.toString()),
                style: const TextStyle(
                  color: Color(0xFFF85149),
                  fontSize: 14,
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
      width: 32,
      height: 32,
      child: IconButton(
        onPressed: onPressed,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            icon,
            key: ValueKey(icon),
            size: 16,
            color: iconColor,
          ),
        ),
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
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
      _ => _kText.withValues(alpha: 0.8),
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
              _lineNumberWidget(),
              const SizedBox(width: 12),
              _levelIconWidget(levelIcon, levelColor),
              const SizedBox(width: 8),
              Expanded(
                child: SelectableText(
                  log.message,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
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
          color: levelColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: levelColor.withValues(
              alpha: isExpanded.value ? 0.2 : 0.08,
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
                      _lineNumberWidget(),
                      const SizedBox(width: 12),
                      _levelIconWidget(levelIcon, levelColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          lines.first,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
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
                          color: levelColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isExpanded.value
                                  ? Icons.unfold_less_rounded
                                  : Icons.unfold_more_rounded,
                              size: 14,
                              color: levelColor.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              t.buildLogs.detail.lines(
                                count: lines.length.toString(),
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                color: levelColor.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600,
                                fontFamily: 'monospace',
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
                  color: _kBg,
                  border: Border(
                    top: BorderSide(
                      color: levelColor.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                padding: const EdgeInsets.all(14),
                child: SelectableText(
                  log.message,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
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

  Widget _lineNumberWidget() {
    return SizedBox(
      width: 40,
      child: Text(
        '$lineNumber',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: _kMuted.withValues(alpha: 0.4),
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
          size: log.level == 'info' ? 6 : 14,
          color: color.withValues(alpha: 0.7),
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
              ? _kText.withValues(alpha: 0.03)
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
        decoration: const BoxDecoration(
          color: _kSurface,
          border: Border(bottom: BorderSide(color: _kBorder)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: const Color(0xFFD29922).withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.auto_awesome_rounded,
              size: 14,
              color: const Color(0xFFD29922).withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            Text(
              t.buildLogs.detail.generatingSummary,
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFFD29922).withValues(alpha: 0.8),
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
      decoration: const BoxDecoration(
        color: _kSurface,
        border: Border(bottom: BorderSide(color: _kBorder)),
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
                      size: 16,
                      color: accentColor.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t.buildLogs.detail.failureSummaryTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kText.withValues(alpha: 0.9),
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
                          color: _kBorder.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          model!,
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                            color: _kMuted.withValues(alpha: 0.7),
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
                          color: _kMuted.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Icon(
                      isExpanded.value
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 20,
                      color: _kMuted,
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
                    color: accentColor.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.12),
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
                              accentColor.withValues(alpha: 0.8),
                              accentColor.withValues(alpha: 0.3),
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            bottomLeft: Radius.circular(10),
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
                                color: _kText.withValues(alpha: 0.85),
                                height: 1.6,
                              ),
                              strong: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _kText.withValues(alpha: 0.95),
                              ),
                              code: TextStyle(
                                fontFamily: 'monospace',
                                backgroundColor: _kBorder.withValues(
                                  alpha: 0.5,
                                ),
                                color: const Color(0xFF58A6FF),
                                fontSize: 12,
                              ),
                              codeblockDecoration: BoxDecoration(
                                color: _kSurface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: _kBorder),
                              ),
                              blockquote: TextStyle(
                                color: _kMuted,
                                fontStyle: FontStyle.italic,
                              ),
                              blockquoteDecoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(color: _kBorder, width: 4),
                                ),
                              ),
                              listBullet: TextStyle(
                                color: _kMuted,
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
