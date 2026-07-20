import 'package:dashboard/build_logs/build_jobs_provider.dart';
import 'package:dashboard/cicd_log/cicd_logs_page.dart';
import 'package:dashboard/cicd_log/detail/build_step_mock_data.dart';
import 'package:dashboard/cicd_log/detail/build_step_providers.dart';
import 'package:dashboard/cicd_log/detail/job_status_icon.dart';
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
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (err, _) => Scaffold(body: Center(child: Text('エラー: $err'))),
      data: (buildJob) {
        if (buildJob == null) {
          return const Scaffold(
            body: Center(
              child: Text('ビルドジョブが見つかりません'),
            ),
          );
        }

        return CicdLogDetailPage(buildJobId: buildJobId);
      },
    );
  }
}

class CicdLogDetailPage extends ConsumerWidget {
  const CicdLogDetailPage({
    super.key,
    required this.buildJobId,
  });

  final String buildJobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stepsAsync = ref.watch(buildStepSummariesProvider(buildJobId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('CI/CD詳細ログ'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
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
                  return _StepAccordion(step: steps[index]);
                },
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator.adaptive(),
        ),
        error: (err, _) => Center(
          child: Text(
            'ログの取得中にエラーが発生しました: $err',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}

class _StepAccordion extends HookConsumerWidget {
  const _StepAccordion({
    required this.step,
  });

  final BuildStepSummary step;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = useState(false);
    final theme = Theme.of(context);

    final durationText = step.duration == Duration.zero
        ? ''
        : '${step.duration.inSeconds}s';

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
            if (isExpanded.value) _StepLogsContent(stepId: step.id),
          ],
        ),
      ),
    );
  }
}

class _StepLogsContent extends ConsumerWidget {
  const _StepLogsContent({
    required this.stepId,
  });

  final String stepId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(buildStepLogDetailProvider(stepId));

    return detailAsync.when(
      data: (logs) {
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
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ),
      ),
      error: (err, stack) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child: Text(
          'Failed to load logs: $err',
          style: const TextStyle(color: Colors.red, fontSize: 13),
        ),
      ),
    );
  }
}
