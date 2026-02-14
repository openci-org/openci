import 'package:dashboard/build_logs/build_jobs_provider.dart';
import 'package:dashboard/build_logs/build_logs_provider.dart';
import 'package:dashboard/extensions/date_time_extensions.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LogsPage extends HookConsumerWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(buildJobsProvider);
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

class BuildJobCard extends ConsumerStatefulWidget {
  const BuildJobCard({super.key, required this.buildJob});
  final BuildJob buildJob;

  @override
  ConsumerState<BuildJobCard> createState() => _BuildJobCardState();
}

class _BuildJobCardState extends ConsumerState<BuildJobCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final buildJob = widget.buildJob;
    final workflowNameAsync =
        ref.watch(workflowNameProvider(buildJob.workflowId));

    final statusColor = switch (buildJob.status) {
      'success' => Colors.green,
      'failure' => Colors.red,
      'in_progress' => Theme.of(context).colorScheme.primary,
      'queued' => Colors.blue,
      _ => Colors.grey,
    };

    final statusIcon = switch (buildJob.status) {
      'success' => Icons.check_circle,
      'failure' => Icons.cancel,
      'queued' => Icons.schedule,
      _ => Icons.help_outline,
    };

    return Card(
      elevation: 0,
      color: statusColor.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withValues(alpha: 0.2),
        ),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: buildJob.status == 'in_progress'
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 1.0),
              )
            : Icon(statusIcon, color: statusColor, size: 28),
        title: Row(
          children: [
            Expanded(
              child: workflowNameAsync.when(
                data: (name) => Text(
                  name ?? '${buildJob.owner}/${buildJob.repo}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                loading: () => const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                ),
                error: asyncErrorWidget,
              ),
            ),
            Text(
              buildJob.createdAt.toTimeAgoEn(),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Git metadata chips
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (buildJob.branch != null)
                    _GitChip(
                      icon: FontAwesomeIcons.codeBranch,
                      label: buildJob.branch!,
                      color: Colors.purple,
                    ),
                  if (buildJob.pullRequestNumber != null)
                    _GitChip(
                      icon: FontAwesomeIcons.codePullRequest,
                      label: '#${buildJob.pullRequestNumber}',
                      color: Colors.green,
                    ),
                  if (buildJob.tagName != null)
                    _GitChip(
                      icon: FontAwesomeIcons.tag,
                      label: buildJob.tagName!,
                      color: Colors.amber,
                    ),
                  if (buildJob.commitSha != null)
                    _GitChip(
                      icon: FontAwesomeIcons.codeCommit,
                      label: buildJob.commitSha!.substring(0, 7),
                      color: Colors.blueGrey,
                    ),
                ],
              ),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'retry') {
              try {
                context.showSnackBarMessage('Retrying build job...');
                await ref
                    .read(buildJobsProvider.notifier)
                    .retryBuildJob(buildJob.id);
                if (context.mounted) {
                  context.showSnackBarMessage('Build job queued successfully');
                }
              } catch (e) {
                if (context.mounted) {
                  context.showSnackBarMessage('Failed to retry: $e');
                }
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'retry',
              child: Row(
                children: [
                  Icon(Icons.replay, size: 18),
                  SizedBox(width: 8),
                  Text('Retry'),
                ],
              ),
            ),
          ],
        ),
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

class _GitChip extends StatelessWidget {
  const _GitChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            icon,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
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
