import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
      locale: const Locale('ja', 'JP'),
      supportedLocales: const [Locale('ja', 'JP')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
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
  final _boardScrollController = ScrollController();
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
          dueDate: DateTime.now().add(const Duration(days: 2)),
        ),
        Issue(
          id: 'IMA-16',
          repo: 'openci/ima',
          title: 'iOSでも片手で列を切り替えやすくする',
          assignee: 'AK',
          labels: ['mobile'],
          comments: 3,
          priority: Priority.medium,
          dueDate: DateTime.now().add(const Duration(days: 7)),
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
          dueDate: DateTime.now().subtract(const Duration(days: 1)),
        ),
        Issue(
          id: 'OPS-54',
          repo: 'openci/firebase',
          title: '複数repo横断でmilestoneを同期する',
          assignee: 'MF',
          labels: ['sync', 'api'],
          comments: 5,
          priority: Priority.medium,
          dueDate: DateTime.now().add(const Duration(days: 12)),
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
          dueDate: DateTime.now(),
        ),
        Issue(
          id: 'DASH-33',
          repo: 'openci/dashboard',
          title: 'ProjectV2 itemのフィールド差分をキャッシュする',
          assignee: 'RN',
          labels: ['perf'],
          comments: 6,
          priority: Priority.low,
          dueDate: DateTime.now().add(const Duration(days: 4)),
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
          dueDate: DateTime.now().add(const Duration(days: 5)),
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

  Future<void> _openAddIssueDialog() async {
    final draft = await showDialog<NewIssueDraft>(
      context: context,
      builder: (context) => AddIssueDialog(columns: _columns),
    );

    if (draft == null) {
      return;
    }

    _addIssue(draft);
    _showSavedSnackBar();
  }

  Future<void> _openEditIssueDialog(String issueId) async {
    final sourceColumn = _columns.firstWhere(
      (column) => column.issues.any((issue) => issue.id == issueId),
    );
    final issue = sourceColumn.issues.firstWhere(
      (issue) => issue.id == issueId,
    );

    final draft = await showDialog<NewIssueDraft>(
      context: context,
      builder: (context) => AddIssueDialog(
        columns: _columns,
        initialIssue: issue,
        initialColumnId: sourceColumn.id,
      ),
    );

    if (draft == null) {
      return;
    }

    _updateIssue(issueId: issueId, draft: draft);
    _showSavedSnackBar();
  }

  void _addIssue(NewIssueDraft draft) {
    final targetColumn = _columns.firstWhere(
      (column) => column.id == draft.columnId,
    );

    setState(() {
      targetColumn.issues.insert(
        0,
        Issue(
          id: _nextIssueId(),
          repo: draft.repo,
          title: draft.title,
          body: draft.body,
          assignee: draft.assignee,
          labels: draft.labels,
          comments: 0,
          priority: draft.priority,
          dueDate: draft.dueDate,
        ),
      );
    });
  }

  void _updateIssue({required String issueId, required NewIssueDraft draft}) {
    final sourceColumn = _columns.firstWhere(
      (column) => column.issues.any((issue) => issue.id == issueId),
    );
    final sourceIndex = sourceColumn.issues.indexWhere(
      (issue) => issue.id == issueId,
    );
    final targetColumn = _columns.firstWhere(
      (column) => column.id == draft.columnId,
    );

    setState(() {
      final currentIssue = sourceColumn.issues[sourceIndex];
      final updatedIssue = Issue(
        id: currentIssue.id,
        repo: draft.repo,
        title: draft.title,
        body: draft.body,
        assignee: draft.assignee,
        labels: draft.labels,
        comments: currentIssue.comments,
        priority: draft.priority,
        dueDate: draft.dueDate,
      );

      if (sourceColumn.id == targetColumn.id) {
        sourceColumn.issues[sourceIndex] = updatedIssue;
        return;
      }

      sourceColumn.issues.removeAt(sourceIndex);
      targetColumn.issues.insert(0, updatedIssue);
    });
  }

  String _nextIssueId() {
    final totalIssues = _columns.fold<int>(
      0,
      (count, column) => count + column.issues.length,
    );

    return 'IMA-${100 + totalIssues + 1}';
  }

  void _showSavedSnackBar() {
    if (!mounted) {
      return;
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final snackBarWidth = screenWidth < 420 ? screenWidth - 32 : 320.0;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          width: snackBarWidth,
          content: const Text('Saved'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1400),
        ),
      );
  }

  @override
  void dispose() {
    _boardScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalIssues = _columns.fold<int>(
      0,
      (count, column) => count + column.issues.length,
    );

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyT, meta: true):
            _openAddIssueDialog,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SafeArea(
            child: Column(
              children: [
                BoardHeader(totalIssues: totalIssues),
                BoardToolbar(onAddIssue: _openAddIssueDialog),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final boardHeight = constraints.maxHeight > 32
                          ? constraints.maxHeight - 32
                          : constraints.maxHeight;

                      return Scrollbar(
                        controller: _boardScrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _boardScrollController,
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
                                    onIssueTapped: _openEditIssueDialog,
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
  const BoardToolbar({super.key, required this.onAddIssue});

  final VoidCallback onAddIssue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          AddIssueButton(onPressed: onAddIssue),
          const ToolbarChip(
            icon: Icons.account_tree_outlined,
            label: '10 repos',
          ),
          const ToolbarChip(icon: Icons.sync_outlined, label: 'Synced 2m ago'),
          const ToolbarChip(
            icon: Icons.filter_alt_outlined,
            label: 'All priorities',
          ),
          const ToolbarChip(
            icon: Icons.search_outlined,
            label: 'Search issues',
          ),
        ],
      ),
    );
  }
}

class AddIssueButton extends StatelessWidget {
  const AddIssueButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text('New issue  ⌘T'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
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

class AddIssueDialog extends StatefulWidget {
  const AddIssueDialog({
    super.key,
    required this.columns,
    this.initialIssue,
    this.initialColumnId,
  });

  final List<BoardColumn> columns;
  final Issue? initialIssue;
  final String? initialColumnId;

  @override
  State<AddIssueDialog> createState() => _AddIssueDialogState();
}

class _AddIssueDialogState extends State<AddIssueDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _repoController = TextEditingController(text: 'openci/ima');
  final _assigneeController = TextEditingController(text: 'MF');
  final _labelsController = TextEditingController(text: 'feature, mobile');
  late String _selectedColumnId;
  Priority _priority = Priority.medium;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    final issue = widget.initialIssue;

    _selectedColumnId = widget.initialColumnId ?? widget.columns.first.id;

    if (issue != null) {
      _titleController.text = issue.title;
      _bodyController.text = issue.body;
      _repoController.text = issue.repo;
      _assigneeController.text = issue.assignee;
      _labelsController.text = issue.labels.join(', ');
      _priority = issue.priority;
      _dueDate = issue.dueDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _repoController.dispose();
    _assigneeController.dispose();
    _labelsController.dispose();
    super.dispose();
  }

  void _saveIssue() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final labels = _labelsController.text
        .split(',')
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toList();

    Navigator.of(context).pop(
      NewIssueDraft(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        repo: _repoController.text.trim(),
        assignee: _assigneeController.text.trim(),
        labels: labels,
        columnId: _selectedColumnId,
        priority: _priority,
        dueDate: _dueDate,
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final initialDate = _dueDate ?? now;
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );

    if (selectedDate == null) {
      return;
    }

    setState(() => _dueDate = _dateOnly(selectedDate));
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.86;
    final isEditing = widget.initialIssue != null;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _saveIssue,
      },
      child: Focus(
        autofocus: true,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 720, maxHeight: maxHeight),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Material(
                color: Colors.white,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DialogHeader(
                          title: isEditing
                              ? 'Edit GitHub issue'
                              : 'New GitHub issue',
                          description: isEditing
                              ? '${widget.initialIssue!.id}を編集します。⌘Enterで保存できます。'
                              : '同期前提のmock ticketをボードへ追加します。⌘Tで開いて、⌘Enterで保存できます。',
                        ),
                        const SizedBox(height: 20),
                        _TitleField(
                          controller: _titleController,
                          decoration: _inputDecoration(
                            label: 'Title',
                            hint: '例: issueの同期ステータスを表示する',
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _bodyController,
                          minLines: 7,
                          maxLines: 12,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          decoration: _inputDecoration(
                            label: 'Body',
                            hint: '背景、やりたいこと、受け入れ条件などをMarkdownっぽく書けます。',
                          ),
                        ),
                        const SizedBox(height: 14),
                        _RepoAndAssigneeFields(
                          repoController: _repoController,
                          assigneeController: _assigneeController,
                          decorationBuilder: _inputDecoration,
                        ),
                        const SizedBox(height: 14),
                        _StatusAndPriorityFields(
                          columns: widget.columns,
                          selectedColumnId: _selectedColumnId,
                          priority: _priority,
                          decorationBuilder: _inputDecoration,
                          priorityLabelBuilder: _priorityLabel,
                          onColumnChanged: (value) {
                            setState(() => _selectedColumnId = value);
                          },
                          onPriorityChanged: (value) {
                            setState(() => _priority = value);
                          },
                        ),
                        const SizedBox(height: 14),
                        DueDateField(
                          dueDate: _dueDate,
                          onPick: _pickDueDate,
                          onClear: () => setState(() => _dueDate = null),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _labelsController,
                          textInputAction: TextInputAction.done,
                          decoration: _inputDecoration(
                            label: 'Labels',
                            hint: 'feature, github, mobile',
                          ),
                          onFieldSubmitted: (_) => _saveIssue(),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _saveIssue,
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: Text(
                                  isEditing
                                      ? 'Save changes  ⌘Enter'
                                      : 'Add issue  ⌘Enter',
                                ),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String label, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
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
    );
  }

  String _priorityLabel(Priority priority) {
    switch (priority) {
      case Priority.high:
        return 'High';
      case Priority.medium:
        return 'Medium';
      case Priority.low:
        return 'Low';
    }
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}

class _TitleField extends StatelessWidget {
  const _TitleField({required this.controller, required this.decoration});

  final TextEditingController controller;
  final InputDecoration decoration;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: true,
      textInputAction: TextInputAction.next,
      decoration: decoration,
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'タイトルを入力してください' : null,
    );
  }
}

class _RepoAndAssigneeFields extends StatelessWidget {
  const _RepoAndAssigneeFields({
    required this.repoController,
    required this.assigneeController,
    required this.decorationBuilder,
  });

  final TextEditingController repoController;
  final TextEditingController assigneeController;
  final InputDecoration Function({required String label, String? hint})
  decorationBuilder;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: repoController,
            textInputAction: TextInputAction.next,
            decoration: decorationBuilder(
              label: 'Repository',
              hint: 'owner/repo',
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'repoを入力してください' : null,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 170,
          child: TextFormField(
            controller: assigneeController,
            textInputAction: TextInputAction.next,
            decoration: decorationBuilder(label: 'Assignee', hint: 'MF'),
            validator: (value) =>
                value == null || value.trim().isEmpty ? '担当者を入力してください' : null,
          ),
        ),
      ],
    );
  }
}

class _StatusAndPriorityFields extends StatelessWidget {
  const _StatusAndPriorityFields({
    required this.columns,
    required this.selectedColumnId,
    required this.priority,
    required this.decorationBuilder,
    required this.priorityLabelBuilder,
    required this.onColumnChanged,
    required this.onPriorityChanged,
  });

  final List<BoardColumn> columns;
  final String selectedColumnId;
  final Priority priority;
  final InputDecoration Function({required String label, String? hint})
  decorationBuilder;
  final String Function(Priority priority) priorityLabelBuilder;
  final ValueChanged<String> onColumnChanged;
  final ValueChanged<Priority> onPriorityChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: selectedColumnId,
            decoration: decorationBuilder(label: 'Status'),
            items: [
              for (final column in columns)
                DropdownMenuItem(value: column.id, child: Text(column.title)),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }

              onColumnChanged(value);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<Priority>(
            initialValue: priority,
            decoration: decorationBuilder(label: 'Priority'),
            items: [
              for (final priority in Priority.values)
                DropdownMenuItem(
                  value: priority,
                  child: Text(priorityLabelBuilder(priority)),
                ),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }

              onPriorityChanged(value);
            },
          ),
        ),
      ],
    );
  }
}

class DueDateField extends StatelessWidget {
  const DueDateField({
    super.key,
    required this.dueDate,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? dueDate;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: '締切',
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
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 18,
            color: Color(0xFF64748B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              dueDate == null ? '締切なし' : _formatDate(dueDate!),
              style: const TextStyle(
                color: Color(0xFF334155),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(onPressed: onPick, child: const Text('日付を選択')),
          if (dueDate != null)
            IconButton(
              tooltip: '締切をクリア',
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded, size: 18),
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
    required this.onIssueTapped,
  });

  final BoardColumn column;
  final IssueDropCallback onIssueDropped;
  final ValueChanged<String> onIssueTapped;

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
                      IssueCardDropTarget(
                        issue: column.issues[index],
                        sourceColumnId: column.id,
                        index: index,
                        onTap: () => onIssueTapped(column.issues[index].id),
                        onIssueDropped: onIssueDropped,
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

class IssueCardDropTarget extends StatefulWidget {
  const IssueCardDropTarget({
    super.key,
    required this.issue,
    required this.sourceColumnId,
    required this.index,
    required this.onTap,
    required this.onIssueDropped,
  });

  final Issue issue;
  final String sourceColumnId;
  final int index;
  final VoidCallback onTap;
  final IssueDropCallback onIssueDropped;

  @override
  State<IssueCardDropTarget> createState() => _IssueCardDropTargetState();
}

class _IssueCardDropTargetState extends State<IssueCardDropTarget> {
  final _cardKey = GlobalKey();
  bool _isHovering = false;
  bool _insertAfter = false;

  void _updateDropPosition(Offset globalPosition) {
    final renderObject = _cardKey.currentContext?.findRenderObject();

    if (renderObject is! RenderBox) {
      return;
    }

    final localPosition = renderObject.globalToLocal(globalPosition);
    final nextInsertAfter = localPosition.dy > renderObject.size.height / 2;

    if (_isHovering == true && _insertAfter == nextInsertAfter) {
      return;
    }

    setState(() {
      _isHovering = true;
      _insertAfter = nextInsertAfter;
    });
  }

  void _clearDropPosition() {
    if (!_isHovering) {
      return;
    }

    setState(() => _isHovering = false);
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<IssueDragData>(
      onWillAcceptWithDetails: (details) {
        _updateDropPosition(details.offset);
        return true;
      },
      onMove: (details) => _updateDropPosition(details.offset),
      onLeave: (_) => _clearDropPosition(),
      onAcceptWithDetails: (details) {
        widget.onIssueDropped(
          issueId: details.data.issueId,
          targetColumnId: widget.sourceColumnId,
          targetIndex: widget.index + (_insertAfter ? 1 : 0),
        );
        _clearDropPosition();
      },
      builder: (context, candidateData, rejectedData) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            KeyedSubtree(
              key: _cardKey,
              child: IssueCardDraggable(
                issue: widget.issue,
                sourceColumnId: widget.sourceColumnId,
                onTap: widget.onTap,
              ),
            ),
            if (_isHovering)
              Positioned(
                left: 10,
                right: 10,
                top: _insertAfter ? null : -3,
                bottom: _insertAfter ? -3 : null,
                child: const DropIndicator(),
              ),
          ],
        );
      },
    );
  }
}

class DropIndicator extends StatelessWidget {
  const DropIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: const Color(0xFF38BDF8),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.32),
            blurRadius: 10,
          ),
        ],
      ),
    );
  }
}

class IssueCardDraggable extends StatelessWidget {
  const IssueCardDraggable({
    super.key,
    required this.issue,
    required this.sourceColumnId,
    required this.onTap,
  });

  final Issue issue;
  final String sourceColumnId;
  final VoidCallback onTap;

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
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: IssueCard(issue: issue),
      ),
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
          if (issue.body.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              issue.body,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF64748B),
                height: 1.35,
              ),
            ),
          ],
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
              if (issue.dueDate != null) ...[
                const SizedBox(width: 8),
                DueDatePill(dueDate: issue.dueDate!),
              ],
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

class DueDatePill extends StatelessWidget {
  const DueDatePill({super.key, required this.dueDate});

  final DateTime dueDate;

  @override
  Widget build(BuildContext context) {
    final status = _dueDateStatus(dueDate);
    final colors = switch (status) {
      DueDateStatus.overdue => (
        background: const Color(0xFFFEE2E2),
        foreground: const Color(0xFFB91C1C),
      ),
      DueDateStatus.today => (
        background: const Color(0xFFFFEDD5),
        foreground: const Color(0xFFC2410C),
      ),
      DueDateStatus.soon => (
        background: const Color(0xFFFEF3C7),
        foreground: const Color(0xFF92400E),
      ),
      DueDateStatus.later => (
        background: const Color(0xFFEFF6FF),
        foreground: const Color(0xFF1D4ED8),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_outlined, size: 13, color: colors.foreground),
          const SizedBox(width: 4),
          Text(
            _dueDateLabel(dueDate),
            style: TextStyle(
              color: colors.foreground,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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

class NewIssueDraft {
  const NewIssueDraft({
    required this.title,
    required this.body,
    required this.repo,
    required this.assignee,
    required this.labels,
    required this.columnId,
    required this.priority,
    required this.dueDate,
  });

  final String title;
  final String body;
  final String repo;
  final String assignee;
  final List<String> labels;
  final String columnId;
  final Priority priority;
  final DateTime? dueDate;
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
    this.body = '',
    required this.assignee,
    required this.labels,
    required this.comments,
    required this.priority,
    this.dueDate,
  });

  final String id;
  final String repo;
  final String title;
  final String body;
  final String assignee;
  final List<String> labels;
  final int comments;
  final Priority priority;
  final DateTime? dueDate;
}

DateTime _dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

String _formatDate(DateTime date) {
  return '${date.month}月${date.day}日';
}

String _dueDateLabel(DateTime date) {
  final status = _dueDateStatus(date);

  return switch (status) {
    DueDateStatus.overdue => '期限切れ',
    DueDateStatus.today => '今日',
    DueDateStatus.soon => _formatDate(date),
    DueDateStatus.later => _formatDate(date),
  };
}

DueDateStatus _dueDateStatus(DateTime date) {
  final today = _dateOnly(DateTime.now());
  final dueDate = _dateOnly(date);
  final daysUntilDue = dueDate.difference(today).inDays;

  if (daysUntilDue < 0) {
    return DueDateStatus.overdue;
  }

  if (daysUntilDue == 0) {
    return DueDateStatus.today;
  }

  if (daysUntilDue <= 3) {
    return DueDateStatus.soon;
  }

  return DueDateStatus.later;
}

enum DueDateStatus { overdue, today, soon, later }

enum Priority { high, medium, low }
