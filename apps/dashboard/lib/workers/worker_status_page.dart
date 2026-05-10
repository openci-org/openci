import 'package:dashboard/extensions/date_time_extensions.dart';
import 'package:dashboard/theme/app_colors.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:dashboard/workers/worker_status_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class WorkerStatusBody extends HookConsumerWidget {
  const WorkerStatusBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refreshTick = useMemoized(
      () => Stream<DateTime>.periodic(
        const Duration(seconds: 30),
        (_) => DateTime.now(),
      ),
    );
    useStream(refreshTick, initialData: DateTime.now());

    final workersAsync = ref.watch(workerInstancesProvider);
    return _WorkerEscapeShortcut(
      child: workersAsync.when(
        data: (workers) {
          final macosWorkers = workers
              .where(
                (worker) => worker.platformGroup == WorkerPlatformGroup.macos,
              )
              .toList();
          final linuxWorkers = workers
              .where(
                (worker) => worker.platformGroup == WorkerPlatformGroup.linux,
              )
              .toList();
          final otherWorkers = workers
              .where(
                (worker) => worker.platformGroup == WorkerPlatformGroup.other,
              )
              .toList();

          if (workers.isEmpty) {
            return const _EmptyWorkers();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _WorkerSummary(workers: workers),
                      const SizedBox(height: 16),
                      _WorkerPlatformSection(
                        title: 'macOS workers',
                        subtitle: 'runs-on に macos を含むジョブを処理します',
                        icon: const FaIcon(FontAwesomeIcons.apple),
                        workers: macosWorkers,
                      ),
                      const SizedBox(height: 16),
                      _WorkerPlatformSection(
                        title: 'Linux workers',
                        subtitle: 'runs-on に ubuntu を含むジョブを処理します',
                        icon: const FaIcon(FontAwesomeIcons.linux),
                        workers: linuxWorkers,
                      ),
                      if (otherWorkers.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _WorkerPlatformSection(
                          title: 'Other workers',
                          subtitle: 'platform が macOS / Linux と判定できない worker',
                          icon: const Icon(Icons.device_unknown_rounded),
                          workers: otherWorkers,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
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

class _WorkerEscapeShortcut extends StatelessWidget {
  const _WorkerEscapeShortcut({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        },
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}

class _WorkerSummary extends StatelessWidget {
  const _WorkerSummary({required this.workers});

  final List<WorkerInstance> workers;

  @override
  Widget build(BuildContext context) {
    final online = workers.where((worker) => worker.isOnline).length;
    final busy = workers.where((worker) => worker.isBusy).length;
    final errors = workers
        .where((worker) => worker.isOnline && worker.hasError)
        .length;
    final offline = workers.length - online;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _SummaryTile(
          label: 'Online',
          value: online,
          color: AppColors.of(context).success,
        ),
        _SummaryTile(
          label: 'Busy',
          value: busy,
          color: AppColors.of(context).accent,
        ),
        _SummaryTile(
          label: 'Error',
          value: errors,
          color: AppColors.of(context).error,
        ),
        _SummaryTile(
          label: 'Offline',
          value: offline,
          color: AppColors.of(context).textTertiary,
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkerPlatformSection extends StatelessWidget {
  const _WorkerPlatformSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.workers,
  });

  final String title;
  final String subtitle;
  final Widget icon;
  final List<WorkerInstance> workers;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final onlineCount = workers.where((worker) => worker.isOnline).length;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                IconTheme(
                  data: IconThemeData(color: colors.accent, size: 24),
                  child: icon,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$onlineCount/${workers.length} online',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.divider),
          if (workers.isEmpty)
            Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                '登録された worker はありません',
                style: TextStyle(color: colors.textSecondary),
              ),
            )
          else
            ...workers.map((worker) => _WorkerCard(worker: worker)),
        ],
      ),
    );
  }
}

class _WorkerCard extends StatelessWidget {
  const _WorkerCard({required this.worker});

  final WorkerInstance worker;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final statusColor = _workerStatusColor(context, worker);
    final currentJob = worker.currentBuildJobId;
    final lastError = worker.lastError;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker.workerId,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        _MetaText(text: _workerStatusLabel(worker)),
                        _MetaText(text: 'version ${worker.version}'),
                        if (worker.hostname.isNotEmpty)
                          _MetaText(text: worker.hostname),
                        if (worker.pid != null)
                          _MetaText(text: 'pid ${worker.pid}'),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                'last seen ${worker.lastSeenAt.toTimeAgo()}',
                style: TextStyle(
                  color: worker.isOnline ? colors.textSecondary : colors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (currentJob != null && currentJob.isNotEmpty) ...[
            const SizedBox(height: 10),
            _WorkerDetailLine(
              icon: Icons.play_circle_outline_rounded,
              text: worker.currentRunId == null
                  ? 'Current job: $currentJob'
                  : 'Current job: $currentJob / run ${worker.currentRunId}',
            ),
          ],
          if (lastError != null && lastError.isNotEmpty) ...[
            const SizedBox(height: 10),
            _WorkerDetailLine(
              icon: Icons.error_outline_rounded,
              text: lastError,
              color: colors.error,
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.of(context).textSecondary,
        fontSize: 12,
      ),
    );
  }
}

class _WorkerDetailLine extends StatelessWidget {
  const _WorkerDetailLine({
    required this.icon,
    required this.text,
    this.color,
  });

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.of(context).textSecondary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: effectiveColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: effectiveColor,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyWorkers extends StatelessWidget {
  const _EmptyWorkers();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dns_outlined,
            size: 42,
            color: colors.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            'Worker heartbeat がまだありません',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '0.1.27 以降の worker が起動するとここに表示されます',
            style: TextStyle(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

String _workerStatusLabel(WorkerInstance worker) {
  if (!worker.isOnline) return 'offline';
  return switch (worker.status) {
    WorkerStatus.starting => 'starting',
    WorkerStatus.idle => 'idle',
    WorkerStatus.busy => 'busy',
    WorkerStatus.error => 'error',
    WorkerStatus.stopping => 'stopping',
    WorkerStatus.unknown => 'unknown',
  };
}

Color _workerStatusColor(BuildContext context, WorkerInstance worker) {
  final colors = AppColors.of(context);
  if (!worker.isOnline) return colors.textTertiary;
  return switch (worker.status) {
    WorkerStatus.busy => colors.accent,
    WorkerStatus.error => colors.error,
    WorkerStatus.idle => colors.success,
    WorkerStatus.starting => colors.warning,
    WorkerStatus.stopping => colors.warning,
    WorkerStatus.unknown => colors.textTertiary,
  };
}
