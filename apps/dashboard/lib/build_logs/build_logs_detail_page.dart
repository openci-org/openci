import 'package:dashboard/build_logs/build_jobs_provider.dart';
import 'package:dashboard/build_logs/build_logs_provider.dart';
import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum _ActionState { idle, loading, done }

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

    final canCancel =
        buildJob.status == 'queued' || buildJob.status == 'in_progress';

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: workflowNameAsync.when(
          data: (name) => Text(
            name ?? '${buildJob.owner}/${buildJob.repo}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          loading: () => const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator.adaptive(strokeWidth: 2),
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
                color: Colors.orange[300],
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
                _ActionState.loading => SizedBox(
                  key: const ValueKey('retry-loading'),
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                _ActionState.done => Icon(
                  Icons.check,
                  key: const ValueKey('retry-check'),
                  size: 20,
                  color: Colors.green[300],
                ),
                _ActionState.idle => Icon(
                  Icons.replay,
                  key: const ValueKey('retry-icon'),
                  size: 20,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              },
            ),
            tooltip: 'Retry',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (buildJob.status == 'in_progress')
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: statusColor,
                              ),
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
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (buildJob.branch != null)
                      _DetailGitChip(
                        icon: FontAwesomeIcons.codeBranch,
                        label: buildJob.branch!,
                        color: Colors.purple[300]!,
                      ),
                    if (buildJob.pullRequestNumber != null)
                      _DetailGitChip(
                        icon: FontAwesomeIcons.codePullRequest,
                        label: '#${buildJob.pullRequestNumber}',
                        color: Colors.green[300]!,
                      ),
                    if (buildJob.tagName != null)
                      _DetailGitChip(
                        icon: FontAwesomeIcons.tag,
                        label: buildJob.tagName!,
                        color: Colors.amber[300]!,
                      ),
                    if (buildJob.commitSha != null)
                      _DetailGitChip(
                        icon: FontAwesomeIcons.codeCommit,
                        label: buildJob.commitSha!.substring(0, 7),
                        color: Colors.blueGrey[300]!,
                      ),
                  ],
                ),
              ],
            ),
          ),
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
                        Icon(
                          Icons.hourglass_empty,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          detailT.noRuns,
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text(
                  detailT.waitingForLogs,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.terminal,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        detailT.logEntries(count: logs.length.toString()),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.4),
                          fontFamily: 'monospace',
                        ),
                      ),
                      const Spacer(),
                      IconButton(
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
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: copyDone.value
                              ? Icon(
                                  Icons.check,
                                  key: const ValueKey('copy-check'),
                                  size: 18,
                                  color: Colors.green[300],
                                )
                              : Icon(
                                  Icons.copy_all,
                                  key: const ValueKey('copy-icon'),
                                  size: 18,
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                        ),
                        tooltip: detailT.copyAll,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Scrollbar(
                    controller: scrollController,
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        return _DetailLogLine(log: log, lineNumber: index + 1);
                      },
                    ),
                  ),
                ),
              ],
            ),
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
                  backgroundColor: const Color(0xFF2A2A2A),
                  foregroundColor: Colors.white.withValues(alpha: 0.8),
                  elevation: 4,
                  child: const Icon(Icons.keyboard_double_arrow_down),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              t.common.error(error: error.toString()),
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
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
      'error' => Colors.red[300],
      'warning' => Colors.orange[300],
      'success' => Colors.green[300],
      _ => Colors.grey[300],
    };

    final levelIcon = switch (log.level) {
      'error' => Icons.error_outline,
      'warning' => Icons.warning_amber,
      'success' => Icons.check_circle_outline,
      _ => Icons.circle,
    };

    if (!isMultiLine) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
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
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Container(
        decoration: BoxDecoration(
          color: levelColor!.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: levelColor.withValues(alpha: isExpanded.value ? 0.2 : 0.1),
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
                    horizontal: 8,
                    vertical: 8,
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
                            height: 1.4,
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
                          color: levelColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isExpanded.value
                                  ? Icons.unfold_less
                                  : Icons.unfold_more,
                              size: 14,
                              color: levelColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              t.buildLogs.detail.lines(
                                count: lines.length.toString(),
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                color: levelColor,
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
            if (isExpanded.value) ...[
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  border: Border(
                    top: BorderSide(
                      color: levelColor.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                padding: const EdgeInsets.all(12),
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
          ],
        ),
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
          color: Colors.white.withValues(alpha: 0.2),
          height: 1.4,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _levelIconWidget(IconData icon, Color? color) {
    return SizedBox(
      width: 16,
      height: 16,
      child: Center(
        child: Icon(
          icon,
          size: log.level == 'info' ? 6 : 14,
          color: color,
        ),
      ),
    );
  }
}
