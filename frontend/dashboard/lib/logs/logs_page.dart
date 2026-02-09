import 'package:dashboard/extensions/date_time_extensions.dart';
import 'package:dashboard/logs/logs_provider.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LogsPage extends HookConsumerWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(buildJobsListProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Build Logs - ${DateTime.now().toFormattedDate()}',
        ),
      ),
      body: state.when(
        data: (buildJobs) {
          if (buildJobs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No build jobs found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Scrollbar(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: buildJobs.length,
              itemBuilder: (_, index) {
                final job = buildJobs[index];
                return BuildJobCard(buildJob: job);
              },
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

class BuildJobCard extends StatelessWidget {
  const BuildJobCard({super.key, required this.buildJob});
  final BuildJob buildJob;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (buildJob.status) {
      'success' => Colors.green,
      'failure' => Colors.red,
      'in_progress' => Colors.orange,
      'queued' => Colors.blue,
      _ => Colors.grey,
    };

    final statusIcon = switch (buildJob.status) {
      'success' => Icons.check_circle,
      'failure' => Icons.cancel,
      'in_progress' => Icons.pending,
      'queued' => Icons.schedule,
      _ => Icons.help_outline,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(statusIcon, color: statusColor, size: 28),
        title: Text(
          '${buildJob.owner}/${buildJob.repo}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            if (buildJob.pullRequestNumber != null)
              Text('PR #${buildJob.pullRequestNumber}'),
            if (buildJob.commitSha != null)
              Text(
                buildJob.commitSha!.substring(0, 7),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            Text(
              buildJob.createdAt.toFormattedDate(),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        trailing: buildJob.runCount != null && buildJob.runCount! > 0
            ? Chip(
                label: Text(
                  'Run ${buildJob.runCount}',
                  style: const TextStyle(fontSize: 12),
                ),
                visualDensity: VisualDensity.compact,
              )
            : null,
        children: [
          if (buildJob.latestRunId != null)
            LogsListView(
              buildJobId: buildJob.id,
              runId: buildJob.latestRunId!,
            )
          else
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No runs yet'),
            ),
        ],
      ),
    );
  }
}

class LogsListView extends ConsumerWidget {
  const LogsListView({
    super.key,
    required this.buildJobId,
    required this.runId,
  });

  final String buildJobId;
  final String runId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(buildLogsProvider(buildJobId, runId));

    return logsAsync.when(
      data: (logs) {
        if (logs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Waiting for logs...'),
              ],
            ),
          );
        }

        return Container(
          color: const Color(0xFF1E1E1E),
          constraints: const BoxConstraints(maxHeight: 400),
          child: Scrollbar(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return LogLine(log: log);
              },
            ),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error: $error'),
      ),
    );
  }
}

class LogLine extends HookWidget {
  const LogLine({super.key, required this.log});
  final BuildLog log;

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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: isMultiLine ? () => isExpanded.value = !isExpanded.value : null,
        borderRadius: BorderRadius.circular(4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: Center(
                child: Icon(
                  levelIcon,
                  size: log.level == 'info' ? 6 : 16,
                  color: levelColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (isMultiLine)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  isExpanded.value
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  size: 16,
                  color: Colors.grey[500],
                ),
              ),
            Expanded(
              child: SelectableText(
                isMultiLine && !isExpanded.value ? lines.first : log.message,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: levelColor,
                  height: 1.4,
                ),
              ),
            ),
            if (isMultiLine && !isExpanded.value)
              Text(
                ' +${lines.length - 1} lines',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
