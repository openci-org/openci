import 'package:dashboard/build_logs/build_jobs_provider.dart';
import 'package:dashboard/build_logs/build_logs_detail_page.dart';
import 'package:dashboard/extensions/date_time_extensions.dart';
import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/users/user_provider.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:dashboard/workflow/list/select_repository_bottom_sheet.dart';
import 'package:flutter/material.dart';
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
          t.buildLogs.title(date: DateTime.now().toFormattedDate()),
        ),
      ),
      body: Column(
        children: [
          Consumer(
            builder: (context, ref, _) {
              final userAsync = ref.watch(userProvider);
              return userAsync.when(
                data: (user) {
                  final selectedRepo = user.selectedRepository;
                  if (selectedRepo == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ActionChip(
                        avatar: const Icon(FontAwesomeIcons.github, size: 16),
                        label: Text(
                          selectedRepo.split('/').last,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          showDragHandle: true,
                          builder: (_) => const SelectRepositoryBottomSheet(),
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              );
            },
          ),
          // ── Content ──
          Expanded(
            child: state.when(
              data: (buildJobs) {
                if (buildJobs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          t.buildLogs.noJobs,
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      itemCount: buildJobs.length,
                      itemBuilder: (_, index) {
                        final job = buildJobs[index];
                        return BuildJobCard(buildJob: job);
                      },
                    ),
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator.adaptive()),
              error: asyncErrorWidget,
            ),
          ),
        ],
      ),
    );
  }
}

class BuildJobCard extends HookConsumerWidget {
  const BuildJobCard({super.key, required this.buildJob});
  final BuildJob buildJob;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workflowNameAsync = ref.watch(
      workflowNameProvider(buildJob),
    );

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

    final isRunning =
        buildJob.status == 'in_progress' || buildJob.status == 'queued';

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BuildLogsDetailPage(buildJob: buildJob),
            ),
          );
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
                              child: CircularProgressIndicator.adaptive(
                                strokeWidth: 2,
                              ),
                            ),
                            error: asyncErrorWidget,
                          ),
                        ),
                        Text(
                          buildJob.createdAt.toTimeAgoEn(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _InfoBadge(
                          icon: buildJob.status == 'in_progress'
                              ? SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: statusColor,
                                  ),
                                )
                              : Icon(
                                  statusIcon,
                                  color: statusColor,
                                  size: 11,
                                ),
                          label: statusLabel,
                          color: statusColor,
                        ),
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
                        if (buildJob.completedAt != null)
                          _InfoBadge(
                            icon: const Icon(Icons.timer_outlined, size: 11),
                            label: _formatDuration(
                              buildJob.completedAt!.difference(
                                buildJob.createdAt,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              BuildLogsDetailPage(buildJob: buildJob),
                        ),
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

String _formatDuration(Duration duration) {
  final totalMinutes = duration.inMinutes;
  if (totalMinutes < 1) return '<1m';
  if (totalMinutes < 60) return '${totalMinutes}m';
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.icon,
    required this.label,
    this.color,
  });

  final Widget icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final textColor = color ?? theme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: theme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: textColor,
              fontWeight: color != null ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
