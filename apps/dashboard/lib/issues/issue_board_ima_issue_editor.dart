part of 'issue_board_ima_page.dart';

class AddIssueDialog extends StatefulWidget {
  const AddIssueDialog({
    super.key,
    required this.columns,
    required this.repositoryOptions,
    this.initialIssue,
    this.allIssues = const [],
    this.initialColumnId,
    this.isEstimatingWeight = false,
    this.onEstimateIssueWeight,
    this.onOverrideIssueWeight,
    this.isStartingCursorAgent = false,
    this.onStartCursorAgent,
    this.onCreateGitHubSubIssue,
    this.isBottomSheet = false,
    this.workspaceId,
  });

  final List<BoardColumn> columns;
  final List<String> repositoryOptions;
  final Issue? initialIssue;
  final List<Issue> allIssues;
  final String? initialColumnId;
  final bool isEstimatingWeight;
  final Future<void> Function(String issueId)? onEstimateIssueWeight;
  final IssueWeightOverrideCallback? onOverrideIssueWeight;
  final bool isStartingCursorAgent;
  final Future<void> Function(String issueId)? onStartCursorAgent;
  final Future<Map<String, dynamic>> Function({
    required String parentIssueId,
    required String title,
    required String body,
  })?
  onCreateGitHubSubIssue;
  final bool isBottomSheet;
  final String? workspaceId;

  @override
  State<AddIssueDialog> createState() => _AddIssueDialogState();
}

class _AddIssueDialogState extends State<AddIssueDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _bodyController = TextEditingController();
  final _githubUrlController = TextEditingController();
  final _labelsController = TextEditingController(text: 'feature, mobile');
  final _subIssueTitleController = TextEditingController();
  final _subIssueBodyController = TextEditingController();
  String? _selectedRepo;
  late String _selectedColumnId;
  Priority _priority = Priority.medium;
  DateTime? _dueDate;
  var _isEstimatingWeight = false;
  var _isOverridingWeight = false;
  var _isStartingCursorAgent = false;
  var _isCreatingSubIssue = false;
  final List<Issue> _issueStack = [];
  Issue? _liveIssue;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _issueSubscription;

  Issue? get _currentIssue =>
      _liveIssue ??
      (_issueStack.isEmpty ? widget.initialIssue : _issueStack.last);

  @override
  void initState() {
    super.initState();
    final issue = widget.initialIssue;

    _selectedColumnId = widget.initialColumnId ?? widget.columns.first.id;
    _selectedRepo = widget.repositoryOptions.isEmpty
        ? null
        : widget.repositoryOptions.first;

    if (issue != null) {
      _issueStack.add(issue);
      _setCurrentIssue(issue, listen: true);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _titleFocusNode.requestFocus();
        }
      });
    }
  }

  void _setCurrentIssue(Issue issue, {required bool listen}) {
    _liveIssue = issue;
    _titleController.text = issue.title;
    _bodyController.text = issue.body;
    _githubUrlController.text = issue.githubUrl ?? '';
    _selectedRepo = widget.repositoryOptions.contains(issue.repo)
        ? issue.repo
        : null;
    _labelsController.text = issue.labels.join(', ');
    _priority = issue.priority;
    _dueDate = issue.dueDate;
    _subIssueTitleController.clear();
    _subIssueBodyController.clear();
    if (listen) {
      _listenToIssue(issue.id);
    }
  }

  void _listenToIssue(String issueId) {
    final workspaceId = widget.workspaceId;
    if (workspaceId == null || workspaceId.isEmpty) {
      return;
    }
    final currentSubscription = _issueSubscription;
    if (currentSubscription != null) {
      unawaited(currentSubscription.cancel());
    }
    _issueSubscription = FirebaseFirestore.instance
        .doc('workspaces/$workspaceId/issues/$issueId')
        .snapshots()
        .listen((snapshot) {
          if (!mounted || !snapshot.exists) return;
          final issue = Issue.fromDocument(snapshot);
          setState(() {
            _liveIssue = issue;
            if (_issueStack.isNotEmpty && _issueStack.last.id == issue.id) {
              _issueStack[_issueStack.length - 1] = issue;
            }
          });
        });
  }

  @override
  void dispose() {
    _issueSubscription?.cancel();
    _titleController.dispose();
    _titleFocusNode.dispose();
    _bodyController.dispose();
    _githubUrlController.dispose();
    _labelsController.dispose();
    _subIssueTitleController.dispose();
    _subIssueBodyController.dispose();
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

    final draft = NewIssueDraft(
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      repo: _selectedRepo ?? '',
      githubUrl: _normalizedOptionalUrl(_githubUrlController.text),
      labels: labels,
      columnId: _selectedColumnId,
      priority: _priority,
      dueDate: _dueDate,
    );
    final currentIssue = _currentIssue;
    Navigator.of(context).pop(
      currentIssue == null
          ? draft
          : EditIssueDialogResult(issueId: currentIssue.id, draft: draft),
    );
  }

  void _closeIssue() {
    final issue = _currentIssue;
    if (issue == null) {
      return;
    }
    Navigator.of(context).pop(CloseIssueDialogResult(issue.id));
  }

  Future<void> _estimateIssueWeight() async {
    final issue = _currentIssue;
    final onEstimate = widget.onEstimateIssueWeight;
    if (issue == null || onEstimate == null || _isEstimatingWeight) {
      return;
    }

    setState(() => _isEstimatingWeight = true);
    try {
      await onEstimate(issue.id);
    } finally {
      if (mounted) {
        setState(() => _isEstimatingWeight = false);
      }
    }
  }

  Future<void> _overrideIssueWeight() async {
    final issue = _currentIssue;
    final onOverride = widget.onOverrideIssueWeight;
    if (issue == null || onOverride == null || _isOverridingWeight) {
      return;
    }

    final draft = await showDialog<IssueWeightOverrideDraft>(
      context: context,
      builder: (context) => IssueWeightOverrideDialog(issue: issue),
    );
    if (draft == null || !mounted) {
      return;
    }

    setState(() => _isOverridingWeight = true);
    try {
      await onOverride(issueId: issue.id, draft: draft);
    } finally {
      if (mounted) {
        setState(() => _isOverridingWeight = false);
      }
    }
  }

  Future<void> _startCursorAgent() async {
    final issue = _currentIssue;
    final onStart = widget.onStartCursorAgent;
    if (issue == null || onStart == null || _isStartingCursorAgent) {
      return;
    }

    setState(() => _isStartingCursorAgent = true);
    try {
      await onStart(issue.id);
    } finally {
      if (mounted) {
        setState(() => _isStartingCursorAgent = false);
      }
    }
  }

  Future<void> _createSubIssue() async {
    final issue = _currentIssue;
    final onCreate = widget.onCreateGitHubSubIssue;
    final title = _subIssueTitleController.text.trim();
    if (issue == null || onCreate == null || _isCreatingSubIssue) {
      return;
    }
    if (title.isEmpty) {
      _showFloatingSnackBar(context, 'Sub-issue titleを入力してください');
      return;
    }

    setState(() => _isCreatingSubIssue = true);
    try {
      await onCreate(
        parentIssueId: issue.id,
        title: title,
        body: _subIssueBodyController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      _subIssueTitleController.clear();
      _subIssueBodyController.clear();
      _showOverlaySnackBar(context, 'Sub-issue added');
    } finally {
      if (mounted) {
        setState(() => _isCreatingSubIssue = false);
      }
    }
  }

  Future<void> _openIssueFromSubIssue(String issueId) async {
    Issue? issue;
    for (final candidate in widget.allIssues) {
      if (candidate.id == issueId) {
        issue = candidate;
        break;
      }
    }
    if (issue == null) {
      final workspaceId = widget.workspaceId;
      if (workspaceId != null && workspaceId.isNotEmpty) {
        final snapshot = await FirebaseFirestore.instance
            .doc('workspaces/$workspaceId/issues/$issueId')
            .get();
        if (snapshot.exists) {
          issue = Issue.fromDocument(snapshot);
        }
      }
      if (!mounted) {
        return;
      }
    }
    if (issue == null) {
      _showFloatingSnackBar(context, 'Issueが見つかりません');
      return;
    }
    final selectedIssue = issue;
    setState(() {
      _issueStack.add(selectedIssue);
      _setCurrentIssue(selectedIssue, listen: true);
    });
  }

  void _goBackIssue() {
    if (_issueStack.length <= 1) {
      return;
    }
    setState(() {
      _issueStack.removeLast();
      _setCurrentIssue(_issueStack.last, listen: true);
    });
  }

  void _copyGitHubUrl() {
    unawaited(
      _copyTextToClipboard(
        context,
        text: _githubUrlController.text,
        successMessage: 'GitHubリンクをコピーしました',
      ),
    );
  }

  void _openGitHubUrl() {
    final url = _githubUrlController.text.trim();
    if (url.isNotEmpty) {
      unawaited(_launchUrlExternal(url));
    }
  }

  Future<IssuePullRequestDiff> _loadPullRequestDiff({
    required Issue issue,
    required IssuePullRequest pullRequest,
  }) async {
    final workspaceId = widget.workspaceId;
    if (workspaceId == null || workspaceId.isEmpty) {
      throw StateError('workspaceId is required');
    }
    final result = await firebaseFunctions
        .httpsCallable(
          getIssuePullRequestDiffFunction,
          options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
        )
        .call<Map<String, dynamic>>({
          'workspaceId': workspaceId,
          'issueId': issue.id,
          'repository': issue.repo,
          'pullRequestNumber': pullRequest.number,
        });
    return IssuePullRequestDiff.fromMap(_asMap(result.data));
  }

  Future<void> _openPullRequestDiff(IssuePullRequest pullRequest) async {
    final issue = _currentIssue;
    if (issue == null) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PullRequestDiffSheet(
        issue: issue,
        pullRequest: pullRequest,
        loadDiff: () =>
            _loadPullRequestDiff(issue: issue, pullRequest: pullRequest),
        onMerge: pullRequest.merged || pullRequest.state.toLowerCase() != 'open'
            ? null
            : () => _mergePullRequest(issue: issue, pullRequest: pullRequest),
      ),
    );
  }

  Future<bool> _mergePullRequest({
    required Issue issue,
    required IssuePullRequest pullRequest,
  }) async {
    final workspaceId = widget.workspaceId;
    if (workspaceId == null || workspaceId.isEmpty) {
      _showFloatingSnackBar(context, 'workspaceId is required');
      return false;
    }
    final confirmed = await _confirmPullRequestMerge(pullRequest);
    if (confirmed != true) {
      return false;
    }

    try {
      final result = await firebaseFunctions
          .httpsCallable(
            mergeIssuePullRequestFunction,
            options: HttpsCallableOptions(timeout: const Duration(seconds: 45)),
          )
          .call<Map<String, dynamic>>({
            'workspaceId': workspaceId,
            'issueId': issue.id,
            'repository': issue.repo,
            'pullRequestNumber': pullRequest.number,
            'mergeMethod': 'squash',
          });
      final data = _asMap(result.data);
      final merged = data['merged'] == true;
      if (!mounted) {
        return merged;
      }
      _showOverlaySnackBar(
        context,
        merged
            ? 'PR #${pullRequest.number}をマージしました'
            : _asString(data['message'], 'PRのマージ結果を確認してください'),
      );
      return merged;
    } catch (error) {
      if (mounted) {
        _showFloatingSnackBar(context, _friendlyError(error));
      }
      return false;
    }
  }

  Future<bool?> _confirmPullRequestMerge(IssuePullRequest pullRequest) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('PR #${pullRequest.number}をマージしますか？'),
        content: Text(
          'Squash mergeを実行し、このissueを完了へ移動します。\n${pullRequest.title}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.call_merge_rounded, size: 18),
            label: const Text('マージする'),
          ),
        ],
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
    final screenSize = MediaQuery.sizeOf(context);
    final isCompactDialog = screenSize.width < 560;
    final maxHeight = screenSize.height * (isCompactDialog ? 0.92 : 0.86);
    final currentIssue = _currentIssue;
    final isEditing = currentIssue != null;
    final canCloseIssue = isEditing && currentIssue.statusId != _closedStatusId;
    final title = isEditing ? 'GitHub issueを編集' : 'GitHub issueを新規作成';
    final description = isEditing
        ? '${currentIssue.displayId} の内容を更新します。'
        : 'GitHub issueを作成してボードへ追加します。';
    final dialogPadding = EdgeInsets.all(isCompactDialog ? 18 : 24);
    final dialogBorderRadius = BorderRadius.circular(isCompactDialog ? 22 : 28);
    final formContent = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isEditing && _issueStack.length > 1) ...[
            IssueBreadcrumb(
              issues: _issueStack,
              onBack: _goBackIssue,
              onSelect: (index) {
                if (index < 0 || index >= _issueStack.length - 1) {
                  return;
                }
                setState(() {
                  _issueStack.removeRange(index + 1, _issueStack.length);
                  _setCurrentIssue(_issueStack.last, listen: true);
                });
              },
            ),
            const SizedBox(height: 14),
          ],
          _TitleField(
            controller: _titleController,
            focusNode: _titleFocusNode,
            decoration: _inputDecoration(
              label: 'タイトル',
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
              label: '本文',
              hint: '背景、やりたいこと、受け入れ条件などをMarkdownっぽく書けます。',
            ),
          ),
          const SizedBox(height: 14),
          _RepoField(
            repositories: widget.repositoryOptions,
            selectedRepository: _selectedRepo,
            onRepositoryChanged: (value) {
              setState(() => _selectedRepo = value);
            },
            decorationBuilder: _inputDecoration,
          ),
          if (isEditing) ...[
            const SizedBox(height: 14),
            _GitHubLinkField(
              controller: _githubUrlController,
              decoration: _inputDecoration(
                label: 'GitHubリンク',
                hint: 'https://github.com/openci/ima/issues/123',
              ),
              onOpen: _openGitHubUrl,
              onCopy: _copyGitHubUrl,
            ),
            if (currentIssue.pullRequests.isNotEmpty) ...[
              const SizedBox(height: 14),
              PullRequestReviewPanel(
                issue: currentIssue,
                onOpenDiff: _openPullRequestDiff,
                onMergePullRequest: (pullRequest) => unawaited(
                  _mergePullRequest(
                    issue: currentIssue,
                    pullRequest: pullRequest,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            CreateSubIssuePanel(
              issue: currentIssue,
              workspaceId: widget.workspaceId,
              linkedSubIssues: _subIssuesForParent(
                currentIssue,
                widget.allIssues,
              ),
              onOpenIssue: _openIssueFromSubIssue,
              titleController: _subIssueTitleController,
              bodyController: _subIssueBodyController,
              isCreating: _isCreatingSubIssue,
              onCreate: widget.onCreateGitHubSubIssue == null
                  ? null
                  : _createSubIssue,
            ),
          ],
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
              label: 'ラベル',
              hint: 'feature, github, mobile',
            ),
            onFieldSubmitted: (_) => _saveIssue(),
          ),
          if (isEditing) ...[
            const SizedBox(height: 14),
            IssueWeightPanel(
              issue: currentIssue,
              isEstimating: widget.isEstimatingWeight || _isEstimatingWeight,
              isOverriding: _isOverridingWeight,
              onEstimate: widget.onEstimateIssueWeight == null
                  ? null
                  : _estimateIssueWeight,
              onOverride: widget.onOverrideIssueWeight == null
                  ? null
                  : _overrideIssueWeight,
            ),
            const SizedBox(height: 14),
            CursorAgentPanel(
              issue: currentIssue,
              isStarting:
                  widget.isStartingCursorAgent || _isStartingCursorAgent,
              onStart: widget.onStartCursorAgent == null
                  ? null
                  : _startCursorAgent,
            ),
            SizedBox(height: 14),
          ],
        ],
      ),
    );
    final content = ClipRRect(
      borderRadius: widget.isBottomSheet
          ? const BorderRadius.vertical(top: Radius.circular(28))
          : dialogBorderRadius,
      child: Material(
        color: Colors.white,
        child: widget.isBottomSheet
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BottomSheetHeader(
                    title: title,
                    issueDisplayId: isEditing ? currentIssue.displayId : null,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      child: formContent,
                    ),
                  ),
                  _BottomSheetActions(
                    isEditing: isEditing,
                    canCloseIssue: canCloseIssue,
                    onCloseIssue: _closeIssue,
                    onSaveIssue: _saveIssue,
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: dialogPadding.copyWith(bottom: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFAFBFC),
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: _DialogHeader(
                      title: title,
                      description: description,
                      issueDisplayId: isEditing ? currentIssue.displayId : null,
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: dialogPadding.copyWith(top: 18, bottom: 2),
                      child: formContent,
                    ),
                  ),
                  Container(
                    padding: dialogPadding.copyWith(top: 16),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: _DialogActions(
                      isEditing: isEditing,
                      canCloseIssue: canCloseIssue,
                      onCancel: () => Navigator.of(context).pop(),
                      onCloseIssue: _closeIssue,
                      onSaveIssue: _saveIssue,
                    ),
                  ),
                ],
              ),
      ),
    );
    final framedContent = widget.isBottomSheet
        ? SizedBox(width: double.infinity, height: maxHeight, child: content)
        : ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 720, maxHeight: maxHeight),
            child: content,
          );

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _saveIssue,
      },
      child: Focus(
        autofocus: true,
        child: widget.isBottomSheet
            ? AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: framedContent,
                ),
              )
            : Dialog(
                insetPadding: EdgeInsets.symmetric(
                  horizontal: isCompactDialog ? 12 : 20,
                  vertical: isCompactDialog ? 12 : 24,
                ),
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: dialogBorderRadius),
                clipBehavior: Clip.antiAlias,
                child: framedContent,
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
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 1.5),
      ),
      floatingLabelStyle: const TextStyle(color: Color(0xFF1D4ED8)),
      contentPadding: const EdgeInsets.fromLTRB(14, 15, 14, 15),
    );
  }

  String _priorityLabel(Priority priority) {
    switch (priority) {
      case Priority.high:
        return '高';
      case Priority.medium:
        return '中';
      case Priority.low:
        return '低';
    }
  }
}

class _DialogActions extends StatelessWidget {
  const _DialogActions({
    required this.isEditing,
    required this.canCloseIssue,
    required this.onCancel,
    required this.onCloseIssue,
    required this.onSaveIssue,
  });

  final bool isEditing;
  final bool canCloseIssue;
  final VoidCallback onCancel;
  final VoidCallback onCloseIssue;
  final VoidCallback onSaveIssue;

  @override
  Widget build(BuildContext context) {
    final cancelButton = TextButton(
      onPressed: onCancel,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF64748B),
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text('キャンセル'),
    );
    final closeButton = _IssueEditorCompleteButton(
      onPressed: onCloseIssue,
      minWidth: 136,
    );
    final saveButton = _IssueEditorPrimaryButton(
      onPressed: onSaveIssue,
      icon: isEditing ? Icons.save_outlined : Icons.add_rounded,
      label: isEditing ? '変更を保存' : 'issueを追加',
      minWidth: 148,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(alignment: Alignment.centerLeft, child: cancelButton),
              const SizedBox(height: 10),
              if (canCloseIssue) ...[closeButton, const SizedBox(height: 10)],
              saveButton,
            ],
          );
        }

        return Row(
          children: [
            cancelButton,
            const Spacer(),
            if (canCloseIssue) ...[closeButton, const SizedBox(width: 12)],
            saveButton,
          ],
        );
      },
    );
  }
}

class _IssueEditorPrimaryButton extends StatelessWidget {
  const _IssueEditorPrimaryButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.minWidth,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFCBD5E1),
        disabledForegroundColor: const Color(0xFF64748B),
        elevation: 0,
        minimumSize: Size(minWidth, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _IssueEditorCompleteButton extends StatelessWidget {
  const _IssueEditorCompleteButton({
    required this.onPressed,
    required this.minWidth,
  });

  final VoidCallback? onPressed;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.check_rounded, size: 18),
      label: const Text(
        'issueを完了',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFECFDF5),
        foregroundColor: const Color(0xFF047857),
        disabledBackgroundColor: const Color(0xFFE2E8F0),
        disabledForegroundColor: const Color(0xFF64748B),
        elevation: 0,
        minimumSize: Size(minWidth, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        side: const BorderSide(color: Color(0xFFA7F3D0)),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _BottomSheetHeader extends StatelessWidget {
  const _BottomSheetHeader({required this.title, this.issueDisplayId});

  final String title;
  final String? issueDisplayId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 10, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFBFC),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (issueDisplayId != null) ...[
                      const SizedBox(width: 8),
                      _IssueIdChip(displayId: issueDisplayId!),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: '閉じる',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomSheetActions extends StatelessWidget {
  const _BottomSheetActions({
    required this.isEditing,
    required this.canCloseIssue,
    required this.onCloseIssue,
    required this.onSaveIssue,
  });

  final bool isEditing;
  final bool canCloseIssue;
  final VoidCallback onCloseIssue;
  final VoidCallback onSaveIssue;

  @override
  Widget build(BuildContext context) {
    final closeButton = _IssueEditorCompleteButton(
      onPressed: onCloseIssue,
      minWidth: 0,
    );
    final saveButton = _IssueEditorPrimaryButton(
      onPressed: onSaveIssue,
      icon: isEditing ? Icons.save_outlined : Icons.add_rounded,
      label: isEditing ? '変更を保存' : 'issueを追加',
      minWidth: 0,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (canCloseIssue) ...[
              Expanded(child: closeButton),
              const SizedBox(width: 10),
            ],
            Expanded(child: saveButton),
          ],
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({
    required this.title,
    required this.description,
    this.issueDisplayId,
  });

  final String title;
  final String description;
  final String? issueDisplayId;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (issueDisplayId != null) ...[
                    const SizedBox(width: 8),
                    _IssueIdChip(displayId: issueDisplayId!),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: '閉じる',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}

class IssueBreadcrumb extends StatelessWidget {
  const IssueBreadcrumb({
    super.key,
    required this.issues,
    required this.onBack,
    required this.onSelect,
  });

  final List<Issue> issues;
  final VoidCallback onBack;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final parentIssue = issues.first;
    final currentIssue = issues.last;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        border: Border.all(color: const Color(0xFFBFDBFE)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.account_tree_outlined,
                          size: 16,
                          color: Color(0xFF2563EB),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'sub-issueを表示中',
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currentIssue.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 15,
                        height: 1.25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '親: ${parentIssue.displayId} · ${parentIssue.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 17),
                label: Text('${parentIssue.displayId}に戻る'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1D4ED8),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF93C5FD)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var index = 0; index < issues.length; index++) ...[
                  if (index > 0)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ActionChip(
                    avatar: Icon(
                      index == 0
                          ? Icons.flag_outlined
                          : Icons.subdirectory_arrow_right_rounded,
                      size: 15,
                      color: index == issues.length - 1
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF2563EB),
                    ),
                    label: Text(issues[index].displayId),
                    onPressed: index == issues.length - 1
                        ? null
                        : () => onSelect(index),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: index == issues.length - 1
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFFDBEAFE),
                    side: BorderSide(
                      color: index == issues.length - 1
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF93C5FD),
                    ),
                    labelStyle: TextStyle(
                      color: index == issues.length - 1
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF1D4ED8),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueIdChip extends StatefulWidget {
  const _IssueIdChip({required this.displayId});

  final String displayId;

  @override
  State<_IssueIdChip> createState() => _IssueIdChipState();
}

class _IssueIdChipState extends State<_IssueIdChip> {
  bool _copied = false;

  Future<void> _handleCopy() async {
    final trimmed = widget.displayId.trim();
    if (trimmed.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: trimmed));
    if (!mounted) return;
    _showOverlaySnackBar(context, 'Issue IDがコピーされました');
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _copied ? null : () => unawaited(_handleCopy()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.displayId,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _copied ? Icons.check_rounded : Icons.copy_rounded,
                key: ValueKey(_copied),
                size: 13,
                color: _copied
                    ? const Color(0xFF22C55E)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleField extends StatelessWidget {
  const _TitleField({
    required this.controller,
    required this.focusNode,
    required this.decoration,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final InputDecoration decoration;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      autofocus: true,
      textInputAction: TextInputAction.next,
      decoration: decoration,
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'タイトルを入力してください' : null,
    );
  }
}

class _GitHubLinkField extends StatelessWidget {
  const _GitHubLinkField({
    required this.controller,
    required this.decoration,
    required this.onCopy,
    required this.onOpen,
  });

  final TextEditingController controller;
  final InputDecoration decoration;
  final VoidCallback onCopy;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final field = TextFormField(
          controller: controller,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          decoration: decoration,
          validator: _validateOptionalHttpUrl,
        );
        final actions = ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final hasUrl = value.text.trim().isNotEmpty;
            final actionButtonStyle = OutlinedButton.styleFrom(
              minimumSize: const Size(0, 56),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            );
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: hasUrl ? onCopy : null,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('コピー'),
                  style: actionButtonStyle,
                ),
                OutlinedButton.icon(
                  onPressed: hasUrl ? onOpen : null,
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('開く'),
                  style: actionButtonStyle,
                ),
              ],
            );
          },
        );

        if (constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [field, const SizedBox(height: 10), actions],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: field),
            const SizedBox(width: 12),
            actions,
          ],
        );
      },
    );
  }
}

class PullRequestReviewPanel extends StatelessWidget {
  const PullRequestReviewPanel({
    super.key,
    required this.issue,
    required this.onOpenDiff,
    required this.onMergePullRequest,
  });

  final Issue issue;
  final ValueChanged<IssuePullRequest> onOpenDiff;
  final ValueChanged<IssuePullRequest> onMergePullRequest;

  @override
  Widget build(BuildContext context) {
    final pullRequests = issue.pullRequests.reversed.toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.alt_route_rounded,
                size: 18,
                color: Color(0xFF2563EB),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pullRequests.length == 1
                      ? 'Pull request'
                      : 'Pull requests ${pullRequests.length}',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final entry in pullRequests.indexed) ...[
            PullRequestReviewTile(
              repository: issue.repo,
              pullRequest: entry.$2,
              onOpenDiff: () => onOpenDiff(entry.$2),
              onMerge: entry.$2.merged || entry.$2.state.toLowerCase() != 'open'
                  ? null
                  : () => onMergePullRequest(entry.$2),
            ),
            if (entry.$1 != pullRequests.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class PullRequestReviewTile extends StatelessWidget {
  const PullRequestReviewTile({
    super.key,
    required this.repository,
    required this.pullRequest,
    required this.onOpenDiff,
    required this.onMerge,
  });

  final String repository;
  final IssuePullRequest pullRequest;
  final VoidCallback onOpenDiff;
  final VoidCallback? onMerge;

  @override
  Widget build(BuildContext context) {
    final branch = pullRequest.branch;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '$repository #${pullRequest.number}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        PullRequestStatePill(pullRequest: pullRequest),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pullRequest.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),
                    if (branch.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.fork_right_rounded,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              branch,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 500;
              final diffButton = FilledButton.icon(
                onPressed: onOpenDiff,
                icon: const Icon(Icons.code_rounded, size: 17),
                label: const Text('差分を見る'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              );
              final githubButton = OutlinedButton.icon(
                onPressed: pullRequest.url == null
                    ? null
                    : () => unawaited(_launchUrlExternal(pullRequest.url!)),
                icon: const Icon(Icons.open_in_new_rounded, size: 17),
                label: const Text('GitHub'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              );
              final mergeButton = OutlinedButton.icon(
                onPressed: onMerge,
                icon: const Icon(Icons.call_merge_rounded, size: 17),
                label: const Text('マージ'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF047857),
                  side: const BorderSide(color: Color(0xFFA7F3D0)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    diffButton,
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: githubButton),
                        const SizedBox(width: 8),
                        Expanded(child: mergeButton),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  diffButton,
                  const SizedBox(width: 8),
                  githubButton,
                  const Spacer(),
                  mergeButton,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class PullRequestStatePill extends StatelessWidget {
  const PullRequestStatePill({super.key, required this.pullRequest});

  final IssuePullRequest pullRequest;

  @override
  Widget build(BuildContext context) {
    final state = pullRequest.state.toLowerCase();
    final label = pullRequest.merged
        ? 'merged'
        : state == 'closed'
        ? 'closed'
        : 'open';
    final color = pullRequest.merged
        ? const Color(0xFF7C3AED)
        : state == 'closed'
        ? const Color(0xFFB45309)
        : const Color(0xFF15803D);
    final icon = pullRequest.merged
        ? Icons.call_merge_rounded
        : state == 'closed'
        ? Icons.circle_rounded
        : Icons.radio_button_checked_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class PullRequestDiffSheet extends StatefulWidget {
  const PullRequestDiffSheet({
    super.key,
    required this.issue,
    required this.pullRequest,
    required this.loadDiff,
    required this.onMerge,
  });

  final Issue issue;
  final IssuePullRequest pullRequest;
  final Future<IssuePullRequestDiff> Function() loadDiff;
  final Future<bool> Function()? onMerge;

  @override
  State<PullRequestDiffSheet> createState() => _PullRequestDiffSheetState();
}

class _PullRequestDiffSheetState extends State<PullRequestDiffSheet> {
  late Future<IssuePullRequestDiff> _future;
  var _isMerging = false;
  var _merged = false;

  @override
  void initState() {
    super.initState();
    _future = widget.loadDiff();
    _merged = widget.pullRequest.merged;
  }

  void _retry() {
    setState(() => _future = widget.loadDiff());
  }

  Future<void> _merge() async {
    final onMerge = widget.onMerge;
    if (onMerge == null || _isMerging || _merged) {
      return;
    }
    setState(() => _isMerging = true);
    final merged = await onMerge();
    if (!mounted) {
      return;
    }
    setState(() {
      _isMerging = false;
      _merged = merged || _merged;
      if (merged) {
        _future = widget.loadDiff();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.9;
    return SizedBox(
      height: height,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: FutureBuilder<IssuePullRequestDiff>(
            future: _future,
            builder: (context, snapshot) {
              final diff = snapshot.data;
              return Column(
                children: [
                  _PullRequestDiffHeader(
                    issue: widget.issue,
                    pullRequest: widget.pullRequest,
                    diff: diff,
                    isMerging: _isMerging,
                    merged: _merged || (diff?.merged ?? false),
                    onMerge: widget.onMerge == null || _merged ? null : _merge,
                  ),
                  Expanded(
                    child: switch (snapshot.connectionState) {
                      ConnectionState.waiting => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      _ when snapshot.hasError => _PullRequestDiffError(
                        error: snapshot.error,
                        onRetry: _retry,
                      ),
                      _ when diff != null => PullRequestDiffBody(diff: diff),
                      _ => const Center(child: Text('差分を読み込めませんでした')),
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PullRequestDiffHeader extends StatelessWidget {
  const _PullRequestDiffHeader({
    required this.issue,
    required this.pullRequest,
    required this.diff,
    required this.isMerging,
    required this.merged,
    required this.onMerge,
  });

  final Issue issue;
  final IssuePullRequest pullRequest;
  final IssuePullRequestDiff? diff;
  final bool isMerging;
  final bool merged;
  final VoidCallback? onMerge;

  @override
  Widget build(BuildContext context) {
    final title = diff?.title ?? pullRequest.title;
    final url = diff?.url.isNotEmpty == true ? diff!.url : pullRequest.url;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 14),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFBFC),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${issue.repo} #${pullRequest.number}',
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        PullRequestStatePill(
                          pullRequest: pullRequest.copyWith(
                            state: diff?.state,
                            merged: merged || diff?.merged == true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '閉じる',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 520;
              final openButton = OutlinedButton.icon(
                onPressed: url == null || url.isEmpty
                    ? null
                    : () => unawaited(_launchUrlExternal(url)),
                icon: const Icon(Icons.open_in_new_rounded, size: 17),
                label: const Text('GitHub'),
              );
              final mergeButton = FilledButton.icon(
                onPressed: merged || isMerging ? null : onMerge,
                icon: isMerging
                    ? const SizedBox.square(
                        dimension: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.call_merge_rounded, size: 17),
                label: Text(merged ? 'マージ済み' : 'マージ'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF047857),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE2E8F0),
                  disabledForegroundColor: const Color(0xFF64748B),
                ),
              );
              if (compact) {
                return Row(
                  children: [
                    Expanded(child: openButton),
                    const SizedBox(width: 8),
                    Expanded(child: mergeButton),
                  ],
                );
              }
              return Row(
                children: [
                  openButton,
                  const Spacer(),
                  mergeButton,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class PullRequestDiffBody extends StatelessWidget {
  const PullRequestDiffBody({super.key, required this.diff});

  final IssuePullRequestDiff diff;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PullRequestDiffStats(diff: diff),
          if (diff.filesTruncated) ...[
            const SizedBox(height: 10),
            const _PullRequestDiffNotice(
              message: '変更ファイルが多いため、先頭300ファイルまで表示しています。',
            ),
          ],
          const SizedBox(height: 12),
          for (final entry in diff.files.indexed) ...[
            PullRequestDiffFileView(file: entry.$2),
            if (entry.$1 != diff.files.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _PullRequestDiffStats extends StatelessWidget {
  const _PullRequestDiffStats({required this.diff});

  final IssuePullRequestDiff diff;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _PullRequestDiffStatPill(
          icon: Icons.description_outlined,
          label: '${diff.changedFiles} files',
          color: const Color(0xFF2563EB),
        ),
        _PullRequestDiffStatPill(
          icon: Icons.add_rounded,
          label: '+${diff.additions}',
          color: const Color(0xFF15803D),
        ),
        _PullRequestDiffStatPill(
          icon: Icons.remove_rounded,
          label: '-${diff.deletions}',
          color: const Color(0xFFB91C1C),
        ),
        if (diff.branch.isNotEmpty)
          _PullRequestDiffStatPill(
            icon: Icons.fork_right_rounded,
            label: diff.branch,
            color: const Color(0xFF64748B),
          ),
      ],
    );
  }
}

class _PullRequestDiffStatPill extends StatelessWidget {
  const _PullRequestDiffStatPill({
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class PullRequestDiffFileView extends StatelessWidget {
  const PullRequestDiffFileView({super.key, required this.file});

  final IssuePullRequestDiffFile file;

  @override
  Widget build(BuildContext context) {
    final patch = file.patch;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          initiallyExpanded: diffFileInitiallyExpanded(file),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                file.filename,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (file.previousFilename != null) ...[
                const SizedBox(height: 3),
                Text(
                  'renamed from ${file.previousFilename}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _DiffFileStatusPill(status: file.status),
                _DiffCountPill(
                  label: '+${file.additions}',
                  color: const Color(0xFF15803D),
                ),
                _DiffCountPill(
                  label: '-${file.deletions}',
                  color: const Color(0xFFB91C1C),
                ),
                _DiffCountPill(
                  label: '${file.changes} changes',
                  color: const Color(0xFF64748B),
                ),
              ],
            ),
          ),
          children: [
            if (patch.isEmpty)
              const _PullRequestDiffNotice(
                message: 'このファイルのdiff previewはありません。',
              )
            else
              _PatchBlock(
                patch: file.patchTruncated
                    ? '$patch\n\n... patch truncated in OpenCI preview'
                    : patch,
              ),
          ],
        ),
      ),
    );
  }
}

bool diffFileInitiallyExpanded(IssuePullRequestDiffFile file) {
  return file.patch.isNotEmpty && file.changes <= 80;
}

class _DiffFileStatusPill extends StatelessWidget {
  const _DiffFileStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'added' => const Color(0xFF15803D),
      'removed' => const Color(0xFFB91C1C),
      'renamed' => const Color(0xFF7C3AED),
      _ => const Color(0xFF2563EB),
    };
    return _DiffCountPill(label: status, color: color);
  }
}

class _DiffCountPill extends StatelessWidget {
  const _DiffCountPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PatchBlock extends StatelessWidget {
  const _PatchBlock({required this.patch});

  final String patch;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(12),
        child: SelectableText(
          patch,
          style: const TextStyle(
            color: Color(0xFFE2E8F0),
            fontFamily: 'monospace',
            fontSize: 12,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}

class _PullRequestDiffNotice extends StatelessWidget {
  const _PullRequestDiffNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        border: Border.all(color: const Color(0xFFFDE68A)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF92400E),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PullRequestDiffError extends StatelessWidget {
  const _PullRequestDiffError({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFB91C1C),
              size: 28,
            ),
            const SizedBox(height: 10),
            Text(
              _friendlyError(error ?? '差分を読み込めませんでした'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('再読み込み'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RepoField extends StatelessWidget {
  const _RepoField({
    required this.repositories,
    required this.selectedRepository,
    required this.onRepositoryChanged,
    required this.decorationBuilder,
  });

  final List<String> repositories;
  final String? selectedRepository;
  final ValueChanged<String> onRepositoryChanged;
  final InputDecoration Function({required String label, String? hint})
  decorationBuilder;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selectedRepository,
      decoration: decorationBuilder(
        label: 'repo',
        hint: '連携済みrepoから選択',
      ),
      items: [
        for (final repository in repositories)
          DropdownMenuItem(
            value: repository,
            child: Text(repository, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: repositories.isEmpty
          ? null
          : (value) {
              if (value == null) {
                return;
              }

              onRepositoryChanged(value);
            },
      validator: (value) =>
          value == null || value.trim().isEmpty ? '先にrepoを選択してください' : null,
    );
  }
}

class CreateSubIssuePanel extends StatelessWidget {
  const CreateSubIssuePanel({
    super.key,
    required this.issue,
    this.workspaceId,
    this.linkedSubIssues = const [],
    this.onOpenIssue,
    required this.titleController,
    required this.bodyController,
    required this.isCreating,
    required this.onCreate,
  });

  final Issue issue;
  final String? workspaceId;
  final List<Issue> linkedSubIssues;
  final ValueChanged<String>? onOpenIssue;
  final TextEditingController titleController;
  final TextEditingController bodyController;
  final bool isCreating;
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    final isLinkedToGitHub = issue.githubUrl != null;
    final canCreate = isLinkedToGitHub && !isCreating && onCreate != null;
    final summary = issue.subIssuesSummary;
    final referencedSubIssues = _mergedSubIssueReferences(
      linkedSubIssues: linkedSubIssues,
      storedSubIssues: issue.subIssues,
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_tree_outlined,
                size: 18,
                color: Color(0xFF2563EB),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  summary == null
                      ? 'Sub-issues'
                      : 'Sub-issues ${summary.completed}/${summary.total}',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (summary != null)
                Text(
                  '${summary.percentCompleted}%',
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
          if (summary != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 6,
                value: summary.progress,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(
                  summary.completed == summary.total
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF2563EB),
                ),
              ),
            ),
          ],
          if (linkedSubIssues.isNotEmpty || referencedSubIssues.isNotEmpty) ...[
            const SizedBox(height: 10),
            SubIssuesList(
              workspaceId: workspaceId,
              subIssues: linkedSubIssues,
              referenceSubIssues: referencedSubIssues,
              onIssueTap: onOpenIssue,
            ),
          ],
          const SizedBox(height: 12),
          CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              SingleActivator(LogicalKeyboardKey.enter, meta: true): () {
                if (canCreate) {
                  onCreate!();
                }
              },
            },
            child: Focus(
              child: Column(
                children: [
                  TextField(
                    controller: titleController,
                    enabled: canCreate,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: '新しいsub-issueのタイトル',
                      hintText: '例: APIでsub-issueを同期する',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: bodyController,
                    enabled: canCreate,
                    minLines: 2,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      labelText: '本文',
                      hintText: '任意: sub-issueの説明',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SubIssueCreateActionBar(
            isLinkedToGitHub: isLinkedToGitHub,
            isCreating: isCreating,
            canCreate: canCreate,
            onCreate: onCreate,
          ),
        ],
      ),
    );
  }
}

class _SubIssueCreateActionBar extends StatelessWidget {
  const _SubIssueCreateActionBar({
    required this.isLinkedToGitHub,
    required this.isCreating,
    required this.canCreate,
    required this.onCreate,
  });

  final bool isLinkedToGitHub;
  final bool isCreating;
  final bool canCreate;
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    final message = isLinkedToGitHub
        ? 'GitHubへ作成し、このissueのsub-issueに紐づけます。'
        : 'GitHubに同期されたissueでのみ作成できます。';
    final button = _SubIssueCreateButton(
      isCreating: isCreating,
      onPressed: canCreate ? onCreate : null,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 480;
        final messageText = Text(
          message,
          maxLines: isCompact ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF475569),
            fontSize: 12,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
        );

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    messageText,
                    const SizedBox(height: 10),
                    button,
                  ],
                )
              : Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.account_tree_outlined,
                        size: 16,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: messageText),
                    const SizedBox(width: 12),
                    button,
                  ],
                ),
        );
      },
    );
  }
}

class _SubIssueCreateButton extends StatelessWidget {
  const _SubIssueCreateButton({required this.isCreating, this.onPressed});

  final bool isCreating;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: isCreating
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.add_task_rounded, size: 18),
      label: Text(isCreating ? '作成中...' : 'sub-issueを作成'),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        disabledBackgroundColor: isCreating
            ? const Color(0xFF0F766E)
            : const Color(0xFFE2E8F0),
        disabledForegroundColor: isCreating
            ? Colors.white
            : const Color(0xFF64748B),
        elevation: 0,
        minimumSize: const Size(148, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

List<IssueSubIssueReference> _mergedSubIssueReferences({
  required List<Issue> linkedSubIssues,
  required List<IssueSubIssueReference> storedSubIssues,
}) {
  final linkedIds = linkedSubIssues.map((issue) => issue.id).toSet();
  final byKey = <String, IssueSubIssueReference>{};

  for (final subIssue in storedSubIssues) {
    if (subIssue.issueId.isNotEmpty && linkedIds.contains(subIssue.issueId)) {
      continue;
    }
    final key = subIssue.issueId.isNotEmpty
        ? subIssue.issueId
        : subIssue.number.toString();
    if (key.isNotEmpty) {
      byKey[key] = subIssue;
    }
  }

  return byKey.values.toList();
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final statusField = DropdownButtonFormField<String>(
          initialValue: selectedColumnId,
          decoration: decorationBuilder(label: 'ステータス'),
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
        );
        final priorityField = DropdownButtonFormField<Priority>(
          initialValue: priority,
          decoration: decorationBuilder(label: '優先度'),
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
        );

        if (constraints.maxWidth < 560) {
          return Column(
            children: [statusField, const SizedBox(height: 12), priorityField],
          );
        }

        return Row(
          children: [
            Expanded(child: statusField),
            const SizedBox(width: 12),
            Expanded(child: priorityField),
          ],
        );
      },
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dateLabel = Row(
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
            ],
          );
          final actions = Wrap(
            spacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton(onPressed: onPick, child: const Text('日付を選択')),
              if (dueDate != null)
                IconButton(
                  tooltip: '締切をクリア',
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
            ],
          );

          if (constraints.maxWidth < 360) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [dateLabel, const SizedBox(height: 8), actions],
            );
          }

          return Row(
            children: [
              Expanded(child: dateLabel),
              actions,
            ],
          );
        },
      ),
    );
  }
}
