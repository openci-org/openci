import 'package:dashboard/build_logs/build_jobs_provider.dart';
import 'package:dashboard/cicd_log/detail/build_step_providers.dart';
import 'package:dashboard/cicd_log/detail/job_status_icon.dart';
import 'package:dashboard/extensions/circular_progress_indicator_extensions.dart';
import 'package:dashboard/responsive/desktop_max_width.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CicdLogDetailRoutePage extends ConsumerWidget {
  const CicdLogDetailRoutePage({
    super.key,
    required this.buildJobId,
  });

  final String buildJobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buildJobAsync = ref.watch(buildJobByIdProvider(buildJobId));
    return buildJobAsync.when(
      loading: () => CircularProgressIndicator.adaptive().withScaffoldCenter(),
      error: (err, _) => Scaffold(body: Center(child: Text('エラー: $err'))),
      data: (buildJob) {
        if (buildJob == null) {
          return const Scaffold(
            body: Center(
              child: Text('ビルドジョブが見つかりません'),
            ),
          );
        }

        return CicdLogDetailPage(
          buildJobId: buildJobId,
          runId: buildJob.latestRunId ?? '',
        );
      },
    );
  }
}

class CicdLogDetailPage extends ConsumerWidget {
  const CicdLogDetailPage({
    super.key,
    required this.buildJobId,
    required this.runId,
  });

  final String buildJobId;
  final String runId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(
      realtimeRunLogsStreamProvider(
        buildJobId: buildJobId,
        runId: runId,
      ),
      (previous, next) {
        next.whenData((event) {
          final isStepEvent = event['isStepEvent'] as bool? ?? false;
          final stepId = event['stepId'] as String?;

          if (isStepEvent) {
            ref.invalidate(
              buildStepSummariesProvider(
                buildJobId: buildJobId,
                runId: runId,
              ),
            );
          }
          if (stepId != null && stepId.isNotEmpty) {
            ref.invalidate(
              buildStepLogDetailProvider(
                buildJobId: buildJobId,
                runId: runId,
                stepId: stepId,
              ),
            );
          }
        });
      },
    );

    final stepsAsync = ref.watch(
      buildStepSummariesProvider(
        buildJobId: buildJobId,
        runId: runId,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('CI/CD詳細ログ'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all_rounded),
            tooltip: '全体のログをコピー',
            onPressed: () async {
              try {
                final allLogs = await ref.read(
                  allBuildStepLogsProvider(
                    buildJobId: buildJobId,
                    runId: runId,
                  ).future,
                );
                if (allLogs.isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('コピーするログがありません'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                  return;
                }
                await Clipboard.setData(ClipboardData(text: allLogs));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('全体のログをクリップボードにコピーしました'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ログのコピーに失敗しました: $e'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: stepsAsync.when(
        data: (steps) {
          if (steps.isEmpty) {
            return const Center(child: Text('ログステップがありません'));
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: desktopMaxWidth),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  return _StepAccordion(
                    step: steps[index],
                    buildJobId: buildJobId,
                  );
                },
              ),
            ),
          );
        },
        loading: () => CircularProgressIndicator.adaptive().withCenter(),
        error: asyncErrorWidget,
      ),
    );
  }
}

class _StepAccordion extends HookConsumerWidget {
  const _StepAccordion({
    required this.step,
    required this.buildJobId,
  });

  final BuildStep step;
  final String buildJobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = useState(false);
    final theme = Theme.of(context);

    final durationText = step.durationMs == 0
        ? ''
        : '${(step.durationMs / 1000).round()}s';

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: jobStatusIcon(step, theme),
          title: Text(
            step.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (durationText.isNotEmpty)
                Text(
                  durationText,
                  style: TextStyle(
                    color: theme.colorScheme.outline,
                    fontSize: 12,
                  ),
                ),
              const SizedBox(width: 8),
              Icon(
                isExpanded.value
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
          onExpansionChanged: (expanded) {
            isExpanded.value = expanded;
          },
          children: [
            if (isExpanded.value)
              _StepLogsContent(
                buildJobId: buildJobId,
                runId: step.runId,
                stepId: step.id,
              ),
          ],
        ),
      ),
    );
  }
}

class _StepLogsContent extends HookConsumerWidget {
  const _StepLogsContent({
    required this.buildJobId,
    required this.runId,
    required this.stepId,
  });

  final String buildJobId;
  final String runId;
  final String stepId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveLogs = useState<List<String>>([]);
    final isInitialized = useState<bool>(false);

    final detailAsync = ref.watch(
      buildStepLogDetailProvider(
        buildJobId: buildJobId,
        runId: runId,
        stepId: stepId,
      ),
    );

    detailAsync.whenData((initialLogs) {
      if (!isInitialized.value) {
        liveLogs.value = List.from(initialLogs);
        isInitialized.value = true;
      }
    });

    ref.listen(
      realtimeRunLogsStreamProvider(
        buildJobId: buildJobId,
        runId: runId,
      ),
      (previous, next) {
        next.whenData((event) {
          final isStepEvent = event['isStepEvent'] as bool? ?? false;
          final eventStepId = event['stepId'] as String?;
          final message = event['message'] as String?;

          if (!isStepEvent &&
              eventStepId == stepId &&
              message != null &&
              message.isNotEmpty) {
            if (!liveLogs.value.contains(message)) {
              liveLogs.value = [...liveLogs.value, message];
            }
          }
        });
      },
    );

    final logs = isInitialized.value
        ? liveLogs.value
        : (detailAsync.value ?? []);

    if (detailAsync.isLoading && !isInitialized.value) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    if (logs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Text(
          'No logs available.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      );
    }

    return Stack(
      children: [
        Container(
          color: Colors.black,
          padding: const EdgeInsets.only(
            top: 40,
            bottom: 8,
            left: 16,
            right: 16,
          ),
          width: double.infinity,
          child: SelectionArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: logs.map((log) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    log,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton(
            icon: const Icon(
              Icons.copy_rounded,
              color: Colors.white60,
              size: 18,
            ),
            tooltip: 'ログをコピー',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: logs.join('\n')));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ログをクリップボードにコピーしました'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
