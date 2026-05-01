import 'package:flutter/material.dart';

void main() {
  runApp(const IssueBoardApp());
}

class IssueBoardApp extends StatelessWidget {
  const IssueBoardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IssuePilot',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const IssueBoardPage(),
    );
  }
}

class IssueBoardPage extends StatefulWidget {
  const IssueBoardPage({super.key});

  @override
  State<IssueBoardPage> createState() => _IssueBoardPageState();
}

class _IssueBoardPageState extends State<IssueBoardPage> {
  final List<BoardColumn> _columns = [
    BoardColumn(
      id: 'triage',
      title: 'Triage',
      description: '新着と要件確認',
      color: const Color(0xFF6366F1),
      issues: [
        Issue(
          id: 'OPN-142',
          repo: 'openci/dashboard',
          title: 'GitHub Appのインストール状態を一目で見たい',
          assignee: 'MF',
          labels: ['feature', 'github'],
          comments: 8,
          priority: Priority.high,
        ),
        Issue(
          id: 'IMA-16',
          repo: 'openci/ima',
          title: 'iOSでも片手で列を切り替えやすくする',
          assignee: 'AK',
          labels: ['mobile'],
          comments: 3,
          priority: Priority.medium,
        ),
      ],
    ),
    BoardColumn(
      id: 'backlog',
      title: 'Backlog',
      description: '着手待ち',
      color: const Color(0xFF0EA5E9),
      issues: [
        Issue(
          id: 'CLI-88',
          repo: 'openci/worker_cli_node',
          title: 'act実行ログから失敗ステップだけを抽出する',
          assignee: 'YS',
          labels: ['worker', 'logs'],
          comments: 12,
          priority: Priority.high,
        ),
        Issue(
          id: 'OPS-54',
          repo: 'openci/firebase',
          title: '複数repo横断でmilestoneを同期する',
          assignee: 'MF',
          labels: ['sync', 'api'],
          comments: 5,
          priority: Priority.medium,
        ),
      ],
    ),
    BoardColumn(
      id: 'doing',
      title: 'In Progress',
      description: '今やっていること',
      color: const Color(0xFFF59E0B),
      issues: [
        Issue(
          id: 'IMA-21',
          repo: 'openci/ima',
          title: 'Kanbanカードのドラッグ&ドロップを検証する',
          assignee: 'MF',
          labels: ['prototype', 'flutter'],
          comments: 2,
          priority: Priority.high,
        ),
        Issue(
          id: 'DASH-33',
          repo: 'openci/dashboard',
          title: 'ProjectV2 itemのフィールド差分をキャッシュする',
          assignee: 'RN',
          labels: ['perf'],
          comments: 6,
          priority: Priority.low,
        ),
      ],
    ),
    BoardColumn(
      id: 'review',
      title: 'Review',
      description: 'レビューと検証',
      color: const Color(0xFFA855F7),
      issues: [
        Issue(
          id: 'WEB-19',
          repo: 'openci/landing_page',
          title: 'pricingページに個人開発者向けプランを追加する',
          assignee: 'MM',
          labels: ['copy'],
          comments: 4,
          priority: Priority.medium,
        ),
      ],
    ),
    BoardColumn(
      id: 'done',
      title: 'Done',
      description: '今週完了',
      color: const Color(0xFF22C55E),
      issues: [
        Issue(
          id: 'AUTH-27',
          repo: 'openci/firebase',
          title: 'GitHub OAuthの権限説明を見直す',
          assignee: 'MF',
          labels: ['auth', 'docs'],
          comments: 1,
          priority: Priority.low,
        ),
      ],
    ),
  ];

  void _moveIssue({
    required String issueId,
    required String targetColumnId,
    required int targetIndex,
  }) {
    final sourceColumn = _columns.firstWhere(
      (column) => column.issues.any((issue) => issue.id == issueId),
    );
    final sourceIndex = sourceColumn.issues.indexWhere(
      (issue) => issue.id == issueId,
    );
    final targetColumn = _columns.firstWhere(
      (column) => column.id == targetColumnId,
    );

    if (sourceColumn.id == targetColumnId && sourceIndex == targetIndex) {
      return;
    }

    setState(() {
      final issue = sourceColumn.issues.removeAt(sourceIndex);
      var insertIndex = targetIndex;

      if (sourceColumn.id == targetColumnId && sourceIndex < targetIndex) {
        insertIndex -= 1;
      }

      targetColumn.issues.insert(
        insertIndex.clamp(0, targetColumn.issues.length),
        issue,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalIssues = _columns.fold<int>(
      0,
      (count, column) => count + column.issues.length,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            BoardHeader(totalIssues: totalIssues),
            const BoardToolbar(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final boardHeight = constraints.maxHeight > 32
                      ? constraints.maxHeight - 32
                      : constraints.maxHeight;

                  return Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        height: boardHeight,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final column in _columns) ...[
                              BoardColumnView(
                                column: column,
                                onIssueDropped: _moveIssue,
                              ),
                              const SizedBox(width: 16),
                            ],
                          ],
                        ),
                      ),
                    ),
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

class BoardHeader extends StatelessWidget {
  const BoardHeader({super.key, required this.totalIssues});

  final int totalIssues;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'IssuePilot',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '複数repoのGitHub Issuesを同期して、macOSとiOSで軽く扱うためのKanbanプロトタイプ。',
                  style: textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          IssueCountBadge(totalIssues: totalIssues),
        ],
      ),
    );
  }
}

class IssueCountBadge extends StatelessWidget {
  const IssueCountBadge({super.key, required this.totalIssues});

  final int totalIssues;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$totalIssues',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const Text(
            'open issues',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class BoardToolbar extends StatelessWidget {
  const BoardToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: const [
          ToolbarChip(icon: Icons.account_tree_outlined, label: '10 repos'),
          ToolbarChip(icon: Icons.sync_outlined, label: 'Synced 2m ago'),
          ToolbarChip(icon: Icons.filter_alt_outlined, label: 'All priorities'),
          ToolbarChip(icon: Icons.search_outlined, label: 'Search issues'),
        ],
      ),
    );
  }
}

class ToolbarChip extends StatelessWidget {
  const ToolbarChip({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF475569)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class BoardColumnView extends StatelessWidget {
  const BoardColumnView({
    super.key,
    required this.column,
    required this.onIssueDropped,
  });

  final BoardColumn column;
  final IssueDropCallback onIssueDropped;

  @override
  Widget build(BuildContext context) {
    return DragTarget<IssueDragData>(
      onWillAcceptWithDetails: (details) =>
          details.data.sourceColumnId != column.id,
      onAcceptWithDetails: (details) {
        onIssueDropped(
          issueId: details.data.issueId,
          targetColumnId: column.id,
          targetIndex: column.issues.length,
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 310,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isHovering
                ? column.color.withValues(alpha: 0.08)
                : Colors.white,
            border: Border.all(
              color: isHovering
                  ? column.color.withValues(alpha: 0.45)
                  : const Color(0xFFE2E8F0),
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ColumnHeader(column: column),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    for (
                      var index = 0;
                      index < column.issues.length;
                      index++
                    ) ...[
                      IssueDropSlot(
                        columnId: column.id,
                        index: index,
                        onIssueDropped: onIssueDropped,
                      ),
                      IssueCardDraggable(
                        issue: column.issues[index],
                        sourceColumnId: column.id,
                      ),
                      const SizedBox(height: 10),
                    ],
                    IssueDropSlot(
                      columnId: column.id,
                      index: column.issues.length,
                      onIssueDropped: onIssueDropped,
                      isLast: true,
                    ),
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

class ColumnHeader extends StatelessWidget {
  const ColumnHeader({super.key, required this.column});

  final BoardColumn column;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 38,
          decoration: BoxDecoration(
            color: column.color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      column.title,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CountPill(count: column.issues.length),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                column.description,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CountPill extends StatelessWidget {
  const CountPill({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Color(0xFF475569),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class IssueDropSlot extends StatelessWidget {
  const IssueDropSlot({
    super.key,
    required this.columnId,
    required this.index,
    required this.onIssueDropped,
    this.isLast = false,
  });

  final String columnId;
  final int index;
  final IssueDropCallback onIssueDropped;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return DragTarget<IssueDragData>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) {
        onIssueDropped(
          issueId: details.data.issueId,
          targetColumnId: columnId,
          targetIndex: index,
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: isHovering ? 42 : (isLast ? 54 : 6),
          margin: EdgeInsets.only(bottom: isLast ? 0 : 4),
          decoration: BoxDecoration(
            color: isHovering ? const Color(0xFFE0F2FE) : Colors.transparent,
            border: Border.all(
              color: isHovering ? const Color(0xFF38BDF8) : Colors.transparent,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: isHovering
              ? const Text(
                  'ここに移動',
                  style: TextStyle(
                    color: Color(0xFF0369A1),
                    fontWeight: FontWeight.w700,
                  ),
                )
              : null,
        );
      },
    );
  }
}

class IssueCardDraggable extends StatelessWidget {
  const IssueCardDraggable({
    super.key,
    required this.issue,
    required this.sourceColumnId,
  });

  final Issue issue;
  final String sourceColumnId;

  @override
  Widget build(BuildContext context) {
    return Draggable<IssueDragData>(
      data: IssueDragData(issueId: issue.id, sourceColumnId: sourceColumnId),
      hitTestBehavior: HitTestBehavior.opaque,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 290,
          child: Transform.rotate(
            angle: -0.035,
            child: IssueCard(issue: issue, isDragging: true),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: IssueCard(issue: issue)),
      child: IssueCard(issue: issue),
    );
  }
}

class IssueCard extends StatelessWidget {
  const IssueCard({super.key, required this.issue, this.isDragging = false});

  final Issue issue;
  final bool isDragging;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDragging ? 0.16 : 0.04),
            blurRadius: isDragging ? 22 : 10,
            offset: Offset(0, isDragging ? 12 : 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RepoBadge(repo: issue.repo),
              const Spacer(),
              PriorityDot(priority: issue.priority),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            issue.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final label in issue.labels) LabelPill(label: label),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFFDBEAFE),
                child: Text(
                  issue.assignee,
                  style: const TextStyle(
                    color: Color(0xFF1D4ED8),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                issue.id,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 16,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(width: 4),
              Text(
                '${issue.comments}',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RepoBadge extends StatelessWidget {
  const RepoBadge({super.key, required this.repo});

  final String repo;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          repo,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF475569),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class LabelPill extends StatelessWidget {
  const LabelPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF475569),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class PriorityDot extends StatelessWidget {
  const PriorityDot({super.key, required this.priority});

  final Priority priority;

  Color get color {
    switch (priority) {
      case Priority.high:
        return const Color(0xFFEF4444);
      case Priority.medium:
        return const Color(0xFFF59E0B);
      case Priority.low:
        return const Color(0xFF22C55E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${priority.name} priority',
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

typedef IssueDropCallback =
    void Function({
      required String issueId,
      required String targetColumnId,
      required int targetIndex,
    });

class IssueDragData {
  const IssueDragData({required this.issueId, required this.sourceColumnId});

  final String issueId;
  final String sourceColumnId;
}

class BoardColumn {
  BoardColumn({
    required this.id,
    required this.title,
    required this.description,
    required this.color,
    required this.issues,
  });

  final String id;
  final String title;
  final String description;
  final Color color;
  final List<Issue> issues;
}

class Issue {
  const Issue({
    required this.id,
    required this.repo,
    required this.title,
    required this.assignee,
    required this.labels,
    required this.comments,
    required this.priority,
  });

  final String id;
  final String repo;
  final String title;
  final String assignee;
  final List<String> labels;
  final int comments;
  final Priority priority;
}

enum Priority { high, medium, low }
