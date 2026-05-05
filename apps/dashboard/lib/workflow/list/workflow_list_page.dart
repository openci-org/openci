import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/build_logs/synced_spinner.dart';
import 'package:dashboard/firebase/data_connect_service_id_page.dart';
import 'package:dashboard/firebase/firebase_config_provider.dart';
import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/settings/settings_page.dart';
import 'package:dashboard/team/create_team_bottom_sheet.dart';
import 'package:dashboard/team/delete_team_bottom_sheet.dart';
import 'package:dashboard/team/edit_team_bottom_sheet.dart';
import 'package:dashboard/team/invite_team_member_bottom_sheet.dart';
import 'package:dashboard/team/switch_team_bottom_sheet.dart';
import 'package:dashboard/team/team_members_bottom_sheet.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/theme/app_colors.dart';
import 'package:dashboard/theme/theme_provider.dart';
import 'package:dashboard/users/user_provider.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:dashboard/utilities/function_error_message.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:dashboard/workflow/editor/initial_workflow_setup/github_connection_provider.dart';
import 'package:dashboard/workflow/list/select_repository_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

String getInitials(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  if (words.length >= 2) {
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }
  return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
}

class WorkflowListPage extends HookConsumerWidget {
  const WorkflowListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final selfHostedConfig = ref.watch(selfHostedConfigProvider).value;
    final showDataConnectSettings = useState(false);

    useEffect(() {
      showDataConnectSettings.value = false;
      if (!userAsync.isLoading || selfHostedConfig == null) return null;

      final timer = Timer(const Duration(seconds: 4), () {
        showDataConnectSettings.value = true;
      });
      return timer.cancel;
    }, [userAsync.isLoading, selfHostedConfig?.projectId]);

    return userAsync.when(
      loading: () {
        final config = selfHostedConfig;
        if (showDataConnectSettings.value && config != null) {
          return DataConnectServiceIdPage(
            config: config,
            title: 'Data Connect is still loading',
            message:
                'Check the Data Connect service ID for ${config.projectId}.',
          );
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator.adaptive()),
        );
      },
      error: (error, stackTrace) {
        final config = selfHostedConfig;
        if (config != null) {
          return DataConnectServiceIdPage(
            config: config,
            title: 'Data Connect failed to load',
            message:
                'Check the Data Connect service ID for ${config.projectId}.\n$error',
          );
        }
        return asyncErrorWidget(error, stackTrace);
      },
      data: (_) => const _IssuesFirstMockDashboard(),
    );
  }
}

class _IssuesFirstMockDashboard extends HookConsumerWidget {
  const _IssuesFirstMockDashboard();

  static const _mockTriageWeights = [1, 2, 4, 8, 16];

  static final _columns = [
    _MockIssueColumn(
      title: 'Triage',
      subtitle: '新着と要件確認',
      count: 50,
      accent: Color(0xFF6366F1),
      issues: [
        _MockIssue(
          number: 1715,
          title: 'このボードをメイン画面にする',
          repo: 'openci-org/openci',
          owner: 'AI agent',
          status: '設計中',
          weight: 8,
          checks: '2/3 checks',
          isRunning: true,
        ),
        _MockIssue(
          number: 1698,
          title: 'GitHub App 権限の説明を短くする',
          repo: 'openci-org/openci',
          owner: 'レビュー',
          status: '判断待ち',
          weight: 2,
          checks: '待機中',
        ),
        for (var index = 0; index < 48; index++)
          _MockIssue(
            number: 1800 + index,
            title: 'Triage mock task ${index + 1}',
            repo: 'openci-org/openci',
            owner: index.isEven ? 'AI agent' : 'Masa',
            status: '要確認',
            weight: _mockTriageWeights[index % _mockTriageWeights.length],
            checks: '未確認',
          ),
      ],
    ),
    _MockIssueColumn(
      title: 'Backlog',
      subtitle: '着手待ち',
      count: 5,
      accent: Color(0xFF0EA5E9),
      issues: [
        _MockIssue(
          number: 1709,
          title: 'worker のログを issue に紐づける',
          repo: 'openci-org/openci',
          owner: 'Masa',
          status: '次に着手',
          weight: 4,
          checks: '準備完了',
        ),
      ],
    ),
    _MockIssueColumn(
      title: 'In Progress',
      subtitle: '今やっていること',
      count: 3,
      accent: Color(0xFFF59E0B),
      issues: [
        _MockIssue(
          number: 1687,
          title: 'Issue から Cursor agent を起動する',
          repo: 'openci-org/openci',
          owner: 'AI agent',
          status: '実行中',
          weight: 16,
          checks: 'run #42',
          isRunning: true,
        ),
        _MockIssue(
          number: 1679,
          title: 'PR 作成後にボードステータスを更新する',
          repo: 'openci-org/openci',
          owner: 'Masa',
          status: '実装中',
          weight: 4,
          checks: '1件失敗',
        ),
      ],
    ),
    _MockIssueColumn(
      title: 'Review',
      subtitle: 'レビューと検証',
      count: 4,
      accent: Color(0xFFA855F7),
      issues: [
        _MockIssue(
          number: 1664,
          title: 'Secrets 設定画面の空状態を改善する',
          repo: 'openci-org/openci',
          owner: 'Masa',
          status: 'PR #221',
          weight: 2,
          checks: '成功',
          ciStatus: 'CI 成功',
          ciDetail: 'build, test, preview',
          ciState: _MockCiState.passing,
        ),
        _MockIssue(
          number: 1661,
          title: 'Workflow 一覧を issue から開く',
          repo: 'openci-org/openci',
          owner: 'AI agent',
          status: 'PR #219',
          weight: 4,
          checks: '実行中',
          ciStatus: 'CI 実行中',
          ciDetail: 'web build running',
          ciState: _MockCiState.inProgress,
        ),
        _MockIssue(
          number: 1658,
          title: 'Variables の権限チェックを追加する',
          repo: 'openci-org/openci',
          owner: 'Masa',
          status: 'PR #218',
          weight: 2,
          checks: 'キュー中',
          ciStatus: 'CI キュー中',
          ciDetail: 'worker 待ち',
          ciState: _MockCiState.queued,
        ),
        _MockIssue(
          number: 1655,
          title: 'Release preview のリンク切れを直す',
          repo: 'openci-org/openci',
          owner: 'AI agent',
          status: 'PR #217',
          weight: 1,
          checks: '失敗',
          ciStatus: 'CI 失敗',
          ciDetail: 'test-dashboard failed',
          ciState: _MockCiState.failure,
        ),
      ],
    ),
    _MockIssueColumn(
      title: 'Done',
      subtitle: '今週完了',
      count: 7,
      accent: Color(0xFF22C55E),
      issues: [
        _MockIssue(
          number: 1651,
          title: 'Firebase Data Connect のローディング改善',
          repo: 'openci-org/openci',
          owner: 'AI agent',
          status: 'マージ済み',
          weight: 4,
          checks: 'デプロイ済み',
        ),
      ],
    ),
  ];

  static const _quickLinks = [
    _MockQuickLink(
      title: '実行履歴',
      subtitle: 'CI runs、ログ、失敗した checks',
      metric: '3件実行中',
      icon: Icons.history_rounded,
    ),
    _MockQuickLink(
      title: 'Workflows',
      subtitle: '.openci YAML と triggers',
      metric: '8 files',
      icon: Icons.account_tree_outlined,
    ),
    _MockQuickLink(
      title: 'Variables',
      subtitle: '環境変数と secrets',
      metric: '12 keys',
      icon: Icons.key_outlined,
    ),
    _MockQuickLink(
      title: 'Store release',
      subtitle: 'リリースノートと配信',
      metric: '2 drafts',
      icon: Icons.rocket_launch_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team = ref.watch(teamStateProvider);
    final authUser = ref.watch(authProvider).value;
    final toolsExpanded = useState(false);
    final listViewEnabled = useState(false);
    final expandedMobileColumns = useState<Set<String>>({});
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompactScreen = screenWidth < 640;

    return SyncedSpinnerScope(
      child: Scaffold(
        backgroundColor: AppColors.of(context).scaffold,
        appBar: AppBar(
          titleSpacing: isCompactScreen ? 12 : 20,
          backgroundColor: AppColors.of(context).scaffold,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.of(context).accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.bolt_rounded,
                  color: AppColors.of(context).accentOnAccent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'OpenCI',
                  style: TextStyle(
                    color: AppColors.of(context).textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isCompactScreen) ...[
                const SizedBox(width: 10),
                _MockBadge(label: 'Issues first mock'),
              ],
            ],
          ),
          actions: [
            if (!isCompactScreen)
              Consumer(
                builder: (context, ref, _) {
                  final configAsync = ref.watch(selfHostedConfigProvider);
                  return configAsync.maybeWhen(
                    data: (config) {
                      if (config == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _MockBadge(
                          label: 'Self-hosted ${config.projectId}',
                        ),
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  );
                },
              ),
            Padding(
              padding: EdgeInsets.only(right: isCompactScreen ? 8 : 12),
              child: team.when(
                data: (teamData) => _TeamMenuButton(
                  teamName: teamData.name,
                  email: authUser?.email,
                  initials: getInitials(teamData.name),
                  membersCount: teamData.members.length,
                ),
                error: asyncErrorWidget,
                loading: () => const SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(child: CircularProgressIndicator.adaptive()),
                ),
              ),
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1080;
            final sidePanel = _MockCiSidePanel(
              links: _quickLinks,
              expanded: !wide || toolsExpanded.value,
              onToggle: wide
                  ? () => toolsExpanded.value = !toolsExpanded.value
                  : null,
            );
            final board = _MockIssueBoard(
              columns: _columns,
              listViewEnabled: listViewEnabled.value,
              onListViewChanged: (value) => listViewEnabled.value = value,
              expandedMobileColumns: expandedMobileColumns.value,
              onToggleMobileColumn: (title) {
                final next = {...expandedMobileColumns.value};
                if (!next.add(title)) {
                  next.remove(title);
                }
                expandedMobileColumns.value = next;
              },
            );

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                isCompactScreen ? 8 : 16,
                4,
                isCompactScreen ? 8 : 16,
                20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: board),
                        const SizedBox(width: 12),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          width: toolsExpanded.value ? 300 : 56,
                          child: sidePanel,
                        ),
                      ],
                    )
                  else ...[
                    board,
                    const SizedBox(height: 12),
                    sidePanel,
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MockDailyGoalGauge extends StatelessWidget {
  const _MockDailyGoalGauge({this.expand = false});

  final bool expand;

  @override
  Widget build(BuildContext context) {
    const completed = 14;
    const target = 20;
    const progress = completed / target;

    return SizedBox(
      width: expand ? double.infinity : 236,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.of(context).surfaceSecondary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.of(context).border),
        ),
        child: Row(
          children: [
            Icon(
              Icons.flag_rounded,
              color: AppColors.of(context).accent,
              size: 17,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '今日の目標',
                          style: TextStyle(
                            color: AppColors.of(context).textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '$completed / $target W',
                        style: TextStyle(
                          color: AppColors.of(context).textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: AppColors.of(context).border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.of(context).accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'あと 6W',
              style: TextStyle(
                color: AppColors.of(context).textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockIssueBoard extends StatelessWidget {
  const _MockIssueBoard({
    required this.columns,
    required this.listViewEnabled,
    required this.onListViewChanged,
    required this.expandedMobileColumns,
    required this.onToggleMobileColumn,
  });

  final List<_MockIssueColumn> columns;
  final bool listViewEnabled;
  final ValueChanged<bool> onListViewChanged;
  final Set<String> expandedMobileColumns;
  final ValueChanged<String> onToggleMobileColumn;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 560;
        final columnWidth = isCompact
            ? (constraints.maxWidth - 24).clamp(260.0, 340.0)
            : 250.0;

        return Container(
          padding: EdgeInsets.all(isCompact ? 10 : 12),
          decoration: BoxDecoration(
            color: AppColors.of(context).surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.of(context).border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(4, 0, 4, isCompact ? 8 : 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _MockDailyGoalGauge(expand: isCompact),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _MockBoardSettingsButton(
                      listViewEnabled: listViewEnabled,
                      onListViewChanged: onListViewChanged,
                      compact: isCompact,
                    ),
                  ],
                ),
              ),
              if (listViewEnabled)
                _MockIssueList(
                  columns: columns,
                  columnWidth: columnWidth,
                  stackColumns: isCompact,
                  expandedMobileColumns: expandedMobileColumns,
                  onToggleMobileColumn: onToggleMobileColumn,
                )
              else if (isCompact)
                Column(
                  children: [
                    for (final column in columns) ...[
                      _MockMobileColumn(
                        column: column,
                        expanded: expandedMobileColumns.contains(column.title),
                        onToggle: () => onToggleMobileColumn(column.title),
                      ),
                      if (column != columns.last) const SizedBox(height: 10),
                    ],
                  ],
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final column in columns) ...[
                        SizedBox(
                          width: columnWidth,
                          child: _MockIssueLane(column: column),
                        ),
                        if (column != columns.last) const SizedBox(width: 10),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MockBoardSettingsButton extends StatelessWidget {
  const _MockBoardSettingsButton({
    required this.listViewEnabled,
    required this.onListViewChanged,
    this.compact = false,
  });

  final bool listViewEnabled;
  final ValueChanged<bool> onListViewChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _showMenu(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 16,
              color: AppColors.of(context).textSecondary,
            ),
            if (!compact) ...[
              const SizedBox(width: 6),
              Text(
                'ボード設定',
                style: TextStyle(
                  color: AppColors.of(context).textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    final offset = box?.localToGlobal(Offset.zero) ?? Offset.zero;
    final size = box?.size ?? Size.zero;
    final screenWidth = MediaQuery.sizeOf(context).width;
    var currentListViewEnabled = listViewEnabled;

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (dialogContext) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(dialogContext).pop(),
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            top: offset.dy + size.height + 4,
            right: (screenWidth - offset.dx - size.width).clamp(8.0, 32.0),
            child: Material(
              elevation: 0,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              color: AppColors.of(context).surfaceHover,
              child: Container(
                width: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.of(context).border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: AppColors.of(context).surfaceTertiary,
                            ),
                            child: Icon(
                              Icons.tune_rounded,
                              size: 18,
                              color: AppColors.of(context).textPrimary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'ボード設定',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.of(context).textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: AppColors.of(context).divider),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: StatefulBuilder(
                        builder: (context, setMenuState) {
                          return _MockBoardSettingsMenuItem(
                            icon: currentListViewEnabled
                                ? Icons.view_column_outlined
                                : Icons.view_list_outlined,
                            label: '一覧表示',
                            value: currentListViewEnabled,
                            onTap: () {
                              setMenuState(() {
                                currentListViewEnabled =
                                    !currentListViewEnabled;
                              });
                              onListViewChanged(currentListViewEnabled);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MockBoardSettingsMenuItem extends StatelessWidget {
  const _MockBoardSettingsMenuItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      hoverColor: AppColors.of(context).divider,
      splashColor: AppColors.of(context).divider,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: AppColors.of(context).textPrimary.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.of(context).textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              width: 36,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: value
                    ? AppColors.of(context).accent
                    : AppColors.of(context).surfaceTertiary,
                border: Border.all(
                  color: value
                      ? AppColors.of(context).accent
                      : AppColors.of(context).border,
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockIssueList extends StatelessWidget {
  const _MockIssueList({
    required this.columns,
    required this.columnWidth,
    required this.stackColumns,
    required this.expandedMobileColumns,
    required this.onToggleMobileColumn,
  });

  final List<_MockIssueColumn> columns;
  final double columnWidth;
  final bool stackColumns;
  final Set<String> expandedMobileColumns;
  final ValueChanged<String> onToggleMobileColumn;

  @override
  Widget build(BuildContext context) {
    if (stackColumns) {
      return Column(
        children: [
          for (final column in columns) ...[
            SizedBox(
              width: double.infinity,
              child: _MockIssueListSection(
                column: column,
                collapsed: !expandedMobileColumns.contains(column.title),
                onToggle: () => onToggleMobileColumn(column.title),
              ),
            ),
            if (column != columns.last) const SizedBox(height: 10),
          ],
        ],
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final column in columns) ...[
            SizedBox(
              width: columnWidth,
              child: _MockIssueListSection(column: column),
            ),
            if (column != columns.last) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _MockIssueListSection extends StatelessWidget {
  const _MockIssueListSection({
    required this.column,
    this.collapsed = false,
    this.onToggle,
  });

  final _MockIssueColumn column;
  final bool collapsed;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.of(context).surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.of(context).borderSubtle),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 9),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: column.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      column.title,
                      style: TextStyle(
                        color: AppColors.of(context).textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _MockColumnSummary(column: column),
                  if (onToggle != null) ...[
                    const SizedBox(width: 4),
                    Icon(
                      collapsed
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_up_rounded,
                      size: 18,
                      color: AppColors.of(context).textTertiary,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (!collapsed) ...[
            Divider(height: 1, color: AppColors.of(context).border),
            for (final issue in column.issues) ...[
              _MockIssueListRow(issue: issue),
              if (issue != column.issues.last)
                Divider(
                  height: 1,
                  indent: 12,
                  endIndent: 12,
                  color: AppColors.of(context).border,
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _MockMobileColumn extends StatelessWidget {
  const _MockMobileColumn({
    required this.column,
    required this.expanded,
    required this.onToggle,
  });

  final _MockIssueColumn column;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    if (expanded) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.of(context).surfaceSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.of(context).borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MockMobileExpandedColumnHeader(
              column: column,
              onToggle: onToggle,
            ),
            const SizedBox(height: 10),
            for (final issue in column.issues) ...[
              _MockIssueCard(issue: issue, accent: column.accent),
              if (issue != column.issues.last) const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            _MockAddIssueHint(accent: column.accent),
          ],
        ),
      );
    }

    return _MockMobileColumnSummary(
      column: column,
      expanded: false,
      onToggle: onToggle,
    );
  }
}

class _MockMobileExpandedColumnHeader extends StatelessWidget {
  const _MockMobileExpandedColumnHeader({
    required this.column,
    required this.onToggle,
  });

  final _MockIssueColumn column;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: column.accent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    column.title,
                    style: TextStyle(
                      color: AppColors.of(context).textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    column.subtitle,
                    style: TextStyle(
                      color: AppColors.of(context).textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            _MockColumnSummary(column: column),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_up_rounded,
              size: 20,
              color: AppColors.of(context).textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _MockMobileColumnSummary extends StatelessWidget {
  const _MockMobileColumnSummary({
    required this.column,
    required this.expanded,
    required this.onToggle,
  });

  final _MockIssueColumn column;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.of(context).surfaceSecondary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.of(context).borderSubtle),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: column.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      column.title,
                      style: TextStyle(
                        color: AppColors.of(context).textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      column.subtitle,
                      style: TextStyle(
                        color: AppColors.of(context).textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _MockColumnSummary(column: column),
              const SizedBox(width: 4),
              Icon(
                expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: AppColors.of(context).textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MockColumnSummary extends StatelessWidget {
  const _MockColumnSummary({required this.column});

  final _MockIssueColumn column;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MockBadge(label: '${column.count}件'),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.of(context).accentSubtle,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.of(context).accent.withValues(alpha: 0.18),
            ),
          ),
          child: Text(
            'W${column.totalWeight}',
            style: TextStyle(
              color: AppColors.of(context).accent,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _MockIssueListRow extends StatelessWidget {
  const _MockIssueListRow({required this.issue});

  final _MockIssue issue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              issue.title,
              style: TextStyle(
                color: AppColors.of(context).textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          _MockIssueWeight(weight: issue.weight),
        ],
      ),
    );
  }
}

class _MockIssueLane extends StatelessWidget {
  const _MockIssueLane({required this.column});

  final _MockIssueColumn column;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.of(context).surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.of(context).borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: column.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  column.title,
                  style: TextStyle(
                    color: AppColors.of(context).textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _MockBadge(label: '${column.count}'),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            column.subtitle,
            style: TextStyle(
              color: AppColors.of(context).textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          for (final issue in column.issues) ...[
            _MockIssueCard(issue: issue, accent: column.accent),
            if (issue != column.issues.last) const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          _MockAddIssueHint(accent: column.accent),
        ],
      ),
    );
  }
}

class _MockAddIssueHint extends StatelessWidget {
  const _MockAddIssueHint({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.of(context).surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.of(context).border,
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.add_rounded,
                size: 16,
                color: accent,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Issueを追加',
                  style: TextStyle(
                    color: AppColors.of(context).textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _MockShortcutKey(label: '⌘T'),
            ],
          ),
        ),
      ),
    );
  }
}

class _MockShortcutKey extends StatelessWidget {
  const _MockShortcutKey({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.of(context).surfaceSecondary,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.of(context).border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.of(context).textTertiary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MockIssueCard extends StatelessWidget {
  const _MockIssueCard({required this.issue, required this.accent});

  final _MockIssue issue;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 3,
                color: accent.withValues(alpha: 0.9),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _MockIssueNumber(number: issue.number),
                          const SizedBox(width: 6),
                          _MockIssueWeight(weight: issue.weight),
                          const Spacer(),
                          if (issue.isRunning)
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: 15,
                              color: colors.accent,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        issue.title,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          height: 1.28,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.account_tree_outlined,
                            size: 12,
                            color: colors.textTertiary,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              issue.repo,
                              style: TextStyle(
                                color: colors.textTertiary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (issue.ciStatus != null) ...[
                        const SizedBox(height: 10),
                        _MockCiStatusRow(issue: issue),
                      ],
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

class _MockIssueNumber extends StatelessWidget {
  const _MockIssueNumber({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.of(context).surfaceSecondary,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.of(context).border),
      ),
      child: Text(
        '#$number',
        style: TextStyle(
          color: AppColors.of(context).textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MockIssueWeight extends StatelessWidget {
  const _MockIssueWeight({required this.weight});

  final int weight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.of(context).accentSubtle,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.of(context).accent.withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        'W$weight',
        style: TextStyle(
          color: AppColors.of(context).accent,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MockCiStatusRow extends StatelessWidget {
  const _MockCiStatusRow({required this.issue});

  final _MockIssue issue;

  @override
  Widget build(BuildContext context) {
    final state = issue.ciState ?? _MockCiState.passing;
    final backgroundColor = switch (state) {
      _MockCiState.passing => const Color(0xFFDCFCE7),
      _MockCiState.inProgress => const Color(
        0xFF1F6FEB,
      ).withValues(alpha: 0.12),
      _MockCiState.queued => const Color(0xFF6E40C9).withValues(alpha: 0.12),
      _MockCiState.failure => const Color(0xFFFEE2E2),
    };
    final borderColor = switch (state) {
      _MockCiState.passing => const Color(0xFFBBF7D0),
      _MockCiState.inProgress => const Color(
        0xFF1F6FEB,
      ).withValues(alpha: 0.25),
      _MockCiState.queued => const Color(0xFF6E40C9).withValues(alpha: 0.25),
      _MockCiState.failure => const Color(0xFFFECACA),
    };
    final iconColor = switch (state) {
      _MockCiState.passing => const Color(0xFF16A34A),
      _MockCiState.inProgress => const Color(0xFF1F6FEB),
      _MockCiState.queued => const Color(0xFF6E40C9),
      _MockCiState.failure => const Color(0xFFCF222E),
    };
    final textColor = switch (state) {
      _MockCiState.passing => const Color(0xFF166534),
      _MockCiState.inProgress => const Color(0xFF1F6FEB),
      _MockCiState.queued => const Color(0xFF6E40C9),
      _MockCiState.failure => const Color(0xFFCF222E),
    };
    final detailColor = switch (state) {
      _MockCiState.passing => const Color(0xFF15803D),
      _MockCiState.inProgress => const Color(0xFF1F6FEB).withValues(alpha: 0.8),
      _MockCiState.queued => const Color(0xFF6E40C9).withValues(alpha: 0.8),
      _MockCiState.failure => const Color(0xFFCF222E).withValues(alpha: 0.8),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          _MockCiStatusIcon(state: state, color: iconColor),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.ciStatus!,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (issue.ciDetail != null)
                  Text(
                    issue.ciDetail!,
                    style: TextStyle(
                      color: detailColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MockCiStatusIcon extends StatelessWidget {
  const _MockCiStatusIcon({
    required this.state,
    required this.color,
  });

  final _MockCiState state;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (state == _MockCiState.inProgress) {
      return SyncedSpinner(color: color, size: 10);
    }

    final icon = switch (state) {
      _MockCiState.passing => Icons.check_circle_rounded,
      _MockCiState.inProgress => Icons.help_outline_rounded,
      _MockCiState.queued => Icons.schedule_rounded,
      _MockCiState.failure => Icons.error_rounded,
    };

    return Icon(icon, size: 12, color: color);
  }
}

enum _MockCiState { passing, inProgress, queued, failure }

class _MockCiSidePanel extends StatelessWidget {
  const _MockCiSidePanel({
    required this.links,
    required this.expanded,
    required this.onToggle,
  });

  final List<_MockQuickLink> links;
  final bool expanded;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    if (!expanded) {
      return _MockCiToolRail(
        links: links,
        onExpand: onToggle,
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.of(context).surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.of(context).border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'ツール',
                      style: TextStyle(
                        color: AppColors.of(context).textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (onToggle != null)
                    _MockRailIconButton(
                      icon: Icons.chevron_right_rounded,
                      tooltip: 'ツールを閉じる',
                      onTap: onToggle!,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              for (final link in links) ...[
                _MockQuickLinkTile(link: link),
                if (link != links.last) const SizedBox(height: 7),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _MockActivityPanel(),
      ],
    );
  }
}

class _MockCiToolRail extends StatelessWidget {
  const _MockCiToolRail({
    required this.links,
    required this.onExpand,
  });

  final List<_MockQuickLink> links;
  final VoidCallback? onExpand;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.of(context).border),
      ),
      child: Column(
        children: [
          if (onExpand != null)
            _MockRailIconButton(
              icon: Icons.chevron_left_rounded,
              tooltip: 'ツールを開く',
              onTap: onExpand!,
            ),
          if (onExpand != null) const SizedBox(height: 8),
          for (final link in links) ...[
            _MockRailToolButton(link: link),
            if (link != links.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _MockRailToolButton extends StatelessWidget {
  const _MockRailToolButton({required this.link});

  final _MockQuickLink link;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${link.title} - ${link.metric}',
      waitDuration: const Duration(milliseconds: 250),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.of(context).surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.of(context).border),
            ),
            child: Icon(
              link.icon,
              color: AppColors.of(context).textSecondary,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _MockRailIconButton extends StatelessWidget {
  const _MockRailIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.of(context).borderSubtle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.of(context).border),
            ),
            child: Icon(
              icon,
              color: AppColors.of(context).textSecondary,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _MockQuickLinkTile extends StatelessWidget {
  const _MockQuickLinkTile({required this.link});

  final _MockQuickLink link;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.of(context).border),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.of(context).accentSubtle,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  link.icon,
                  color: AppColors.of(context).accent,
                  size: 16,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      link.title,
                      style: TextStyle(
                        color: AppColors.of(context).textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      link.subtitle,
                      style: TextStyle(
                        color: AppColors.of(context).textTertiary,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                link.metric,
                style: TextStyle(
                  color: AppColors.of(context).textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MockActivityPanel extends StatelessWidget {
  const _MockActivityPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.of(context).border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '最新状況',
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          const _MockActivityItem(
            title: 'Agent が PR #224 を作成',
            subtitle: '#1715 dashboard mock',
          ),
          const _MockActivityItem(
            title: 'web build の CI が失敗',
            subtitle: '生成済み localization が不足',
          ),
          const _MockActivityItem(
            title: 'Deploy preview が準備完了',
            subtitle: 'openci-dashboard-pr-221',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _MockActivityItem extends StatelessWidget {
  const _MockActivityItem({
    required this.title,
    required this.subtitle,
    this.isLast = false,
  });

  final String title;
  final String subtitle;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: AppColors.of(context).accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.of(context).textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.of(context).textTertiary,
                    fontSize: 12,
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

class _MockBadge extends StatelessWidget {
  const _MockBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.of(context).borderSubtle,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.of(context).border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.of(context).textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MockIssueColumn {
  const _MockIssueColumn({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.accent,
    required this.issues,
  });

  final String title;
  final String subtitle;
  final int count;
  final Color accent;
  final List<_MockIssue> issues;

  int get totalWeight =>
      issues.fold<int>(0, (total, issue) => total + issue.weight);
}

class _MockIssue {
  const _MockIssue({
    required this.number,
    required this.title,
    required this.repo,
    required this.owner,
    required this.status,
    required this.weight,
    required this.checks,
    this.isRunning = false,
    this.ciStatus,
    this.ciDetail,
    this.ciState,
  });

  final int number;
  final String title;
  final String repo;
  final String owner;
  final String status;
  final int weight;
  final String checks;
  final bool isRunning;
  final String? ciStatus;
  final String? ciDetail;
  final _MockCiState? ciState;
}

class _MockQuickLink {
  const _MockQuickLink({
    required this.title,
    required this.subtitle,
    required this.metric,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String metric;
  final IconData icon;
}

class ConnectGitHub extends ConsumerWidget {
  const ConnectGitHub({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final githubT = t.github;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.of(context).borderSubtle,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.of(context).divider,
                ),
              ),
              child: Center(
                child: FaIcon(
                  FontAwesomeIcons.github,
                  size: 32,
                  color: AppColors.of(context).textTertiary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              githubT.connectTitle,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.of(context).textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              githubT.connectDescription,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.of(context).textTertiary,
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () async {
                try {
                  await launchGitHubSetup(ref);
                } on FirebaseFunctionsException catch (e, s) {
                  final errorMessage = await FunctionErrorMessage.capture(
                    e,
                    stackTrace: s,
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    responsiveSnackBar(
                      context,
                      content: Text(errorMessage.message),
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: AppColors.of(context).divider,
                foregroundColor: AppColors.of(context).textPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: AppColors.of(context).border,
                  ),
                ),
              ),
              icon: FaIcon(
                FontAwesomeIcons.github,
                size: 16,
                color: AppColors.of(context).textPrimary,
              ),
              label: Text(
                githubT.connectButton,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SelectRepository extends StatelessWidget {
  const SelectRepository({super.key});

  @override
  Widget build(BuildContext context) {
    final wfT = t.workflow;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.of(context).borderSubtle,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.of(context).divider,
                ),
              ),
              child: Center(
                child: FaIcon(
                  FontAwesomeIcons.github,
                  size: 32,
                  color: AppColors.of(context).textTertiary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              wfT.selectRepo,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.of(context).textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              wfT.selectRepoHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.of(context).textTertiary,
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                backgroundColor: AppColors.of(context).scaffold,
                builder: (_) => const SelectRepositoryBottomSheet(),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.of(context).divider,
                foregroundColor: AppColors.of(context).textPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: AppColors.of(context).border,
                  ),
                ),
              ),
              icon: FaIcon(
                FontAwesomeIcons.github,
                size: 16,
                color: AppColors.of(context).textPrimary,
              ),
              label: Text(
                wfT.selectRepoButton,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamMenuButton extends StatelessWidget {
  const _TeamMenuButton({
    required this.teamName,
    required this.email,
    required this.initials,
    required this.membersCount,
  });

  final String teamName;
  final String? email;
  final String initials;
  final int membersCount;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      onTap: () => _showTeamMenu(context),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColors.of(context).surfaceHover,
          border: Border.all(
            color: AppColors.of(context).border,
          ),
        ),
        child: Center(
          child: Text(
            initials,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.of(context).textSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  void _showTeamMenu(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (dialogContext) => Stack(
        children: [
          // Dismiss barrier
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(dialogContext).pop(),
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),
          // Menu popup — dark surface, inset ring, no shadow
          Positioned(
            top: kToolbarHeight + MediaQuery.of(context).padding.top + 4,
            right: 8,
            child: Material(
              elevation: 0,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              color: AppColors.of(context).surfaceHover,
              child: Container(
                width: 256,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.of(context).border,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Header ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: AppColors.of(context).surfaceTertiary,
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.of(context).textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  teamName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.of(context).textPrimary,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (email != null) ...[
                                  const SizedBox(height: 1),
                                  Text(
                                    email!,
                                    style: TextStyle(
                                      color: AppColors.of(context).textTertiary,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Divider ──
                    Divider(
                      height: 1,
                      color: AppColors.of(context).divider,
                    ),

                    // ── Team section ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 6, 6, 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
                            child: Text(
                              'Team',
                              style: TextStyle(
                                color: AppColors.of(context).textTertiary,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          _MenuItem(
                            icon: Icons.group_outlined,
                            label: t.team.members,
                            onTap: () {
                              Navigator.of(dialogContext).pop();
                              showModalBottomSheet(
                                showDragHandle: true,
                                context: context,
                                builder: (_) => const TeamMembersBottomSheet(),
                              );
                            },
                          ),
                          _MenuItem(
                            icon: Icons.swap_horiz_rounded,
                            label: t.team.switchTeam,
                            onTap: () {
                              Navigator.of(dialogContext).pop();
                              showModalBottomSheet(
                                showDragHandle: true,
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => const SwitchTeamBottomSheet(),
                              );
                            },
                          ),
                          _MenuItem(
                            icon: Icons.edit_outlined,
                            label: t.team.editTeam,
                            onTap: () {
                              Navigator.of(dialogContext).pop();
                              showModalBottomSheet(
                                showDragHandle: true,
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => const EditTeamBottomSheet(),
                              );
                            },
                          ),
                          _MenuItem(
                            icon: Icons.person_add_outlined,
                            label: t.settings.inviteTeamMember,
                            onTap: () {
                              Navigator.of(dialogContext).pop();
                              showModalBottomSheet(
                                showDragHandle: true,
                                context: context,
                                isScrollControlled: true,
                                builder: (_) =>
                                    const InviteTeamMemberBottomSheet(),
                              );
                            },
                          ),
                          _MenuItem(
                            icon: Icons.group_add_outlined,
                            label: t.team.createTeam,
                            onTap: () {
                              Navigator.of(dialogContext).pop();
                              showModalBottomSheet(
                                showDragHandle: true,
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => const CreateTeamBottomSheet(),
                              );
                            },
                          ),
                          _MenuItem(
                            icon: Icons.delete_outline_rounded,
                            label: t.team.deleteTeam,
                            isDestructive: true,
                            onTap: () {
                              Navigator.of(dialogContext).pop();
                              showModalBottomSheet(
                                showDragHandle: true,
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => const DeleteTeamBottomSheet(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // ── Divider ──
                    Divider(
                      height: 1,
                      color: AppColors.of(context).divider,
                    ),

                    // ── Appearance & Settings section ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Theme toggle
                          Consumer(
                            builder: (ctx, ref, _) {
                              final mode = ref.watch(themeModeProvider);
                              final isDark = mode == ThemeMode.dark;
                              return InkWell(
                                onTap: () => ref
                                    .read(themeModeProvider.notifier)
                                    .toggle(),
                                borderRadius: BorderRadius.circular(8),
                                hoverColor: AppColors.of(context).divider,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 9,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isDark
                                            ? Icons.dark_mode_outlined
                                            : Icons.light_mode_outlined,
                                        size: 18,
                                        color: AppColors.of(
                                          context,
                                        ).textPrimary.withValues(alpha: 0.6),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          isDark ? 'Dark Mode' : 'Light Mode',
                                          style: TextStyle(
                                            color: AppColors.of(
                                              context,
                                            ).textPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 36,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          color: isDark
                                              ? AppColors.of(context).accent
                                              : AppColors.of(context).border,
                                        ),
                                        child: AnimatedAlign(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          curve: Curves.easeInOut,
                                          alignment: isDark
                                              ? Alignment.centerRight
                                              : Alignment.centerLeft,
                                          child: Container(
                                            width: 16,
                                            height: 16,
                                            margin: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColors.of(
                                                context,
                                              ).textPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          _MenuItem(
                            icon: Icons.settings_outlined,
                            label: t.nav.settings,
                            onTap: () {
                              Navigator.of(dialogContext).pop();
                              showModalBottomSheet(
                                showDragHandle: true,
                                context: context,
                                isScrollControlled: true,
                                builder: (sheetContext) => SizedBox(
                                  height:
                                      MediaQuery.of(sheetContext).size.height *
                                      0.85,
                                  child: const SettingsPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final itemColor = isDestructive
        ? Colors.red.withValues(alpha: 0.9)
        : AppColors.of(context).textPrimary;
    final hoverColor = isDestructive
        ? Colors.red.withValues(alpha: 0.08)
        : AppColors.of(context).divider;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      hoverColor: hoverColor,
      splashColor: hoverColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: itemColor.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: itemColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
