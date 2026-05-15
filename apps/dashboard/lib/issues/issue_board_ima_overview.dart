part of 'issue_board_ima_page.dart';

class BoardHeader extends StatelessWidget {
  const BoardHeader({
    super.key,
    required this.openIssues,
    required this.closedIssues,
    required this.dailyProgressStats,
    required this.onChangeDailyWeightTarget,
    required this.onWorkerOverviewTap,
  });

  final int openIssues;
  final List<Issue> closedIssues;
  final DailyProgressStats dailyProgressStats;
  final VoidCallback onChangeDailyWeightTarget;
  final VoidCallback onWorkerOverviewTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 520;
        final title = Text(
          'OpenCI',
          style:
              (isCompact ? textTheme.headlineSmall : textTheme.headlineMedium)
                  ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.8),
        );
        if (isCompact) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: 10),
                DailyProgressStrip(
                  stats: dailyProgressStats,
                  isCompact: true,
                  onTap: onChangeDailyWeightTarget,
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [Expanded(child: title)],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: BoardOverviewPanel(
                    openIssues: openIssues,
                    closedIssues: closedIssues,
                    dailyProgressStats: dailyProgressStats,
                    onDailyProgressTap: onChangeDailyWeightTarget,
                    onWorkerOverviewTap: onWorkerOverviewTap,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

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

class EstimationAccuracyBadge extends StatelessWidget {
  const EstimationAccuracyBadge({super.key, required this.closedIssues});

  static const _validWeights = [1, 2, 4, 8, 16, 32];

  static bool _isAdjacent(int a, int b) {
    final idxA = _validWeights.indexOf(a);
    final idxB = _validWeights.indexOf(b);
    if (idxA < 0 || idxB < 0) return (a - b).abs() <= 1;
    return (idxA - idxB).abs() <= 1;
  }

  final List<Issue> closedIssues;

  @override
  Widget build(BuildContext context) {
    final pairs = closedIssues
        .where(
          (issue) =>
              issue.resolution?.actualWeight != null &&
              issue.weightEstimate?.value != null,
        )
        .toList();

    if (pairs.isEmpty) {
      return const SizedBox.shrink();
    }

    final adjacentCount = pairs
        .where(
          (issue) => _isAdjacent(
            issue.weightEstimate!.value!,
            issue.resolution!.actualWeight!,
          ),
        )
        .length;
    final within1Rate = (adjacentCount / pairs.length * 100).round();
    final deltas = pairs
        .map(
          (issue) =>
              issue.weightEstimate!.value! - issue.resolution!.actualWeight!,
        )
        .toList();
    final sumAbsError = deltas.fold<int>(0, (s, d) => s + d.abs());
    final mae = (sumAbsError / deltas.length * 10).round() / 10;
    final sumDelta = deltas.fold<int>(0, (s, d) => s + d);
    final bias = (sumDelta / deltas.length * 10).round() / 10;

    final biasLabel = bias == 0
        ? 'バイアスなし'
        : bias > 0
        ? '過大推定 +$bias'
        : '過小推定 $bias';
    final accuracyColor = within1Rate >= 70
        ? const Color(0xFF15803D)
        : within1Rate >= 50
        ? const Color(0xFFA16207)
        : const Color(0xFFDC2626);

    return Tooltip(
      message: 'MAE $mae / $biasLabel / ${pairs.length}件',
      child: Container(
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
              '$within1Rate%',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: accuracyColor,
              ),
            ),
            const Text(
              '推定精度 (隣接値)',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class BoardOverviewPanel extends StatelessWidget {
  const BoardOverviewPanel({
    super.key,
    required this.openIssues,
    required this.closedIssues,
    required this.dailyProgressStats,
    required this.onDailyProgressTap,
    required this.onWorkerOverviewTap,
  });

  final int openIssues;
  final List<Issue> closedIssues;
  final DailyProgressStats dailyProgressStats;
  final VoidCallback onDailyProgressTap;
  final VoidCallback onWorkerOverviewTap;

  @override
  Widget build(BuildContext context) {
    final accuracy = EstimationAccuracySummary.fromIssues(closedIssues);

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: DailyProgressOverview(
                stats: dailyProgressStats,
                onTap: onDailyProgressTap,
              ),
            ),
            const _OverviewDivider(),
            Tooltip(
              message:
                  '${dailyProgressStats.prediction.advice} / 午後中央値 W${dailyProgressStats.prediction.historicalAfternoonMedian.toStringAsFixed(1)} / ${dailyProgressStats.prediction.sampleCount}日',
              child: OverviewMetric(
                label: '見込み',
                value: '${dailyProgressStats.prediction.finishProbability}%',
                valueColor: dailyProgressStats.prediction.color,
                detail: dailyProgressStats.prediction.paceLabel,
              ),
            ),
            const _OverviewDivider(),
            OverviewMetric(
              label: '未完了',
              value: '$openIssues',
              detail: 'issue',
            ),
            if (accuracy != null) ...[
              const _OverviewDivider(),
              Tooltip(
                message:
                    'MAE ${accuracy.mae} / ${accuracy.biasLabel} / ${accuracy.sampleCount}件',
                child: OverviewMetric(
                  label: '精度',
                  value: '${accuracy.within1Rate}%',
                  valueColor: accuracy.color,
                  detail: '±1',
                ),
              ),
            ],
            const _OverviewDivider(),
            WorkerOverviewMetric(onTap: onWorkerOverviewTap),
          ],
        ),
      ),
    );
  }
}

class WorkerOverviewMetric extends StatelessWidget {
  const WorkerOverviewMetric({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(workerInstancesCollection)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _WorkerOverviewTapTarget(
            onTap: onTap,
            child: const OverviewMetric(
              label: 'ワーカー',
              value: '-',
              detail: '読み込みエラー',
              valueColor: Color(0xFFDC2626),
              width: 112,
            ),
          );
        }
        if (!snapshot.hasData) {
          return _WorkerOverviewTapTarget(
            onTap: onTap,
            child: const OverviewMetric(
              label: 'ワーカー',
              value: '-',
              detail: '読み込み中',
              width: 112,
            ),
          );
        }

        final summary = WorkerOverviewSummary.fromDocs(snapshot.data!.docs);
        final valueColor = summary.offlineCount > 0
            ? const Color(0xFFA16207)
            : const Color(0xFF16A34A);
        return Tooltip(
          message:
              'macOS ${summary.onlineMacos}/${summary.totalMacos} オンライン / '
              'Linux ${summary.onlineLinux}/${summary.totalLinux} オンライン / '
              'オフライン ${summary.offlineCount}',
          child: _WorkerOverviewTapTarget(
            onTap: onTap,
            child: OverviewMetric(
              label: 'ワーカー',
              value: '${summary.onlineCount}/${summary.totalCount}',
              valueColor: valueColor,
              detail:
                  'mac ${summary.onlineMacos} / linux ${summary.onlineLinux}',
              width: 112,
            ),
          ),
        );
      },
    );
  }
}

class _WorkerOverviewTapTarget extends StatelessWidget {
  const _WorkerOverviewTapTarget({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: child,
    );
  }
}

class WorkerOverviewSummary {
  const WorkerOverviewSummary({
    required this.totalMacos,
    required this.onlineMacos,
    required this.totalLinux,
    required this.onlineLinux,
    required this.totalOther,
    required this.onlineOther,
  });

  static const offlineAfter = Duration(minutes: 2);

  final int totalMacos;
  final int onlineMacos;
  final int totalLinux;
  final int onlineLinux;
  final int totalOther;
  final int onlineOther;

  int get totalCount => totalMacos + totalLinux + totalOther;
  int get onlineCount => onlineMacos + onlineLinux + onlineOther;
  int get offlineCount => totalCount - onlineCount;

  static WorkerOverviewSummary fromDocs(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    var totalMacos = 0;
    var onlineMacos = 0;
    var totalLinux = 0;
    var onlineLinux = 0;
    var totalOther = 0;
    var onlineOther = 0;
    final now = DateTime.now();

    for (final doc in docs) {
      final data = doc.data();
      final platform = (data['platform'] as String? ?? '').toLowerCase();
      final lastSeenAt = dateTimeFromFirestore(data['lastSeenAt']);
      final isOnline = now.difference(lastSeenAt) < offlineAfter;

      if (platform == 'darwin' || platform.contains('mac')) {
        totalMacos += 1;
        if (isOnline) onlineMacos += 1;
      } else if (platform == 'linux') {
        totalLinux += 1;
        if (isOnline) onlineLinux += 1;
      } else {
        totalOther += 1;
        if (isOnline) onlineOther += 1;
      }
    }

    return WorkerOverviewSummary(
      totalMacos: totalMacos,
      onlineMacos: onlineMacos,
      totalLinux: totalLinux,
      onlineLinux: onlineLinux,
      totalOther: totalOther,
      onlineOther: onlineOther,
    );
  }
}

class _BoardSidePanelDrawer extends StatelessWidget {
  const _BoardSidePanelDrawer({
    required this.panel,
    required this.onDismiss,
  });

  final _BoardSidePanel panel;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return switch (panel) {
      _BoardSidePanel.workers => WorkerInspectorPanel(onDismiss: onDismiss),
      _BoardSidePanel.runs => _BoardSidePanelShell(
        icon: Icons.history_rounded,
        title: 'CI/CDログ',
        onDismiss: onDismiss,
        child: const LogsBody(),
      ),
      _BoardSidePanel.workflows => _BoardSidePanelShell(
        icon: Icons.schema_rounded,
        title: 'CI/CD設定',
        onDismiss: onDismiss,
        child: const WorkflowsBody(),
      ),
      _BoardSidePanel.variables => _BoardSidePanelShell(
        icon: Icons.key_rounded,
        title: '変数',
        onDismiss: onDismiss,
        child: const VariablesBody(),
      ),
      _BoardSidePanel.storeRelease => _BoardSidePanelShell(
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
                _formatWorkerLastSeen(worker.lastSeenAt),
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

String _formatWorkerLastSeen(DateTime lastSeenAt) {
  final diff = DateTime.now().difference(lastSeenAt);
  if (diff.inSeconds < 10) return 'たった今';
  if (diff.inSeconds < 60) return '${diff.inSeconds}秒前';
  if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
  if (diff.inHours < 24) return '${diff.inHours}時間前';
  return '${diff.inDays}日前';
}

class DailyProgressOverview extends StatelessWidget {
  const DailyProgressOverview({
    super.key,
    required this.stats,
    required this.onTap,
  });

  final DailyProgressStats stats;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progressColor = stats.isAchieved
        ? const Color(0xFF16A34A)
        : Theme.of(context).colorScheme.primary;
    final percent = (stats.progress * 100).round();
    final adviceLabel = stats.prediction.advice;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                const Text(
                  '今日',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'W${stats.completedWeight} / W${stats.targetWeight}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${stats.completedCount}件完了 · $adviceLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: stats.isAchieved
                          ? const Color(0xFF15803D)
                          : const Color(0xFF475569),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '$percent%',
                  style: TextStyle(
                    color: progressColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 6,
                value: stats.cappedProgress,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OverviewMetric extends StatelessWidget {
  const OverviewMetric({
    super.key,
    required this.label,
    required this.value,
    required this.detail,
    this.valueColor = const Color(0xFF0F172A),
    this.width = 92,
  });

  final String label;
  final String value;
  final String detail;
  final Color valueColor;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewDivider extends StatelessWidget {
  const _OverviewDivider();

  @override
  Widget build(BuildContext context) {
    return const VerticalDivider(
      width: 1,
      thickness: 1,
      color: Color(0xFFE2E8F0),
    );
  }
}

class EstimationAccuracySummary {
  const EstimationAccuracySummary({
    required this.within1Rate,
    required this.mae,
    required this.bias,
    required this.sampleCount,
  });

  final int within1Rate;
  final double mae;
  final double bias;
  final int sampleCount;

  static EstimationAccuracySummary? fromIssues(List<Issue> closedIssues) {
    final pairs = closedIssues
        .where(
          (issue) =>
              issue.resolution?.actualWeight != null &&
              issue.weightEstimate?.value != null,
        )
        .toList();

    if (pairs.isEmpty) {
      return null;
    }

    final deltas = pairs
        .map(
          (issue) =>
              issue.weightEstimate!.value! - issue.resolution!.actualWeight!,
        )
        .toList();
    final within1 = deltas.where((d) => d.abs() <= 1).length;
    final sumAbsError = deltas.fold<int>(
      0,
      (total, delta) => total + delta.abs(),
    );
    final sumDelta = deltas.fold<int>(0, (total, delta) => total + delta);

    return EstimationAccuracySummary(
      within1Rate: (within1 / deltas.length * 100).round(),
      mae: (sumAbsError / deltas.length * 10).round() / 10,
      bias: (sumDelta / deltas.length * 10).round() / 10,
      sampleCount: pairs.length,
    );
  }

  String get biasLabel {
    if (bias == 0) {
      return 'バイアスなし';
    }
    return bias > 0 ? '過大推定 +$bias' : '過小推定 $bias';
  }

  Color get color {
    if (within1Rate >= 70) {
      return const Color(0xFF15803D);
    }
    if (within1Rate >= 50) {
      return const Color(0xFFA16207);
    }
    return const Color(0xFFDC2626);
  }
}

class DailyProgressStats {
  const DailyProgressStats({
    required this.targetWeight,
    required this.completedWeight,
    required this.completedCount,
    required this.recentAverageWeight,
    required this.history,
    required this.prediction,
  });

  final int targetWeight;
  final int completedWeight;
  final int completedCount;
  final double recentAverageWeight;
  final List<DailyProgressHistoryDay> history;
  final DailyProgressPrediction prediction;

  double get progress {
    if (targetWeight <= 0) {
      return 0;
    }
    return completedWeight / targetWeight;
  }

  double get cappedProgress {
    final value = progress;
    if (value.isNaN || value.isInfinite || value <= 0) {
      return 0;
    }
    if (value >= 1) {
      return 1;
    }
    return value;
  }

  int get remainingWeight {
    final remaining = targetWeight - completedWeight;
    return remaining > 0 ? remaining : 0;
  }

  int get overWeight {
    final over = completedWeight - targetWeight;
    return over > 0 ? over : 0;
  }

  bool get isAchieved => targetWeight > 0 && completedWeight >= targetWeight;
}

class DailyProgressHistoryDay {
  const DailyProgressHistoryDay({
    required this.date,
    required this.completedWeight,
    required this.completedCount,
    required this.morningWeight,
    required this.afternoonWeight,
  });

  final DateTime date;
  final int completedWeight;
  final int completedCount;
  final int morningWeight;
  final int afternoonWeight;
}

class DailyProgressPrediction {
  const DailyProgressPrediction({
    required this.finishProbability,
    required this.paceLabel,
    required this.advice,
    required this.color,
    required this.requiredAfternoonWeight,
    required this.historicalAfternoonMedian,
    required this.sampleCount,
    required this.usesFallback,
  });

  final int finishProbability;
  final String paceLabel;
  final String advice;
  final Color color;
  final int requiredAfternoonWeight;
  final double historicalAfternoonMedian;
  final int sampleCount;
  final bool usesFallback;
}

class _DailyPaceBucket {
  int totalWeight = 0;
  int completedCount = 0;
  int morningWeight = 0;
  int afternoonWeight = 0;
  int weightAtCurrentTime = 0;

  void add({
    required DateTime closedAt,
    required int weight,
    required DateTime now,
  }) {
    totalWeight += weight;
    completedCount += 1;

    if (closedAt.hour < 12) {
      morningWeight += weight;
    } else {
      afternoonWeight += weight;
    }

    if (_isAtOrBeforeTimeOfDay(closedAt, now)) {
      weightAtCurrentTime += weight;
    }
  }
}

class DailyProgressStrip extends StatelessWidget {
  const DailyProgressStrip({
    super.key,
    required this.stats,
    required this.onTap,
    this.isCompact = false,
  });

  final DailyProgressStats stats;
  final VoidCallback onTap;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progressColor = stats.isAchieved
        ? const Color(0xFF16A34A)
        : colorScheme.primary;
    final percent = (stats.progress * 100).round();
    final remainingLabel = stats.isAchieved
        ? stats.overWeight > 0
              ? '+W${stats.overWeight}'
              : '達成'
        : '残り W${stats.remainingWeight}';
    final progressLabel = 'W${stats.completedWeight} / W${stats.targetWeight}';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isCompact ? 16 : 0,
        isCompact ? 8 : 0,
        isCompact ? 16 : 0,
        isCompact ? 10 : 0,
      ),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isCompact ? 14 : 16,
              isCompact ? 12 : 14,
              isCompact ? 14 : 16,
              isCompact ? 12 : 14,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final useCompactContent =
                        isCompact || constraints.maxWidth < 520;
                    if (useCompactContent) {
                      return Row(
                        children: [
                          Expanded(
                            child: Text(
                              progressLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: const Color(0xFF0F172A),
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${stats.completedCount}件',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            remainingLabel,
                            style: TextStyle(
                              color: stats.isAchieved
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFF334155),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                '今日の目標',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                progressLabel,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: const Color(0xFF0F172A),
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.4,
                                    ),
                              ),
                              Text(
                                '${stats.completedCount}件完了',
                                style: const TextStyle(
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                remainingLabel,
                                style: TextStyle(
                                  color: stats.isAchieved
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFF334155),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$percent%',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: progressColor,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: isCompact ? 7 : 8,
                    value: stats.cappedProgress,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DailyProgressSheet extends StatefulWidget {
  const DailyProgressSheet({
    super.key,
    required this.currentTarget,
    required this.stats,
    this.onRecomputeWeights,
  });

  final int currentTarget;
  final DailyProgressStats stats;
  final Future<void> Function()? onRecomputeWeights;

  @override
  State<DailyProgressSheet> createState() => _DailyProgressSheetState();
}

class _DailyProgressSheetState extends State<DailyProgressSheet> {
  late int _target = _clampTarget(widget.currentTarget);

  int _clampTarget(int value) {
    if (value < 1) {
      return 1;
    }
    if (value > 99) {
      return 99;
    }
    return value;
  }

  void _changeTarget(int delta) {
    setState(() => _target = _clampTarget(_target + delta));
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final averageLabel = widget.stats.recentAverageWeight > 0
        ? '過去30日の平均: W${widget.stats.recentAverageWeight.toStringAsFixed(1)}/日'
        : '過去30日の平均はまだありません';

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: screenSize.height * 0.88,
          ),
          child: Material(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '1日の目標 Weight',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '泳ぐ距離を決めるように、毎日の目標を決めます。',
                              style: TextStyle(color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton.filledTonal(
                              onPressed: () => _changeTarget(-1),
                              icon: const Icon(Icons.remove_rounded),
                            ),
                            SizedBox(
                              width: 112,
                              child: Column(
                                children: [
                                  Text(
                                    'W$_target',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -1,
                                        ),
                                  ),
                                  const Text(
                                    '毎日の目標',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton.filled(
                              onPressed: () => _changeTarget(1),
                              icon: const Icon(Icons.add_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            OutlinedButton(
                              onPressed: () => _changeTarget(-5),
                              child: const Text('-5'),
                            ),
                            OutlinedButton(
                              onPressed: () => _changeTarget(5),
                              child: const Text('+5'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    averageLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text(
                        '過去30日の履歴',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const Spacer(),
                      const Text(
                        'Weight / 目標',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: widget.stats.history.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        itemBuilder: (context, index) =>
                            DailyProgressHistoryRow(
                              day: widget.stats.history[index],
                              targetWeight: _target,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (widget.onRecomputeWeights != null)
                        TextButton.icon(
                          onPressed: () {
                            widget.onRecomputeWeights!();
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Weight再計算'),
                        ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('キャンセル'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(_target),
                        child: const Text('保存'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
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
                size: 13,
              ),
              if (currentStatus.label.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  currentStatus.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
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
              child: _DialogHeader(
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

class _RecentRunSummary {
  const _RecentRunSummary({
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

  static _RecentRunSummary? fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    try {
      return _RecentRunSummary(
        id: doc.id,
        status: buildJobStatusFromFirestore(data['status']),
        owner: _asString(data['owner']),
        repo: _asString(data['repo']),
        createdAt:
            _asDate(data['createdAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0),
        workflowName: _asString(data['workflowName']),
        workflowFileName: _asString(data['workflowFileName']),
        jobKey: _asString(data['jobKey']),
        branch: _asString(data['branch']),
        workflowRunId: _asString(data['workflowRunId']),
        pullRequestNumber: _asInt(data['pullRequestNumber']),
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

  static CardBuildStatus? _fromRuns(List<_RecentRunSummary> runs) {
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
            _relativeTimeLabel(run.createdAt),
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
        statusesByPullRequest[_buildStatusKey(
          issue.repo,
          pullRequest.number,
        )];
    if (status != null) {
      return status;
    }
  }
  return null;
}

Map<String, CardBuildStatus> _buildStatusesByIssueId(
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

String _buildStatusKey(String repository, int pullRequestNumber) {
  return '$repository#$pullRequestNumber';
}

String _issueRepositoryNumberKey(String repository, int number) {
  return '$repository#$number';
}

Map<String, Issue> _issuesByRepositoryNumber(List<Issue> issues) {
  final issuesByNumber = <String, Issue>{};
  for (final issue in issues) {
    if (issue.repo.isEmpty || issue.githubNumber <= 0) {
      continue;
    }
    issuesByNumber[_issueRepositoryNumberKey(issue.repo, issue.githubNumber)] =
        issue;
  }
  return issuesByNumber;
}

String _buildStatusMapSignature(Map<String, CardBuildStatus> statuses) {
  final keys = statuses.keys.toList()..sort();
  return [
    for (final key in keys) '$key:${statuses[key]!.signature}',
  ].join('|');
}

String _relativeTimeLabel(DateTime value) {
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
