import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard/build_logs/build_logs_page.dart';
import 'package:dashboard/build_logs/synced_spinner.dart';
import 'package:dashboard/firebase/firestore.dart'
    show
        BuildJobStatus,
        buildJobStatusFromFirestore,
        dateTimeFromFirestore,
        workerInstancesCollection;
import 'package:dashboard/store_release/store_release_page.dart';
import 'package:dashboard/variables/variables_page.dart';
import 'package:dashboard/workflow/list/workflows_page.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import 'issue_board_ima_app_shell.dart';
import 'issue_board_ima_issue_editor.dart';
import 'issue_board_ima_models.dart';
import 'issue_board_ima_utils.dart';

class TeamSwitcherButton extends StatelessWidget {
  const TeamSwitcherButton({
    super.key,
    required this.workspaceName,
    required this.onPressed,
  });

  final String workspaceName;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'チーム切替',
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.groups_2_outlined, size: 18),
        label: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: Text(
            workspaceName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF334155),
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class IssueCountBadge extends StatelessWidget {
  const IssueCountBadge({super.key, required this.openIssues});

  final int openIssues;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$openIssues',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const Text(
            '未完了issue',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class BoardSidePanelDrawer extends StatelessWidget {
  const BoardSidePanelDrawer({
    super.key,
    required this.panel,
    required this.onDismiss,
  });

  final BoardSidePanel panel;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return switch (panel) {
      BoardSidePanel.workers => WorkerInspectorPanel(onDismiss: onDismiss),
      BoardSidePanel.runs => _BoardSidePanelShell(
        icon: Icons.history_rounded,
        title: 'CI/CDログ',
        onDismiss: onDismiss,
        child: const LogsBody(),
      ),
      BoardSidePanel.workflows => _BoardSidePanelShell(
        icon: Icons.schema_rounded,
        title: 'CI/CD設定',
        onDismiss: onDismiss,
        child: const WorkflowsBody(),
      ),
      BoardSidePanel.variables => _BoardSidePanelShell(
        icon: Icons.key_rounded,
        title: 'シークレット',
        onDismiss: onDismiss,
        child: const VariablesBody(),
      ),
      BoardSidePanel.storeRelease => _BoardSidePanelShell(
        icon: Icons.rocket_launch_outlined,
        title: 'ストアリリース',
        onDismiss: onDismiss,
        child: const StoreReleaseBody(),
      ),
    };
  }
}

class _BoardSidePanelShell extends StatelessWidget {
  const _BoardSidePanelShell({
    required this.icon,
    required this.title,
    required this.onDismiss,
    required this.child,
  });

  final IconData icon;
  final String title;
  final VoidCallback onDismiss;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 10, 12),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF2563EB)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'Esc で閉じる',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '閉じる',
                onPressed: onDismiss,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        Expanded(child: child),
      ],
    );
  }
}

class WorkerInspectorPanel extends StatelessWidget {
  const WorkerInspectorPanel({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(workerInstancesCollection)
          .orderBy('lastSeenAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _WorkerInspectorShell(
            onDismiss: onDismiss,
            child: const Center(child: Text('Worker status を読み込めませんでした')),
          );
        }
        if (!snapshot.hasData) {
          return _WorkerInspectorShell(
            onDismiss: onDismiss,
            child: const Center(child: CircularProgressIndicator.adaptive()),
          );
        }

        final workers = snapshot.data!.docs
            .map(WorkerInspectorItem.fromDoc)
            .toList();
        workers.sort(_compareWorkerInspectorItems);
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

        return _WorkerInspectorShell(
          onDismiss: onDismiss,
          child: workers.isEmpty
              ? const _WorkerInspectorEmpty()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  children: [
                    SizedBox(height: 14),
                    _WorkerInspectorSummary(workers: workers),
                    const SizedBox(height: 14),
                    _WorkerInspectorSection(
                      title: 'macOS',
                      workers: macosWorkers,
                      icon: const FaIcon(FontAwesomeIcons.apple),
                    ),
                    const SizedBox(height: 14),
                    _WorkerInspectorSection(
                      title: 'Linux',
                      workers: linuxWorkers,
                      icon: const FaIcon(FontAwesomeIcons.linux),
                    ),
                    if (otherWorkers.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _WorkerInspectorSection(
                        title: 'その他',
                        workers: otherWorkers,
                        icon: const Icon(Icons.device_unknown_rounded),
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }
}

class _WorkerInspectorShell extends StatelessWidget {
  const _WorkerInspectorShell({
    required this.onDismiss,
    required this.child,
  });

  final VoidCallback onDismiss;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 10, 12),
          child: Row(
            children: [
              const Icon(Icons.dns_outlined, color: Color(0xFF2563EB)),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ワーカー',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Esc で閉じる',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '閉じる',
                onPressed: onDismiss,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        Expanded(child: child),
      ],
    );
  }
}

class _WorkerInspectorSummary extends StatelessWidget {
  const _WorkerInspectorSummary({required this.workers});

  final List<WorkerInspectorItem> workers;

  @override
  Widget build(BuildContext context) {
    final online = workers.where((worker) => worker.isOnline).length;
    final busy = workers.where((worker) => worker.isBusy).length;
    final error = workers
        .where((worker) => worker.hasError && worker.isOnline)
        .length;
    final offline = workers.length - online;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _WorkerInspectorSummaryChip(
          label: 'オンライン',
          value: online,
          color: const Color(0xFF16A34A),
        ),
        _WorkerInspectorSummaryChip(
          label: '実行中',
          value: busy,
          color: const Color(0xFF2563EB),
        ),
        _WorkerInspectorSummaryChip(
          label: 'エラー',
          value: error,
          color: const Color(0xFFDC2626),
        ),
        _WorkerInspectorSummaryChip(
          label: 'オフライン',
          value: offline,
          color: const Color(0xFF64748B),
        ),
      ],
    );
  }
}

class _WorkerInspectorSummaryChip extends StatelessWidget {
  const _WorkerInspectorSummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkerInspectorSection extends StatelessWidget {
  const _WorkerInspectorSection({
    required this.title,
    required this.workers,
    required this.icon,
  });

  final String title;
  final List<WorkerInspectorItem> workers;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final online = workers.where((worker) => worker.isOnline).length;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                IconTheme(
                  data: const IconThemeData(
                    color: Color(0xFF2563EB),
                    size: 18,
                  ),
                  child: icon,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '$online/${workers.length} オンライン',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          if (workers.isEmpty)
            const Padding(
              padding: EdgeInsets.all(14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '登録された worker はありません',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
              ),
            )
          else
            for (final worker in workers) _WorkerInspectorRow(worker: worker),
        ],
      ),
    );
  }
}

class _WorkerInspectorRow extends StatelessWidget {
  const _WorkerInspectorRow({required this.worker});

  final WorkerInspectorItem worker;

  @override
  Widget build(BuildContext context) {
    final statusColor = worker.statusColor;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker.workerId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        worker.statusLabel,
                        'v${worker.version}',
                        if (worker.hostname.isNotEmpty) worker.hostname,
                        if (worker.pid != null) 'pid ${worker.pid}',
                      ].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatWorkerLastSeen(worker.lastSeenAt),
                style: TextStyle(
                  color: worker.isOnline
                      ? const Color(0xFF64748B)
                      : const Color(0xFFDC2626),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (worker.currentBuildJobId != null) ...[
            const SizedBox(height: 8),
            _WorkerInspectorDetail(
              icon: Icons.play_circle_outline_rounded,
              text: worker.currentRunId == null
                  ? '実行中のジョブ: ${worker.currentBuildJobId}'
                  : '実行中のジョブ: ${worker.currentBuildJobId} / run ${worker.currentRunId}',
            ),
          ],
          if (worker.lastError != null && worker.lastError!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _WorkerInspectorDetail(
              icon: Icons.error_outline_rounded,
              text: worker.lastError!,
              color: const Color(0xFFDC2626),
            ),
          ],
        ],
      ),
    );
  }
}

class _WorkerInspectorDetail extends StatelessWidget {
  const _WorkerInspectorDetail({
    required this.icon,
    required this.text,
    this.color = const Color(0xFF64748B),
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontSize: 12, height: 1.35),
          ),
        ),
      ],
    );
  }
}

class _WorkerInspectorEmpty extends StatelessWidget {
  const _WorkerInspectorEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Worker heartbeat がまだありません\n0.1.27 以降の worker が起動すると表示されます',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF64748B), height: 1.5),
        ),
      ),
    );
  }
}

enum WorkerPlatformGroup { macos, linux, other }

int _compareWorkerInspectorItems(
  WorkerInspectorItem a,
  WorkerInspectorItem b,
) {
  final platformCompare = a.platformGroup.index.compareTo(
    b.platformGroup.index,
  );
  if (platformCompare != 0) return platformCompare;
  return a.workerId.toLowerCase().compareTo(b.workerId.toLowerCase());
}

class WorkerInspectorItem {
  const WorkerInspectorItem({
    required this.workerId,
    required this.version,
    required this.platform,
    required this.hostname,
    required this.status,
    required this.lastSeenAt,
    this.pid,
    this.currentBuildJobId,
    this.currentRunId,
    this.consecutiveFailures = 0,
    this.lastError,
  });

  static const offlineAfter = Duration(minutes: 2);

  final String workerId;
  final String version;
  final String platform;
  final String hostname;
  final String status;
  final DateTime lastSeenAt;
  final int? pid;
  final String? currentBuildJobId;
  final String? currentRunId;
  final int consecutiveFailures;
  final String? lastError;

  factory WorkerInspectorItem.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return WorkerInspectorItem(
      workerId: data['workerId'] as String? ?? doc.id,
      version: data['version'] as String? ?? 'unknown',
      platform: data['platform'] as String? ?? 'unknown',
      hostname: data['hostname'] as String? ?? '',
      status: data['status'] as String? ?? 'unknown',
      lastSeenAt: dateTimeFromFirestore(data['lastSeenAt']),
      pid: data['pid'] is int ? data['pid'] as int : null,
      currentBuildJobId: data['currentBuildJobId'] as String?,
      currentRunId: data['currentRunId'] as String?,
      consecutiveFailures: data['consecutiveFailures'] is int
          ? data['consecutiveFailures'] as int
          : 0,
      lastError: data['lastError'] as String?,
    );
  }

  bool get isOnline => DateTime.now().difference(lastSeenAt) < offlineAfter;
  bool get isBusy => isOnline && status == 'busy';
  bool get hasError => status == 'error' || consecutiveFailures > 0;

  WorkerPlatformGroup get platformGroup {
    final normalized = platform.toLowerCase();
    if (normalized == 'darwin' || normalized.contains('mac')) {
      return WorkerPlatformGroup.macos;
    }
    if (normalized == 'linux') {
      return WorkerPlatformGroup.linux;
    }
    return WorkerPlatformGroup.other;
  }

  String get statusLabel {
    if (!isOnline) return 'オフライン';
    return switch (status) {
      'busy' => '実行中',
      'error' => 'エラー',
      'idle' => '待機中',
      'starting' => '起動中',
      'stopping' => '停止中',
      _ => '不明',
    };
  }

  Color get statusColor {
    if (!isOnline) return const Color(0xFF94A3B8);
    return switch (status) {
      'busy' => const Color(0xFF2563EB),
      'error' => const Color(0xFFDC2626),
      'idle' => const Color(0xFF16A34A),
      'starting' => const Color(0xFFA16207),
      'stopping' => const Color(0xFFA16207),
      _ => const Color(0xFF94A3B8),
    };
  }
}

String formatWorkerLastSeen(DateTime lastSeenAt) {
  final diff = DateTime.now().difference(lastSeenAt);
  if (diff.inSeconds < 10) return 'たった今';
  if (diff.inSeconds < 60) return '${diff.inSeconds}秒前';
  if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
  if (diff.inHours < 24) return '${diff.inHours}時間前';
  return '${diff.inDays}日前';
}

class BuildStatusBadge extends StatelessWidget {
  const BuildStatusBadge({super.key, required this.status});

  final CardBuildStatus? status;

  @override
  Widget build(BuildContext context) {
    final currentStatus = status;
    if (currentStatus == null) {
      return const SizedBox.shrink();
    }

    final color = currentStatus.color;
    return Tooltip(
      message: currentStatus.tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => BuildStatusJobsDialog(status: currentStatus),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color.withValues(alpha: 0.28)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              BuildStatusIndicator(
                icon: currentStatus.icon,
                color: color,
                isSpinning: currentStatus.isSpinning,
                size: 11.5,
              ),
              if (currentStatus.label.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  currentStatus.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class BuildStatusJobsDialog extends StatelessWidget {
  const BuildStatusJobsDialog({super.key, required this.status});

  final CardBuildStatus status;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isCompactDialog = screenSize.width < 560;
    final dialogPadding = EdgeInsets.all(isCompactDialog ? 18 : 24);
    final maxHeight = screenSize.height * (isCompactDialog ? 0.9 : 0.82);
    final dialogBorderRadius = BorderRadius.circular(28);

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompactDialog ? 12 : 20,
        vertical: isCompactDialog ? 12 : 24,
      ),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: dialogBorderRadius),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 720, maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: dialogPadding.copyWith(bottom: 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: DialogHeader(
                title: 'CI checks',
                description: status.summaryLabel,
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: dialogPadding.copyWith(top: 16, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: status.color.withValues(alpha: 0.08),
                        border: Border.all(
                          color: status.color.withValues(alpha: 0.18),
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: status.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: BuildStatusIndicator(
                                icon: status.icon,
                                color: status.color,
                                isSpinning: status.isSpinning,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              status.tooltip,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: status.color,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    for (final entry in status.jobs.indexed) ...[
                      BuildStatusJobRow(job: entry.$2),
                      if (entry.$1 != status.jobs.length - 1)
                        const SizedBox(height: 8),
                    ],
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

class BuildStatusJobRow extends StatelessWidget {
  const BuildStatusJobRow({super.key, required this.job});

  final BuildStatusJob job;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          context.push('/runs/${Uri.encodeComponent(job.id)}');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: job.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: BuildStatusIndicator(
                    icon: job.icon,
                    color: job.color,
                    isSpinning: job.isSpinning,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      job.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                job.statusLabel,
                style: TextStyle(
                  color: job.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BuildStatusIndicator extends StatelessWidget {
  const BuildStatusIndicator({
    super.key,
    required this.icon,
    required this.color,
    required this.isSpinning,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final bool isSpinning;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (isSpinning) {
      return SyncedSpinner(color: color, size: size, strokeWidth: 2);
    }

    return Icon(icon, size: size, color: color);
  }
}

class RecentRunSummary {
  const RecentRunSummary({
    required this.id,
    required this.status,
    required this.owner,
    required this.repo,
    required this.createdAt,
    required this.workflowName,
    required this.workflowFileName,
    required this.jobKey,
    required this.branch,
    required this.workflowRunId,
    required this.pullRequestNumber,
  });

  final String id;
  final BuildJobStatus status;
  final String owner;
  final String repo;
  final DateTime createdAt;
  final String workflowName;
  final String workflowFileName;
  final String jobKey;
  final String branch;
  final String workflowRunId;
  final int pullRequestNumber;

  String get repository => '$owner/$repo';

  String get workflowTitle => workflowName.isEmpty ? repository : workflowName;

  String get workflowRunGroupKey =>
      '${workflowRunId.isEmpty ? id : workflowRunId}:$workflowFileName';

  static RecentRunSummary? fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    try {
      return RecentRunSummary(
        id: doc.id,
        status: buildJobStatusFromFirestore(data['status']),
        owner: asString(data['owner']),
        repo: asString(data['repo']),
        createdAt:
            asDate(data['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
        workflowName: asString(data['workflowName']),
        workflowFileName: asString(data['workflowFileName']),
        jobKey: asString(data['jobKey']),
        branch: asString(data['branch']),
        workflowRunId: asString(data['workflowRunId']),
        pullRequestNumber: asInt(data['pullRequestNumber']),
      );
    } catch (_) {
      return null;
    }
  }
}

class CardBuildStatus {
  const CardBuildStatus({
    required this.label,
    required this.tooltip,
    required this.color,
    required this.icon,
    required this.signature,
    required this.isSpinning,
    required this.workflowTitle,
    required this.summaryLabel,
    required this.jobs,
  });

  final String label;
  final String tooltip;
  final Color color;
  final IconData icon;
  final String signature;
  final bool isSpinning;
  final String workflowTitle;
  final String summaryLabel;
  final List<BuildStatusJob> jobs;

  static CardBuildStatus? fromRuns(List<RecentRunSummary> runs) {
    if (runs.isEmpty) {
      return null;
    }

    final sortedRuns = runs.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final selectedWorkflowKeys = <String>{};
    final selectedRunIds = <String>{};
    for (final run in sortedRuns) {
      final workflowKey = '${run.workflowTitle}:${run.workflowFileName}';
      if (!selectedWorkflowKeys.add(workflowKey)) {
        continue;
      }
      selectedRunIds.add(run.workflowRunGroupKey);
    }
    final currentRuns =
        [
          for (final run in sortedRuns)
            if (selectedRunIds.contains(run.workflowRunGroupKey)) run,
        ]..sort((a, b) {
          final workflowCompare = a.workflowTitle.compareTo(b.workflowTitle);
          if (workflowCompare != 0) {
            return workflowCompare;
          }
          return a.jobKey.compareTo(b.jobKey);
        });

    var passed = 0;
    var failed = 0;
    var active = 0;
    var other = 0;
    var queuedOnly = true;

    for (final run in currentRuns) {
      switch (run.status) {
        case BuildJobStatus.SUCCESS:
          passed++;
          queuedOnly = false;
        case BuildJobStatus.FAILURE || BuildJobStatus.TIMED_OUT:
          failed++;
          queuedOnly = false;
        case BuildJobStatus.IN_PROGRESS || BuildJobStatus.WAITING:
          active++;
          queuedOnly = false;
        case BuildJobStatus.QUEUED:
          active++;
        case BuildJobStatus.CANCELLED || BuildJobStatus.SKIPPED:
          other++;
          queuedOnly = false;
      }
    }

    final total = currentRuns.length;
    final jobs = [
      for (final run in currentRuns)
        BuildStatusJob(
          id: run.id,
          title: run.jobKey.isEmpty ? run.workflowTitle : run.jobKey,
          subtitle: [
            run.workflowTitle,
            if (run.branch.isNotEmpty) run.branch,
            relativeTimeLabel(run.createdAt),
          ].join(' / '),
          status: run.status,
          createdAt: run.createdAt,
        ),
    ];
    final summaryLabel =
        '$passed passed / $failed failed / $active running / $other other';

    final label = failed > 0
        ? 'fail'
        : active > 0
        ? queuedOnly
              ? 'queued'
              : '$passed/$total CI pass'
        : passed == total
        ? total == 1
              ? 'CI pass'
              : '$passed CI pass'
        : '$passed/$total CI pass';
    final color = failed > 0
        ? const Color(0xFFB91C1C)
        : active > 0
        ? const Color(0xFF2563EB)
        : passed == total
        ? const Color(0xFF15803D)
        : const Color(0xFFB45309);
    final icon = failed > 0
        ? Icons.cancel_rounded
        : active > 0
        ? queuedOnly
              ? Icons.schedule_rounded
              : Icons.sync_rounded
        : passed == total
        ? Icons.check_circle_rounded
        : Icons.adjust_rounded;

    return CardBuildStatus(
      label: label,
      color: color,
      icon: icon,
      isSpinning: shouldSpinCardBuildStatus(
        failed: failed,
        active: active,
        queuedOnly: queuedOnly,
      ),
      signature: jobs.map((job) => '${job.id}:${job.status.name}').join(','),
      workflowTitle: 'PR checks',
      summaryLabel: summaryLabel,
      jobs: jobs,
      tooltip: 'PR checks: $summaryLabel',
    );
  }
}

@visibleForTesting
bool shouldSpinCardBuildStatus({
  required int failed,
  required int active,
  required bool queuedOnly,
}) {
  return failed == 0 && active > 0 && !queuedOnly;
}

class BuildStatusJob {
  const BuildStatusJob({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String subtitle;
  final BuildJobStatus status;
  final DateTime createdAt;

  Color get color => switch (status) {
    BuildJobStatus.SUCCESS => const Color(0xFF15803D),
    BuildJobStatus.FAILURE ||
    BuildJobStatus.TIMED_OUT => const Color(0xFFB91C1C),
    BuildJobStatus.IN_PROGRESS => const Color(0xFF2563EB),
    BuildJobStatus.QUEUED => const Color(0xFF7C3AED),
    BuildJobStatus.WAITING ||
    BuildJobStatus.CANCELLED => const Color(0xFFB45309),
    BuildJobStatus.SKIPPED => const Color(0xFF64748B),
  };

  IconData get icon => switch (status) {
    BuildJobStatus.SUCCESS => Icons.check_circle_rounded,
    BuildJobStatus.FAILURE => Icons.cancel_rounded,
    BuildJobStatus.IN_PROGRESS => Icons.sync_rounded,
    BuildJobStatus.QUEUED => Icons.schedule_rounded,
    BuildJobStatus.WAITING => Icons.adjust_rounded,
    BuildJobStatus.CANCELLED => Icons.block_rounded,
    BuildJobStatus.SKIPPED => Icons.skip_next_rounded,
    BuildJobStatus.TIMED_OUT => Icons.timer_off_rounded,
  };

  bool get isSpinning => status == BuildJobStatus.IN_PROGRESS;

  String get statusLabel => switch (status) {
    BuildJobStatus.SUCCESS => 'passed',
    BuildJobStatus.FAILURE => 'failed',
    BuildJobStatus.IN_PROGRESS => 'running',
    BuildJobStatus.QUEUED => 'queued',
    BuildJobStatus.WAITING => 'waiting',
    BuildJobStatus.CANCELLED => 'cancelled',
    BuildJobStatus.SKIPPED => 'skipped',
    BuildJobStatus.TIMED_OUT => 'timed out',
  };
}

CardBuildStatus? _buildStatusForIssue(
  Issue issue,
  Map<String, CardBuildStatus> statusesByPullRequest,
) {
  for (final pullRequest in issue.pullRequests.reversed) {
    final status =
        statusesByPullRequest[buildStatusKey(
          issue.repo,
          pullRequest.number,
        )];
    if (status != null) {
      return status;
    }
  }
  return null;
}

Map<String, CardBuildStatus> buildStatusesByIssueId(
  List<Issue> issues,
  Map<String, CardBuildStatus> statusesByPullRequest,
) {
  final statuses = <String, CardBuildStatus>{};
  for (final issue in issues) {
    final status = _buildStatusForIssue(issue, statusesByPullRequest);
    if (status != null) {
      statuses[issue.id] = status;
    }
  }
  return statuses;
}

String buildStatusKey(String repository, int pullRequestNumber) {
  return '$repository#$pullRequestNumber';
}

String issueRepositoryNumberKey(String repository, int number) {
  return '$repository#$number';
}

Map<String, Issue> issuesByRepositoryNumber(List<Issue> issues) {
  final issuesByNumber = <String, Issue>{};
  for (final issue in issues) {
    if (issue.repo.isEmpty || issue.githubNumber <= 0) {
      continue;
    }
    issuesByNumber[issueRepositoryNumberKey(issue.repo, issue.githubNumber)] =
        issue;
  }
  return issuesByNumber;
}

String buildStatusMapSignature(Map<String, CardBuildStatus> statuses) {
  final keys = statuses.keys.toList()..sort();
  return [
    for (final key in keys) '$key:${statuses[key]!.signature}',
  ].join('|');
}

String relativeTimeLabel(DateTime value) {
  final difference = DateTime.now().difference(value);
  if (difference.inMinutes < 1) {
    return 'たった今';
  }
  if (difference.inHours < 1) {
    return '${difference.inMinutes}分前';
  }
  if (difference.inDays < 1) {
    return '${difference.inHours}時間前';
  }
  if (difference.inDays < 30) {
    return '${difference.inDays}日前';
  }
  final months = (difference.inDays / 30).floor();
  return '$monthsヶ月前';
}
