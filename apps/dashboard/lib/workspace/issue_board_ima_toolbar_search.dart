import 'package:flutter/material.dart';
import 'issue_board_ima_utils.dart';
import 'issue_board_ima_board_columns.dart';
import 'issue_board_ima_models.dart';
import 'issue_board_ima_app_shell.dart';
import 'issue_board_ima_overview.dart';

class DailyProgressHistoryRow extends StatelessWidget {
  const DailyProgressHistoryRow({
    super.key,
    required this.day,
    required this.targetWeight,
  });

  final DailyProgressHistoryDay day;
  final int targetWeight;

  @override
  Widget build(BuildContext context) {
    final progress = targetWeight <= 0
        ? 0.0
        : day.completedWeight / targetWeight;
    final cappedProgress = progress.clamp(0.0, 1.0).toDouble();
    final percent = (progress * 100).round();
    final achieved = day.completedWeight >= targetWeight && targetWeight > 0;
    final remainingWeight = targetWeight - day.completedWeight;
    final statusLabel = achieved
        ? day.completedWeight > targetWeight
              ? '+W${day.completedWeight - targetWeight}'
              : '達成'
        : day.completedWeight == 0
        ? '未着手'
        : '残り W$remainingWeight';
    final accentColor = achieved
        ? const Color(0xFF15803D)
        : day.completedWeight == 0
        ? const Color(0xFF94A3B8)
        : const Color(0xFF2563EB);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  dailyHistoryDateLabel(day.date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'W${day.completedWeight} / W$targetWeight',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 64,
                child: Text(
                  '${day.completedCount}件',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(
                width: 72,
                child: Text(
                  statusLabel,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const SizedBox(width: 82),
              Expanded(
                child: Text(
                  '午前 W${day.morningWeight} · 午後 W${day.afternoonWeight}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: cappedProgress,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
        ],
      ),
    );
  }
}

class BoardToolbar extends StatelessWidget {
  const BoardToolbar({
    super.key,
    required this.onConnectGitHub,
    required this.onSelectRepositories,
    required this.onImportIssues,
    required this.onSyncIssues,
    required this.onSearchIssues,
    required this.boardViewMode,
    required this.onBoardViewModeChanged,
    required this.githubLogin,
    required this.repoCount,
    required this.isBusy,
    required this.onRunsTap,
    required this.onWorkersTap,
    required this.onWorkflowsTap,
    required this.onVariablesTap,
    required this.onStoreReleaseTap,
    required this.onSettingsTap,
    this.showNavigationActions = true,
  });

  final VoidCallback onConnectGitHub;
  final VoidCallback onSelectRepositories;
  final VoidCallback onImportIssues;
  final VoidCallback onSyncIssues;
  final VoidCallback onSearchIssues;
  final BoardViewMode boardViewMode;
  final ValueChanged<BoardViewMode> onBoardViewModeChanged;
  final String? githubLogin;
  final int repoCount;
  final bool isBusy;
  final VoidCallback onRunsTap;
  final VoidCallback onWorkersTap;
  final VoidCallback onWorkflowsTap;
  final VoidCallback onVariablesTap;
  final VoidCallback onStoreReleaseTap;
  final VoidCallback onSettingsTap;
  final bool showNavigationActions;

  @override
  Widget build(BuildContext context) {
    final isConnected = githubLogin != null && githubLogin!.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < compactBoardBreakpoint) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (!isConnected)
                    FilledButton.icon(
                      onPressed: isBusy ? null : onConnectGitHub,
                      icon: const Icon(Icons.link_rounded, size: 16),
                      label: const Text('GitHub App接続'),
                    ),
                  if (isConnected) ...[
                    ToolbarChip(
                      icon: Icons.account_tree_outlined,
                      label: '$repoCount repo',
                      tooltip: 'GitHub repoを選択',
                      onPressed: isBusy ? null : onSelectRepositories,
                    ),
                    ToolbarChip(
                      icon: Icons.download_rounded,
                      label: '取り込み',
                      tooltip: 'GitHub issueを取り込む',
                      onPressed: isBusy ? null : onImportIssues,
                    ),
                    ToolbarChip(
                      icon: Icons.sync_outlined,
                      label: '同期',
                      tooltip: '未同期issueを同期',
                      onPressed: isBusy ? null : onSyncIssues,
                    ),
                  ],
                  ToolbarChip(
                    icon: Icons.search_outlined,
                    label: '検索',
                    tooltip: 'issueを検索 (⌘K)',
                    onPressed: onSearchIssues,
                  ),
                  BoardViewModeToggle(
                    value: boardViewMode,
                    onChanged: onBoardViewModeChanged,
                  ),
                  if (showNavigationActions) ...[
                    ToolbarChip(
                      icon: Icons.history_rounded,
                      label: 'CI/CDログ',
                      tooltip: 'CI/CD の実行ログを開く',
                      onPressed: onRunsTap,
                    ),
                    ToolbarChip(
                      icon: Icons.dns_outlined,
                      label: 'ワーカー',
                      tooltip: 'OpenCI worker の稼動状況を開く',
                      onPressed: onWorkersTap,
                    ),
                    ToolbarChip(
                      icon: Icons.schema_rounded,
                      label: 'CI/CD設定',
                      tooltip: 'CI/CD設定を開く',
                      onPressed: onWorkflowsTap,
                    ),
                    ToolbarChip(
                      icon: Icons.key_rounded,
                      label: 'シークレット',
                      tooltip: 'シークレット / 環境変数を開く',
                      onPressed: onVariablesTap,
                    ),
                    ToolbarChip(
                      icon: Icons.rocket_launch_outlined,
                      label: 'ストアリリース',
                      tooltip: 'ストアリリースを開く',
                      onPressed: onStoreReleaseTap,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class BoardViewModeToggle extends StatelessWidget {
  const BoardViewModeToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final BoardViewMode value;
  final ValueChanged<BoardViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final isOverview = value == BoardViewMode.overview;

    return Container(
      height: 34,
      padding: const EdgeInsets.only(left: 10, right: 4),
      decoration: BoxDecoration(
        color: isOverview ? const Color(0xFFEFF6FF) : Colors.white,
        border: Border.all(
          color: isOverview ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.grid_view_rounded,
            size: 15,
            color: isOverview
                ? const Color(0xFF2563EB)
                : const Color(0xFF64748B),
          ),
          const SizedBox(width: 6),
          Text(
            '全体ボード',
            style: TextStyle(
              color: isOverview
                  ? const Color(0xFF1D4ED8)
                  : const Color(0xFF475569),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          Transform.scale(
            scale: 0.76,
            child: Switch(
              value: isOverview,
              onChanged: (enabled) => onChanged(
                enabled ? BoardViewMode.overview : BoardViewMode.standard,
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

class CompactBoardViewModeButton extends StatelessWidget {
  const CompactBoardViewModeButton({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final BoardViewMode value;
  final ValueChanged<BoardViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final isOverview = value == BoardViewMode.overview;
    return Tooltip(
      message: '表示を切り替え',
      child: Semantics(
        label: '表示切り替え',
        value: isOverview ? '全体ボード' : '一覧表示',
        child: Container(
          height: 40,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CompactBoardViewModeSegment(
                icon: Icons.view_list_rounded,
                label: '一覧',
                selected: !isOverview,
                onTap: () => onChanged(BoardViewMode.standard),
              ),
              _CompactBoardViewModeSegment(
                icon: Icons.grid_view_rounded,
                label: '全体',
                selected: isOverview,
                onTap: () => onChanged(BoardViewMode.overview),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactBoardViewModeSegment extends StatelessWidget {
  const _CompactBoardViewModeSegment({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = selected
        ? const Color(0xFF1D4ED8)
        : const Color(0xFF64748B);

    return Material(
      color: selected ? const Color(0xFFEFF6FF) : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: selected ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: foregroundColor),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CompactBoardDrawer extends StatelessWidget {
  const CompactBoardDrawer({
    super.key,
    required this.isConnected,
    required this.isBusy,
    required this.repoCount,
    required this.onConnectGitHub,
    required this.onSelectRepositories,
    required this.onImportIssues,
    required this.onSyncIssues,
    required this.onSearchIssues,
    required this.workspaceName,
    required this.selectedDestination,
    required this.onIssueBoardTap,
    required this.onRunsTap,
    required this.onWorkersTap,
    required this.onWorkflowsTap,
    required this.onVariablesTap,
    required this.onStoreReleaseTap,
    required this.onSettingsTap,
  });

  final bool isConnected;
  final bool isBusy;
  final int repoCount;
  final VoidCallback onConnectGitHub;
  final VoidCallback onSelectRepositories;
  final VoidCallback onImportIssues;
  final VoidCallback onSyncIssues;
  final VoidCallback onSearchIssues;
  final String workspaceName;
  final CompactBoardDestination selectedDestination;
  final VoidCallback onIssueBoardTap;
  final VoidCallback onRunsTap;
  final VoidCallback onWorkersTap;
  final VoidCallback onWorkflowsTap;
  final VoidCallback onVariablesTap;
  final VoidCallback onStoreReleaseTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    void closeDrawer() => Navigator.of(context).pop();
    void runAfterClose(VoidCallback action) {
      closeDrawer();
      action();
    }

    return Drawer(
      backgroundColor: const Color(0xFFF8FAFC),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'OpenCI',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    workspaceName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isConnected ? '$repoCount repo connected' : 'GitHub未接続',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const _CompactDrawerSectionLabel('ナビゲーション'),
            _CompactDrawerTile(
              icon: Icons.view_kanban_outlined,
              label: 'ワークスペース',
              selected:
                  selectedDestination == CompactBoardDestination.issueBoard,
              onTap: () => runAfterClose(onIssueBoardTap),
            ),
            _CompactDrawerTile(
              icon: Icons.history_rounded,
              label: 'CI/CDログ',
              selected: selectedDestination == CompactBoardDestination.runs,
              onTap: () => runAfterClose(onRunsTap),
            ),
            _CompactDrawerTile(
              icon: Icons.dns_outlined,
              label: 'ワーカー',
              selected: selectedDestination == CompactBoardDestination.workers,
              onTap: () => runAfterClose(onWorkersTap),
            ),
            _CompactDrawerTile(
              icon: Icons.schema_rounded,
              label: 'CI/CD設定',
              selected:
                  selectedDestination == CompactBoardDestination.workflows,
              onTap: () => runAfterClose(onWorkflowsTap),
            ),
            _CompactDrawerTile(
              icon: Icons.key_rounded,
              label: 'シークレット',
              selected:
                  selectedDestination == CompactBoardDestination.variables,
              onTap: () => runAfterClose(onVariablesTap),
            ),
            _CompactDrawerTile(
              icon: Icons.rocket_launch_outlined,
              label: 'ストアリリース',
              selected:
                  selectedDestination == CompactBoardDestination.storeRelease,
              onTap: () => runAfterClose(onStoreReleaseTap),
            ),
            _CompactDrawerTile(
              icon: Icons.settings_outlined,
              label: '設定',
              selected: selectedDestination == CompactBoardDestination.settings,
              onTap: () => runAfterClose(onSettingsTap),
            ),
            const Divider(height: 24),
            const _CompactDrawerSectionLabel('GitHub'),
            if (!isConnected)
              _CompactDrawerTile(
                icon: Icons.link_rounded,
                label: 'GitHub App接続',
                enabled: !isBusy,
                onTap: () => runAfterClose(onConnectGitHub),
              ),
            _CompactDrawerTile(
              icon: Icons.account_tree_outlined,
              label: '$repoCount repo',
              enabled: !isBusy && isConnected,
              onTap: () => runAfterClose(onSelectRepositories),
            ),
            _CompactDrawerTile(
              icon: Icons.download_rounded,
              label: 'issue取り込み',
              enabled: !isBusy && isConnected,
              onTap: () => runAfterClose(onImportIssues),
            ),
            _CompactDrawerTile(
              icon: Icons.sync_outlined,
              label: '未同期を同期',
              enabled: !isBusy && isConnected,
              onTap: () => runAfterClose(onSyncIssues),
            ),
            const Divider(height: 24),
            const _CompactDrawerSectionLabel('操作'),
            _CompactDrawerTile(
              icon: Icons.search_outlined,
              label: 'issue検索',
              onTap: () => runAfterClose(onSearchIssues),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactDrawerSectionLabel extends StatelessWidget {
  const _CompactDrawerSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _CompactDrawerTile extends StatelessWidget {
  const _CompactDrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? const Color(0xFF2563EB)
        : enabled
        ? const Color(0xFF0F172A)
        : const Color(0xFFCBD5E1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListTile(
        enabled: enabled,
        selected: selected,
        selectedTileColor: const Color(0xFFEFF6FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(icon, color: color),
        title: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        onTap: enabled ? onTap : null,
      ),
    );
  }
}

class ToolbarChip extends StatelessWidget {
  const ToolbarChip({
    super.key,
    required this.icon,
    required this.label,
    this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final String? tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(999);
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: borderRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF475569)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (onPressed == null) {
      return chip;
    }

    return Tooltip(
      message: tooltip ?? label,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onPressed,
          child: chip,
        ),
      ),
    );
  }
}

class IssueSearchDialog extends StatefulWidget {
  const IssueSearchDialog({
    super.key,
    required this.columns,
    this.initialQuery = '',
  });

  final List<BoardColumn> columns;
  final String initialQuery;

  @override
  State<IssueSearchDialog> createState() => _IssueSearchDialogState();
}

class _IssueSearchDialogState extends State<IssueSearchDialog> {
  final _queryController = TextEditingController();
  String? _selectedIssueId;

  @override
  void initState() {
    super.initState();
    _queryController.text = widget.initialQuery;
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  List<_IssueSearchEntry> get _entries => [
    for (final column in widget.columns)
      for (final issue in visibleIssuesForColumn(column))
        _IssueSearchEntry(issue: issue, column: column),
  ];

  List<_IssueSearchEntry> get _filteredEntries {
    final tokens = _queryController.text
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList();
    if (tokens.isEmpty) {
      return _entries;
    }

    return [
      for (final entry in _entries)
        if (entry.matches(tokens)) entry,
    ];
  }

  _IssueSearchEntry? _selectedEntryFor(List<_IssueSearchEntry> entries) {
    if (entries.isEmpty) {
      return null;
    }

    final selectedIssueId = _selectedIssueId;
    if (selectedIssueId != null) {
      for (final entry in entries) {
        if (entry.issue.id == selectedIssueId) {
          return entry;
        }
      }
    }

    return entries.first;
  }

  void _select(_IssueSearchEntry entry) {
    setState(() => _selectedIssueId = entry.issue.id);
  }

  void _open(_IssueSearchEntry entry) {
    Navigator.of(context).pop(
      IssueSearchDialogResult(
        issueId: entry.issue.id,
        query: _queryController.text,
      ),
    );
  }

  void _selectFirstMatch() {
    final entries = _filteredEntries;
    if (entries.isEmpty) {
      return;
    }

    _open(_selectedEntryFor(entries) ?? entries.first);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isCompactDialog = screenSize.width < 560;
    final maxHeight = screenSize.height * (isCompactDialog ? 0.92 : 0.86);
    final dialogPadding = EdgeInsets.all(isCompactDialog ? 18 : 24);
    final dialogBorderRadius = BorderRadius.circular(isCompactDialog ? 22 : 28);
    final query = _queryController.text;
    final entries = _filteredEntries;
    final selectedEntry = _selectedEntryFor(entries);
    final usesSplitNavigator = screenSize.width >= 820;

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
        constraints: BoxConstraints(
          maxWidth: usesSplitNavigator ? 1040 : 720,
          maxHeight: maxHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: dialogPadding.copyWith(bottom: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Issueを検索',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'タイトル、repo、label、担当者で探せます。Enterで先頭のIssueを開きます。',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (!isCompactDialog && query.isEmpty)
                    const _IssueSearchShortcutPill(label: '⌘K'),
                  IconButton(
                    tooltip: '検索を閉じる',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: dialogPadding.copyWith(top: 18, bottom: 12),
              child: Column(
                children: [
                  TextField(
                    controller: _queryController,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                    onChanged: (_) => setState(() => _selectedIssueId = null),
                    onSubmitted: (_) => _selectFirstMatch(),
                    decoration: InputDecoration(
                      hintText: 'issueを検索...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF64748B),
                      ),
                      suffixIcon: query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: '検索をクリア',
                              onPressed: () {
                                _queryController.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF1D4ED8),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        '${entries.length}件',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                      const Spacer(),
                      const _IssueSearchShortcutPill(label: 'Enterで編集'),
                    ],
                  ),
                ],
              ),
            ),
            Flexible(
              child: entries.isEmpty
                  ? _IssueSearchEmptyState(hasQuery: query.isNotEmpty)
                  : usesSplitNavigator
                  ? Padding(
                      padding: EdgeInsets.fromLTRB(
                        dialogPadding.left,
                        0,
                        dialogPadding.right,
                        dialogPadding.bottom,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 360,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: entries.length,
                              itemBuilder: (context, index) {
                                final entry = entries[index];
                                return _IssueSearchResultTile(
                                  entry: entry,
                                  selected:
                                      entry.issue.id == selectedEntry?.issue.id,
                                  onTap: () => _select(entry),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _IssueSearchDetailPane(
                              entry: selectedEntry,
                              onOpen: selectedEntry == null
                                  ? null
                                  : () => _open(selectedEntry),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.fromLTRB(
                        dialogPadding.left,
                        0,
                        dialogPadding.right,
                        dialogPadding.bottom,
                      ),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return _IssueSearchResultTile(
                          entry: entry,
                          selected: false,
                          onTap: () => _open(entry),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IssueSearchShortcutPill extends StatelessWidget {
  const _IssueSearchShortcutPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _IssueSearchEmptyState extends StatelessWidget {
  const _IssueSearchEmptyState({required this.hasQuery});

  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: Color(0xFF94A3B8),
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            hasQuery ? '一致するIssueがありません' : '検索できるIssueがありません',
            style: const TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'タイトル、repo、label、担当者で探せます',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _IssueSearchResultTile extends StatelessWidget {
  const _IssueSearchResultTile({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final _IssueSearchEntry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final issue = entry.issue;
    final labels = issue.labels.take(3).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
          ),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: entry.column.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.radio_button_unchecked_rounded,
                    size: 16,
                    color: entry.column.color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        issue.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _IssueSearchMetaPill(label: issue.displayId),
                          _IssueSearchMetaPill(label: issue.repo),
                          _IssueSearchMetaPill(label: entry.column.title),
                          for (final label in labels)
                            _IssueSearchMetaPill(label: label),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Icon(
                    Icons.north_east_rounded,
                    size: 16,
                    color: Color(0xFFCBD5E1),
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

class _IssueSearchDetailPane extends StatelessWidget {
  const _IssueSearchDetailPane({required this.entry, required this.onOpen});

  final _IssueSearchEntry? entry;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final entry = this.entry;
    if (entry == null) {
      return const DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.all(Radius.circular(18)),
          border: Border.fromBorderSide(BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: Center(
          child: Text(
            'Issueを選択してください',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    final issue = entry.issue;
    final body = issue.body.trim();
    final labels = issue.labels.take(8).toList();
    final pullRequest = issue.pullRequests.isEmpty
        ? null
        : issue.pullRequests.last;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _IssueSearchMetaPill(label: issue.displayId),
                    _IssueSearchMetaPill(label: issue.repo),
                    _IssueSearchMetaPill(label: entry.column.title),
                    _IssueSearchMetaPill(
                      label: _issuePriorityLabel(issue.priority),
                    ),
                    if (issue.dueDate != null)
                      _IssueSearchMetaPill(label: formatDate(issue.dueDate!)),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  issue.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                if (labels.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final label in labels)
                        _IssueSearchMetaPill(label: label),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    body.isEmpty ? '本文はありません' : body,
                    style: TextStyle(
                      color: body.isEmpty
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF334155),
                      height: 1.5,
                      fontWeight: body.isEmpty ? FontWeight.w700 : null,
                    ),
                  ),
                  if (pullRequest != null) ...[
                    const SizedBox(height: 18),
                    _IssueSearchDetailCallout(
                      icon: Icons.account_tree_outlined,
                      title: 'Pull request',
                      value: '#${pullRequest.number} ${pullRequest.title}',
                    ),
                  ],
                  if (issue.subIssuesSummary != null) ...[
                    const SizedBox(height: 10),
                    _IssueSearchDetailCallout(
                      icon: Icons.checklist_rounded,
                      title: 'Sub-issues',
                      value:
                          '${issue.subIssuesSummary!.completed}/${issue.subIssuesSummary!.total} completed',
                    ),
                  ],
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                const Text(
                  'カード選択で詳細を切り替え',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('編集する'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueSearchDetailCallout extends StatelessWidget {
  const _IssueSearchDetailCallout({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2563EB)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _issuePriorityLabel(Priority priority) {
  switch (priority) {
    case Priority.high:
      return '優先度: 高';
    case Priority.medium:
      return '優先度: 中';
    case Priority.low:
      return '優先度: 低';
  }
}

class _IssueSearchMetaPill extends StatelessWidget {
  const _IssueSearchMetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _IssueSearchEntry {
  const _IssueSearchEntry({required this.issue, required this.column});

  final Issue issue;
  final BoardColumn column;

  bool matches(List<String> tokens) {
    final searchableText = [
      issue.id,
      issue.displayId,
      issue.issueKey ?? '',
      issue.repo,
      issue.title,
      issue.body,
      issue.priority.name,
      column.title,
      ...issue.labels,
      for (final pullRequest in issue.pullRequests) ...[
        '${pullRequest.number}',
        pullRequest.title,
        pullRequest.branch,
      ],
    ].join(' ').toLowerCase();

    return tokens.every(searchableText.contains);
  }
}

class IssueSearchDialogResult {
  const IssueSearchDialogResult({required this.issueId, required this.query});

  final String issueId;
  final String query;
}

class RepositoryPickerBottomSheet extends StatefulWidget {
  const RepositoryPickerBottomSheet({
    super.key,
    required this.initiallySelected,
    required this.loadRepositories,
  });

  final Set<String> initiallySelected;
  final Future<List<GitHubRepository>> Function() loadRepositories;

  @override
  State<RepositoryPickerBottomSheet> createState() =>
      _RepositoryPickerBottomSheetState();
}

class _RepositoryPickerBottomSheetState
    extends State<RepositoryPickerBottomSheet> {
  late final Set<String> _selected = {...widget.initiallySelected};
  late Future<List<GitHubRepository>> _repositoriesFuture;

  @override
  void initState() {
    super.initState();
    _repositoriesFuture = widget.loadRepositories();
  }

  void _retry() {
    final future = widget.loadRepositories();
    setState(() {
      _repositoriesFuture = future;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.78,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GitHub repoを選択',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  '同期するrepoを選んでください。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<GitHubRepository>>(
              future: _repositoriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const _RepositoryPickerLoading();
                }

                if (snapshot.hasError) {
                  return _RepositoryPickerError(onRetry: _retry);
                }

                final repositories = snapshot.data ?? const [];
                if (repositories.isEmpty) {
                  return const Center(child: Text('repoが見つかりませんでした。'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: repositories.length,
                  itemBuilder: (context, index) {
                    final repo = repositories[index];
                    final selected = _selected.contains(repo.fullName);

                    return CheckboxListTile(
                      value: selected,
                      title: Text(repo.fullName),
                      subtitle: Text(
                        '${repo.private ? '非公開' : '公開'} / ${repo.defaultBranch}',
                      ),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selected.add(repo.fullName);
                          } else {
                            _selected.remove(repo.fullName);
                          }
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('キャンセル'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(_selected.clear),
                    child: const Text('クリア'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(_selected),
                    child: Text('${_selected.length}件のrepoを保存'),
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

class _RepositoryPickerLoading extends StatelessWidget {
  const _RepositoryPickerLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('repoを読み込んでいます...'),
        ],
      ),
    );
  }
}

class _RepositoryPickerError extends StatelessWidget {
  const _RepositoryPickerError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: colorScheme.error,
              size: 32,
            ),
            const SizedBox(height: 12),
            const Text('repoの読み込みに失敗しました。'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('再読み込み'),
            ),
          ],
        ),
      ),
    );
  }
}
