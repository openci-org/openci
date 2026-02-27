import 'package:dashboard/build_logs/build_jobs_provider.dart';
import 'package:dashboard/build_logs/build_logs_detail_page.dart';
import 'package:dashboard/extensions/date_time_extensions.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LogsPage extends HookConsumerWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(buildJobsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.12),
                    colorScheme.surfaceContainerHighest,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  Icons.terminal_rounded,
                  size: 16,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Build Logs',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                DateTime.now().toFormattedDate(),
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
      body: state.when(
        data: (buildJobs) {
          if (buildJobs.isEmpty) {
            return _EmptyState(colorScheme: colorScheme);
          }

          final activeJobs = buildJobs
              .where(
                (j) => j.status == 'in_progress' || j.status == 'queued',
              )
              .toList();
          final completedJobs = buildJobs
              .where(
                (j) => j.status != 'in_progress' && j.status != 'queued',
              )
              .toList();

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              if (activeJobs.isNotEmpty) ...[
                _SectionHeader(
                  icon: Icons.play_circle_outline,
                  label: 'Active',
                  count: activeJobs.length,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 8),
                for (final job in activeJobs) ...[
                  _BuildJobCard(buildJob: job),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 12),
              ],
              if (completedJobs.isNotEmpty) ...[
                _SectionHeader(
                  icon: Icons.history,
                  label: 'Recent',
                  count: completedJobs.length,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                for (final job in completedJobs) ...[
                  _BuildJobCard(buildJob: job),
                  const SizedBox(height: 8),
                ],
              ],
            ],
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: asyncErrorWidget,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    colorScheme.primaryContainer.withValues(alpha: 0.5),
                    colorScheme.primaryContainer.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 28,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No builds yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Build logs will appear here\nwhen workflows are triggered.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _statusColor(String? status) {
  return switch (status) {
    'success' => Colors.green,
    'failure' => Colors.red,
    'in_progress' => Colors.blue,
    'queued' => Colors.orange,
    'cancelled' => Colors.grey,
    _ => Colors.transparent,
  };
}

class _BuildJobCard extends ConsumerWidget {
  const _BuildJobCard({required this.buildJob});
  final BuildJob buildJob;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workflowNameAsync = ref.watch(
      workflowNameProvider(buildJob.workflowId),
    );
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BuildLogsDetailPage(buildJob: buildJob),
            ),
          );
        },
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: _statusColor(buildJob.status),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 12,
                    right: 4,
                    top: 12,
                    bottom: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: workflowNameAsync.when(
                              data: (name) => Text(
                                name ?? '${buildJob.owner}/${buildJob.repo}',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                              loading: () => Container(
                                width: 120,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              error: asyncErrorWidget,
                            ),
                          ),
                          _BuildStatusBadge(status: buildJob.status),
                          _BuildJobMenu(buildJob: buildJob),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (buildJob.branch != null) ...[
                            _GitInfoBadge(
                              icon: FontAwesomeIcons.codeBranch,
                              label: buildJob.branch!,
                              colorScheme: colorScheme,
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (buildJob.commitSha != null)
                            _GitInfoBadge(
                              icon: FontAwesomeIcons.codeCommit,
                              label: buildJob.commitSha!.substring(0, 7),
                              colorScheme: colorScheme,
                            ),
                        ],
                      ),
                      if (buildJob.pullRequestNumber != null ||
                          buildJob.tagName != null) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            if (buildJob.pullRequestNumber != null)
                              _TriggerChip(
                                icon: FontAwesomeIcons.codePullRequest,
                                label: 'PR #${buildJob.pullRequestNumber}',
                                colorScheme: colorScheme,
                              ),
                            if (buildJob.tagName != null)
                              _TriggerChip(
                                icon: FontAwesomeIcons.tag,
                                label: buildJob.tagName!,
                                colorScheme: colorScheme,
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 11,
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.6,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            buildJob.createdAt.toTimeAgoEn(),
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuildJobMenu extends ConsumerWidget {
  const _BuildJobMenu({required this.buildJob});
  final BuildJob buildJob;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canCancel =
        buildJob.status == 'queued' || buildJob.status == 'in_progress';
    final isFailed = buildJob.status == 'failure';

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        size: 20,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onSelected: (value) async {
        switch (value) {
          case 'retry':
            try {
              context.showSnackBarMessage('Retrying build...');
              await ref
                  .read(buildJobsProvider.notifier)
                  .retryBuildJob(buildJob.id);
              if (!context.mounted) return;
              context.showSnackBarMessage('Build queued successfully');
            } catch (e) {
              if (!context.mounted) return;
              context.showSnackBarMessage('Failed to retry: $e');
            }
          case 'cancel':
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Cancel Build'),
                content: const Text(
                  'Are you sure you want to cancel this build?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('No'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: const Text('Cancel Build'),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              try {
                if (!context.mounted) return;
                context.showSnackBarMessage('Cancelling build...');
                await ref
                    .read(buildJobsProvider.notifier)
                    .cancelBuildJob(buildJob.id);
                if (context.mounted) {
                  context.showSnackBarMessage('Build cancelled');
                }
              } catch (e) {
                if (context.mounted) {
                  context.showSnackBarMessage('Failed to cancel: $e');
                }
              }
            }
          case 'ai_fix':
            if (!context.mounted) return;
            showAIFixSheet(context: context, buildJob: buildJob);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'retry',
          child: Row(
            children: [
              Icon(
                Icons.replay,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              const Text('Retry'),
            ],
          ),
        ),
        if (canCancel)
          PopupMenuItem(
            value: 'cancel',
            child: Row(
              children: [
                Icon(
                  Icons.cancel_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 12),
                Text(
                  'Cancel',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        if (isFailed)
          PopupMenuItem(
            value: 'ai_fix',
            child: Row(
              children: [
                Icon(
                  Icons.auto_fix_high_rounded,
                  size: 18,
                  color: Colors.green[400],
                ),
                const SizedBox(width: 12),
                Text(
                  'Fix with AI',
                  style: TextStyle(color: Colors.green[400]),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _BuildStatusBadge extends StatelessWidget {
  const _BuildStatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (status) {
      'success' => (Icons.check_circle, Colors.green, 'Passed'),
      'failure' => (Icons.cancel, Colors.red, 'Failed'),
      'in_progress' => (Icons.sync, Colors.blue, 'Running'),
      'queued' => (Icons.schedule, Colors.orange, 'Queued'),
      'cancelled' => (Icons.block, Colors.grey, 'Cancelled'),
      _ => (Icons.help_outline, Colors.grey, 'Unknown'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == 'in_progress')
            SizedBox(
              width: 11,
              height: 11,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: color,
              ),
            )
          else
            Icon(icon, color: color, size: 11),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _GitInfoBadge extends StatelessWidget {
  const _GitInfoBadge({
    required this.icon,
    required this.label,
    required this.colorScheme,
  });

  final IconData icon;
  final String label;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 10, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TriggerChip extends StatelessWidget {
  const _TriggerChip({
    required this.icon,
    required this.label,
    required this.colorScheme,
  });

  final IconData icon;
  final String label;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 8, color: colorScheme.primary),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
