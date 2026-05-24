import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/firebase/callable_function_names.dart';
import 'package:dashboard/firebase/firestore.dart' show BuildJobStatus;
import 'package:dashboard/firebase/functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:re_highlight/languages/bash.dart';
import 'package:re_highlight/languages/c.dart';
import 'package:re_highlight/languages/cpp.dart';
import 'package:re_highlight/languages/csharp.dart';
import 'package:re_highlight/languages/css.dart';
import 'package:re_highlight/languages/dart.dart';
import 'package:re_highlight/languages/dockerfile.dart';
import 'package:re_highlight/languages/go.dart';
import 'package:re_highlight/languages/java.dart';
import 'package:re_highlight/languages/javascript.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/languages/kotlin.dart';
import 'package:re_highlight/languages/markdown.dart';
import 'package:re_highlight/languages/php.dart';
import 'package:re_highlight/languages/python.dart';
import 'package:re_highlight/languages/ruby.dart';
import 'package:re_highlight/languages/rust.dart';
import 'package:re_highlight/languages/scss.dart';
import 'package:re_highlight/languages/shell.dart';
import 'package:re_highlight/languages/sql.dart';
import 'package:re_highlight/languages/swift.dart';
import 'package:re_highlight/languages/typescript.dart';
import 'package:re_highlight/languages/xml.dart';
import 'package:re_highlight/languages/yaml.dart';
import 'package:re_highlight/re_highlight.dart';
import 'package:re_highlight/styles/github.dart';
import 'issue_board_ima_issue_cards.dart';
import 'issue_board_ima_utils.dart';
import 'issue_board_ima_board_columns.dart';
import 'issue_board_ima_models.dart';
import 'issue_board_ima_app_shell.dart';
import 'issue_board_ima_overview.dart';

class AddIssueDialog extends StatefulWidget {
  const AddIssueDialog({
    super.key,
    required this.columns,
    required this.repositoryOptions,
    this.initialIssue,
    this.allIssues = const [],
    this.initialColumnId,
    this.buildStatusesByPullRequest = const {},
    this.isEstimatingWeight = false,
    this.onEstimateIssueWeight,
    this.onOverrideIssueWeight,
    this.onCreateGitHubSubIssue,
    this.isBottomSheet = false,
    this.workspaceId,
  });

  final List<BoardColumn> columns;
  final List<String> repositoryOptions;
  final Issue? initialIssue;
  final List<Issue> allIssues;
  final String? initialColumnId;
  final Map<String, CardBuildStatus> buildStatusesByPullRequest;
  final bool isEstimatingWeight;
  final Future<void> Function(String issueId)? onEstimateIssueWeight;
  final IssueWeightOverrideCallback? onOverrideIssueWeight;
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
  var _isCreatingSubIssue = false;
  final List<Issue> _issueStack = [];
  final Map<String, String> _mergeConflictMessagesByPullRequest = {};
  Issue? _liveIssue;
  IssuePullRequest? _selectedPullRequest;
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
    _selectedPullRequest = null;
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
      githubUrl: normalizedOptionalUrl(_githubUrlController.text),
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

  void _closeIssue(String stateReason) {
    final issue = _currentIssue;
    if (issue == null) {
      return;
    }
    Navigator.of(context).pop(CloseIssueDialogResult(issue.id, stateReason: stateReason));
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

  Future<void> _createSubIssue() async {
    final issue = _currentIssue;
    final onCreate = widget.onCreateGitHubSubIssue;
    final title = _subIssueTitleController.text.trim();
    if (issue == null || onCreate == null || _isCreatingSubIssue) {
      return;
    }
    if (title.isEmpty) {
      showFloatingSnackBar(context, 'Sub-issue titleを入力してください');
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
      showOverlaySnackBar(context, 'Sub-issue added');
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
      showFloatingSnackBar(context, 'Issueが見つかりません');
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
      copyTextToClipboard(
        context,
        text: _githubUrlController.text,
        successMessage: 'GitHubリンクをコピーしました',
      ),
    );
  }

  void _openGitHubUrl() {
    final url = _githubUrlController.text.trim();
    if (url.isNotEmpty) {
      unawaited(launchUrlExternal(url));
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
    return IssuePullRequestDiff.fromMap(asMap(result.data));
  }

  void _openPullRequestDiff(IssuePullRequest pullRequest) {
    if (_currentIssue == null) {
      return;
    }
    setState(() => _selectedPullRequest = pullRequest);
  }

  void _closePullRequestDiff() {
    setState(() => _selectedPullRequest = null);
  }

  Future<bool> _mergePullRequest({
    required Issue issue,
    required IssuePullRequest pullRequest,
  }) async {
    final confirmed = await _confirmPullRequestMerge(pullRequest);
    if (confirmed != true) {
      return false;
    }
    if (!mounted) {
      return false;
    }

    Navigator.of(context).pop(
      MergeIssuePullRequestDialogResult(
        issueId: issue.id,
        repository: issue.repo,
        pullRequest: pullRequest,
      ),
    );
    return true;
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

    setState(() => _dueDate = dateOnly(selectedDate));
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isCompactDialog = screenSize.width < 560;
    final maxHeight = screenSize.height * (isCompactDialog ? 0.92 : 0.86);
    final currentIssue = _currentIssue;
    final isEditing = currentIssue != null;
    final canCloseIssue = isEditing && currentIssue.statusId != closedStatusId;
    final selectedPullRequest = currentIssue == null
        ? null
        : _selectedPullRequestForIssue(currentIssue);
    final isViewingPullRequest = selectedPullRequest != null;
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
                mergeConflictMessagesByPullRequest:
                    _mergeConflictMessagesByPullRequest,
              ),
            ],
            const SizedBox(height: 14),
            CreateSubIssuePanel(
              issue: currentIssue,
              workspaceId: widget.workspaceId,
              linkedSubIssues: subIssuesForParent(
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
            SizedBox(height: 14),
          ],
        ],
      ),
    );
    final pullRequestContent =
        currentIssue == null || selectedPullRequest == null
        ? null
        : PullRequestDiffView(
            key: ValueKey('${currentIssue.id}:${selectedPullRequest.number}'),
            issue: currentIssue,
            pullRequest: selectedPullRequest,
            buildStatus:
                widget.buildStatusesByPullRequest[buildStatusKey(
                  currentIssue.repo,
                  selectedPullRequest.number,
                )],
            mergeConflictMessage:
                _mergeConflictMessagesByPullRequest[_pullRequestMergeConflictKey(
                  currentIssue.repo,
                  selectedPullRequest.number,
                )],
            loadDiff: () => _loadPullRequestDiff(
              issue: currentIssue,
              pullRequest: selectedPullRequest,
            ),
            onMerge:
                selectedPullRequest.merged ||
                    selectedPullRequest.state.toLowerCase() != 'open'
                ? null
                : () => _mergePullRequest(
                    issue: currentIssue,
                    pullRequest: selectedPullRequest,
                  ),
            onClose: _closePullRequestDiff,
            closeIcon: Icons.arrow_back_rounded,
            closeTooltip: 'Issue詳細に戻る',
            showSheetHandle: widget.isBottomSheet,
          );
    final content = ClipRRect(
      borderRadius: widget.isBottomSheet
          ? const BorderRadius.vertical(top: Radius.circular(28))
          : dialogBorderRadius,
      child: Material(
        color: Colors.white,
        child:
            pullRequestContent ??
            (widget.isBottomSheet
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _BottomSheetHeader(
                        title: title,
                        issueDisplayId: isEditing
                            ? currentIssue.displayId
                            : null,
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
                        child: DialogHeader(
                          title: title,
                          description: description,
                          issueDisplayId: isEditing
                              ? currentIssue.displayId
                              : null,
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
                          border: Border(
                            top: BorderSide(color: Color(0xFFE2E8F0)),
                          ),
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
                  )),
      ),
    );
    final framedContent = widget.isBottomSheet
        ? SizedBox(width: double.infinity, height: maxHeight, child: content)
        : isViewingPullRequest
        ? SizedBox(
            width: math.min(math.max(screenSize.width - 40, 320), 1120),
            height: maxHeight,
            child: content,
          )
        : ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 720, maxHeight: maxHeight),
            child: content,
          );

    return CallbackShortcuts(
      bindings: isViewingPullRequest
          ? const <ShortcutActivator, VoidCallback>{}
          : <ShortcutActivator, VoidCallback>{
              const SingleActivator(
                LogicalKeyboardKey.enter,
                meta: true,
              ): _saveIssue,
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

  IssuePullRequest? _selectedPullRequestForIssue(Issue issue) {
    final selected = _selectedPullRequest;
    if (selected == null) {
      return null;
    }
    for (final pullRequest in issue.pullRequests) {
      if (pullRequest.number == selected.number) {
        return pullRequest;
      }
    }
    return null;
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
  final ValueChanged<String> onCloseIssue;
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
    final closeCompletedButton = _IssueEditorCloseButton(
      onPressed: canCloseIssue ? () => onCloseIssue('completed') : null,
      minWidth: 120,
      label: '完了',
      icon: Icons.check_rounded,
      backgroundColor: const Color(0xFFECFDF5),
      foregroundColor: const Color(0xFF047857),
      borderColor: const Color(0xFFA7F3D0),
    );
    final closeNotPlannedButton = _IssueEditorCloseButton(
      onPressed: canCloseIssue ? () => onCloseIssue('not_planned') : null,
      minWidth: 120,
      label: '対応なし',
      icon: Icons.do_not_disturb_on_outlined,
      backgroundColor: const Color(0xFFF1F5F9),
      foregroundColor: const Color(0xFF475569),
      borderColor: const Color(0xFFCBD5E1),
    );
    final saveButton = _IssueEditorPrimaryButton(
      onPressed: onSaveIssue,
      icon: isEditing ? Icons.save_outlined : Icons.add_rounded,
      label: isEditing ? '変更を保存' : 'issueを追加',
      minWidth: 148,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(alignment: Alignment.centerLeft, child: cancelButton),
              const SizedBox(height: 10),
              if (canCloseIssue) ...[
                closeCompletedButton,
                const SizedBox(height: 10),
                closeNotPlannedButton,
                const SizedBox(height: 10),
              ],
              saveButton,
            ],
          );
        }

        return Row(
          children: [
            cancelButton,
            const Spacer(),
            if (canCloseIssue) ...[
              closeCompletedButton,
              const SizedBox(width: 8),
              closeNotPlannedButton,
              const SizedBox(width: 12),
            ],
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

class _IssueEditorCloseButton extends StatelessWidget {
  const _IssueEditorCloseButton({
    required this.onPressed,
    required this.minWidth,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
  });

  final VoidCallback? onPressed;
  final double minWidth;
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        disabledBackgroundColor: const Color(0xFFE2E8F0),
        disabledForegroundColor: const Color(0xFF64748B),
        elevation: 0,
        minimumSize: Size(minWidth, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        side: BorderSide(color: borderColor),
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
  final ValueChanged<String> onCloseIssue;
  final VoidCallback onSaveIssue;

  @override
  Widget build(BuildContext context) {
    final closeCompletedButton = _IssueEditorCloseButton(
      onPressed: canCloseIssue ? () => onCloseIssue('completed') : null,
      minWidth: 0,
      label: '完了',
      icon: Icons.check_rounded,
      backgroundColor: const Color(0xFFECFDF5),
      foregroundColor: const Color(0xFF047857),
      borderColor: const Color(0xFFA7F3D0),
    );
    final closeNotPlannedButton = _IssueEditorCloseButton(
      onPressed: canCloseIssue ? () => onCloseIssue('not_planned') : null,
      minWidth: 0,
      label: '対応なし',
      icon: Icons.do_not_disturb_on_outlined,
      backgroundColor: const Color(0xFFF1F5F9),
      foregroundColor: const Color(0xFF475569),
      borderColor: const Color(0xFFCBD5E1),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (canCloseIssue) ...[
              Row(
                children: [
                  Expanded(child: closeCompletedButton),
                  const SizedBox(width: 10),
                  Expanded(child: closeNotPlannedButton),
                ],
              ),
              const SizedBox(height: 10),
            ],
            saveButton,
          ],
        ),
      ),
    );
  }
}

class DialogHeader extends StatelessWidget {
  const DialogHeader({
    super.key,
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
    showOverlaySnackBar(context, 'Issue IDがコピーされました');
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
          validator: validateOptionalHttpUrl,
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
    required this.mergeConflictMessagesByPullRequest,
  });

  final Issue issue;
  final ValueChanged<IssuePullRequest> onOpenDiff;
  final ValueChanged<IssuePullRequest> onMergePullRequest;
  final Map<String, String> mergeConflictMessagesByPullRequest;

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
              mergeConflictMessage:
                  mergeConflictMessagesByPullRequest[_pullRequestMergeConflictKey(
                    issue.repo,
                    entry.$2.number,
                  )],
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
    this.mergeConflictMessage,
    required this.onOpenDiff,
    required this.onMerge,
  });

  final String repository;
  final IssuePullRequest pullRequest;
  final String? mergeConflictMessage;
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
          if (mergeConflictMessage != null) ...[
            const SizedBox(height: 10),
            PullRequestMergeConflictBanner(message: mergeConflictMessage!),
          ],
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 500;
              final diffButton = FilledButton.icon(
                onPressed: onOpenDiff,
                icon: const Icon(Icons.rate_review_rounded, size: 17),
                label: const Text('PR詳細'),
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
                    : () => unawaited(launchUrlExternal(pullRequest.url!)),
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

class PullRequestMergeConflictBanner extends StatelessWidget {
  const PullRequestMergeConflictBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        border: Border.all(color: const Color(0xFFFED7AA)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFC2410C),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Conflictがあります',
                  style: TextStyle(
                    color: Color(0xFF9A3412),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF7C2D12),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
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

class PullRequestDiffSheet extends StatelessWidget {
  const PullRequestDiffSheet({
    super.key,
    required this.issue,
    required this.pullRequest,
    this.buildStatus,
    this.mergeConflictMessage,
    required this.loadDiff,
    required this.onMerge,
  });

  final Issue issue;
  final IssuePullRequest pullRequest;
  final CardBuildStatus? buildStatus;
  final String? mergeConflictMessage;
  final Future<IssuePullRequestDiff> Function() loadDiff;
  final Future<bool> Function()? onMerge;

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
          child: PullRequestDiffView(
            issue: issue,
            pullRequest: pullRequest,
            buildStatus: buildStatus,
            mergeConflictMessage: mergeConflictMessage,
            loadDiff: loadDiff,
            onMerge: onMerge,
            onClose: () => Navigator.of(context).pop(),
            closeIcon: Icons.close_rounded,
            closeTooltip: '閉じる',
            showSheetHandle: true,
          ),
        ),
      ),
    );
  }
}

class PullRequestDiffView extends StatefulWidget {
  const PullRequestDiffView({
    super.key,
    required this.issue,
    required this.pullRequest,
    this.buildStatus,
    this.mergeConflictMessage,
    required this.loadDiff,
    required this.onMerge,
    required this.onClose,
    required this.closeIcon,
    required this.closeTooltip,
    this.showSheetHandle = false,
  });

  final Issue issue;
  final IssuePullRequest pullRequest;
  final CardBuildStatus? buildStatus;
  final String? mergeConflictMessage;
  final Future<IssuePullRequestDiff> Function() loadDiff;
  final Future<bool> Function()? onMerge;
  final VoidCallback onClose;
  final IconData closeIcon;
  final String closeTooltip;
  final bool showSheetHandle;

  @override
  State<PullRequestDiffView> createState() => _PullRequestDiffViewState();
}

class _PullRequestDiffViewState extends State<PullRequestDiffView> {
  late Future<IssuePullRequestDiff> _future;
  var _isMerging = false;
  var _merged = false;

  @override
  void initState() {
    super.initState();
    _future = _loadDiff();
    _merged = widget.pullRequest.merged;
  }

  @override
  void didUpdateWidget(covariant PullRequestDiffView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.issue.id != widget.issue.id ||
        oldWidget.issue.repo != widget.issue.repo ||
        oldWidget.pullRequest.number != widget.pullRequest.number) {
      _future = _loadDiff();
      _isMerging = false;
      _merged = widget.pullRequest.merged;
    }
  }

  Future<IssuePullRequestDiff> _loadDiff() {
    final completer = Completer<IssuePullRequestDiff>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      try {
        widget.loadDiff().then(
          completer.complete,
          onError: completer.completeError,
        );
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  void _retry() {
    final nextFuture = _loadDiff();
    setState(() {
      _future = nextFuture;
    });
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
    final nextFuture = merged ? _loadDiff() : null;
    setState(() {
      _isMerging = false;
      _merged = merged || _merged;
      if (nextFuture != null) {
        _future = nextFuture;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<IssuePullRequestDiff>(
      future: _future,
      builder: (context, snapshot) {
        final diff = snapshot.data;
        return Column(
          children: [
            _PullRequestDiffHeader(
              issue: widget.issue,
              pullRequest: widget.pullRequest,
              diff: diff,
              buildStatus: widget.buildStatus,
              mergeConflictMessage: widget.mergeConflictMessage,
              isMerging: _isMerging,
              merged: _merged || (diff?.merged ?? false),
              onMerge: widget.onMerge == null || _merged ? null : _merge,
              onClose: widget.onClose,
              closeIcon: widget.closeIcon,
              closeTooltip: widget.closeTooltip,
              showSheetHandle: widget.showSheetHandle,
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
    );
  }
}

class _PullRequestDiffHeader extends StatelessWidget {
  const _PullRequestDiffHeader({
    required this.issue,
    required this.pullRequest,
    required this.diff,
    required this.buildStatus,
    required this.mergeConflictMessage,
    required this.isMerging,
    required this.merged,
    required this.onMerge,
    required this.onClose,
    required this.closeIcon,
    required this.closeTooltip,
    required this.showSheetHandle,
  });

  final Issue issue;
  final IssuePullRequest pullRequest;
  final IssuePullRequestDiff? diff;
  final CardBuildStatus? buildStatus;
  final String? mergeConflictMessage;
  final bool isMerging;
  final bool merged;
  final VoidCallback? onMerge;
  final VoidCallback onClose;
  final IconData closeIcon;
  final String closeTooltip;
  final bool showSheetHandle;

  @override
  Widget build(BuildContext context) {
    final title = diff?.title ?? pullRequest.title;
    final url = diff?.url.isNotEmpty == true ? diff!.url : pullRequest.url;
    final headerCi = diff?.ci;
    final headerBuildStatus = buildStatus;
    final activeMergeConflictMessage =
        mergeConflictMessage ?? _pullRequestMergeConflictMessageFromDiff(diff);
    final hasMergeConflict = activeMergeConflictMessage != null;
    return Container(
      padding: EdgeInsets.fromLTRB(20, showSheetHandle ? 12 : 16, 12, 14),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFBFC),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showSheetHandle) ...[
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
          ],
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
                tooltip: closeTooltip,
                onPressed: onClose,
                icon: Icon(closeIcon),
              ),
            ],
          ),
          if (headerBuildStatus != null || headerCi != null) ...[
            const SizedBox(height: 12),
            _PullRequestCiStatusCard(
              ci: headerCi,
              buildStatus: headerBuildStatus,
            ),
          ],
          if (activeMergeConflictMessage != null) ...[
            const SizedBox(height: 12),
            PullRequestMergeConflictBanner(message: activeMergeConflictMessage),
          ],
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 520;
              final openButton = OutlinedButton.icon(
                onPressed: url == null || url.isEmpty
                    ? null
                    : () => unawaited(launchUrlExternal(url)),
                icon: const Icon(Icons.open_in_new_rounded, size: 17),
                label: const Text('GitHub'),
              );
              final ci = diff?.ci;
              final buildStatus = headerBuildStatus;
              final ciPassed =
                  buildStatus?.allChecksPassed == true ||
                  (buildStatus == null && ci?.allPassed == true);
              final mergeButton = FilledButton.icon(
                onPressed: merged || isMerging || hasMergeConflict
                    ? null
                    : onMerge,
                icon: isMerging
                    ? const SizedBox.square(
                        dimension: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        hasMergeConflict
                            ? Icons.warning_amber_rounded
                            : _mergeButtonIcon(ci, buildStatus),
                        size: 17,
                      ),
                label: Text(
                  merged
                      ? 'マージ済み'
                      : hasMergeConflict
                      ? 'Conflictあり'
                      : ciPassed
                      ? 'CI pass・マージ'
                      : _mergeButtonLabel(ci, buildStatus),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: hasMergeConflict
                      ? const Color(0xFFD97706)
                      : _mergeButtonColor(ci, buildStatus),
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

class _PullRequestCiStatusCard extends StatelessWidget {
  const _PullRequestCiStatusCard({required this.ci, required this.buildStatus});

  final PullRequestCiSummary? ci;
  final CardBuildStatus? buildStatus;

  @override
  Widget build(BuildContext context) {
    final dashboardStatus = buildStatus;
    if (dashboardStatus != null) {
      final allPassed = dashboardStatus.allChecksPassed;
      final summary = allPassed
          ? 'CIはすべてpassしています'
          : dashboardStatus.label == 'fail'
          ? '失敗しているCIがあります'
          : dashboardStatus.isSpinning
          ? 'CIがまだ完了していません'
          : 'CIの状態を確認できます';
      return _PullRequestCiStatusFrame(
        color: dashboardStatus.color,
        backgroundColor: dashboardStatus.color.withValues(alpha: 0.08),
        borderColor: dashboardStatus.color.withValues(alpha: 0.22),
        icon: dashboardStatus.icon,
        isSpinning: dashboardStatus.isSpinning,
        summary: summary,
        detail: dashboardStatus.summaryLabel,
        showReady: allPassed,
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => BuildStatusJobsDialog(status: dashboardStatus),
        ),
      );
    }

    final ci = this.ci;
    if (ci == null) {
      return const SizedBox.shrink();
    }
    final style = _ciStatusStyle(ci.status);
    final summary = switch (ci.status) {
      PullRequestCiStatus.success => 'CIはすべてpassしています',
      PullRequestCiStatus.failure => '失敗しているCIがあります',
      PullRequestCiStatus.pending => 'CIがまだ完了していません',
      PullRequestCiStatus.none => 'CIチェックはまだ見つかりません',
      PullRequestCiStatus.unknown => 'CIの一部を確認できませんでした',
    };
    final detail = switch (ci.status) {
      PullRequestCiStatus.success =>
        '${ci.passed} checks passed${ci.skipped > 0 ? ' / ${ci.skipped} skipped' : ''}',
      PullRequestCiStatus.failure =>
        '${ci.failed} failed / ${ci.passed} passed / ${ci.pending} pending',
      PullRequestCiStatus.pending =>
        '${ci.pending} pending / ${ci.passed} passed',
      PullRequestCiStatus.none => 'GitHub checks/statuses: 0',
      PullRequestCiStatus.unknown =>
        '${ci.total} checks found${ci.checksTruncated ? ' / truncated' : ''}',
    };
    return _PullRequestCiStatusFrame(
      color: style.color,
      backgroundColor: style.backgroundColor,
      borderColor: style.borderColor,
      textColor: style.textColor,
      icon: style.icon,
      summary: summary,
      detail: detail,
      showReady: ci.allPassed,
    );
  }
}

class _PullRequestCiStatusFrame extends StatelessWidget {
  const _PullRequestCiStatusFrame({
    required this.color,
    required this.backgroundColor,
    required this.borderColor,
    required this.icon,
    required this.summary,
    required this.detail,
    required this.showReady,
    this.textColor,
    this.isSpinning = false,
    this.onTap,
  });

  final Color color;
  final Color backgroundColor;
  final Color borderColor;
  final Color? textColor;
  final IconData icon;
  final String summary;
  final String detail;
  final bool showReady;
  final bool isSpinning;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final resolvedTextColor = textColor ?? color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: BuildStatusIndicator(
                  icon: icon,
                  color: color,
                  isSpinning: isSpinning,
                  size: 19,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: resolvedTextColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: resolvedTextColor.withValues(alpha: 0.72),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (showReady)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'READY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.open_in_new_rounded,
                color: color.withValues(alpha: 0.75),
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

({
  Color color,
  Color backgroundColor,
  Color borderColor,
  Color textColor,
  IconData icon,
})
_ciStatusStyle(PullRequestCiStatus status) {
  return switch (status) {
    PullRequestCiStatus.success => (
      color: const Color(0xFF047857),
      backgroundColor: const Color(0xFFECFDF5),
      borderColor: const Color(0xFFA7F3D0),
      textColor: const Color(0xFF064E3B),
      icon: Icons.check_circle_rounded,
    ),
    PullRequestCiStatus.failure => (
      color: const Color(0xFFB91C1C),
      backgroundColor: const Color(0xFFFFF1F2),
      borderColor: const Color(0xFFFECACA),
      textColor: const Color(0xFF7F1D1D),
      icon: Icons.error_rounded,
    ),
    PullRequestCiStatus.pending => (
      color: const Color(0xFF2563EB),
      backgroundColor: const Color(0xFFEFF6FF),
      borderColor: const Color(0xFFBFDBFE),
      textColor: const Color(0xFF1E3A8A),
      icon: Icons.pending_rounded,
    ),
    PullRequestCiStatus.none => (
      color: const Color(0xFF64748B),
      backgroundColor: const Color(0xFFF8FAFC),
      borderColor: const Color(0xFFE2E8F0),
      textColor: const Color(0xFF334155),
      icon: Icons.radio_button_unchecked_rounded,
    ),
    PullRequestCiStatus.unknown => (
      color: const Color(0xFFD97706),
      backgroundColor: const Color(0xFFFFFBEB),
      borderColor: const Color(0xFFFDE68A),
      textColor: const Color(0xFF78350F),
      icon: Icons.help_rounded,
    ),
  };
}

extension on CardBuildStatus {
  bool get allChecksPassed {
    return jobs.isNotEmpty &&
        jobs.every((job) => job.status == BuildJobStatus.SUCCESS);
  }
}

Color _mergeButtonColor(
  PullRequestCiSummary? ci,
  CardBuildStatus? buildStatus,
) {
  final dashboardStatus = buildStatus;
  if (dashboardStatus != null) {
    return dashboardStatus.color;
  }
  return switch (ci?.status) {
    PullRequestCiStatus.success => const Color(0xFF047857),
    PullRequestCiStatus.failure => const Color(0xFFB91C1C),
    PullRequestCiStatus.pending => const Color(0xFF2563EB),
    PullRequestCiStatus.unknown => const Color(0xFFD97706),
    PullRequestCiStatus.none || null => const Color(0xFF475569),
  };
}

IconData _mergeButtonIcon(
  PullRequestCiSummary? ci,
  CardBuildStatus? buildStatus,
) {
  final dashboardStatus = buildStatus;
  if (dashboardStatus != null) {
    return dashboardStatus.icon;
  }
  return switch (ci?.status) {
    PullRequestCiStatus.success => Icons.check_circle_rounded,
    PullRequestCiStatus.failure => Icons.error_rounded,
    PullRequestCiStatus.pending => Icons.pending_rounded,
    PullRequestCiStatus.unknown => Icons.help_rounded,
    PullRequestCiStatus.none || null => Icons.call_merge_rounded,
  };
}

String _mergeButtonLabel(
  PullRequestCiSummary? ci,
  CardBuildStatus? buildStatus,
) {
  final dashboardStatus = buildStatus;
  if (dashboardStatus != null) {
    if (dashboardStatus.allChecksPassed) return 'CI pass・マージ';
    if (dashboardStatus.label == 'fail') return 'CI確認・マージ';
    if (dashboardStatus.isSpinning) return 'CI待ち・マージ';
    return 'CI確認・マージ';
  }
  return switch (ci?.status) {
    PullRequestCiStatus.failure => 'CI確認・マージ',
    PullRequestCiStatus.pending => 'CI待ち・マージ',
    PullRequestCiStatus.unknown => 'CI不明・マージ',
    PullRequestCiStatus.success => 'CI pass・マージ',
    PullRequestCiStatus.none || null => 'マージ',
  };
}

class PullRequestDiffBody extends StatelessWidget {
  const PullRequestDiffBody({super.key, required this.diff});

  final IssuePullRequestDiff diff;

  @override
  Widget build(BuildContext context) {
    final commentsCount = diff.comments.length;
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: TabBar(
              labelColor: const Color(0xFF0F172A),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF2563EB),
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
              tabs: [
                Tab(text: 'Diff (${diff.files.length})'),
                Tab(text: 'Comments ($commentsCount)'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _PullRequestDiffTab(diff: diff),
                _PullRequestCommentsTab(diff: diff),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PullRequestDiffTab extends StatelessWidget {
  const _PullRequestDiffTab({required this.diff});

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

class _PullRequestCommentsTab extends StatelessWidget {
  const _PullRequestCommentsTab({required this.diff});

  final IssuePullRequestDiff diff;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      child: diff.comments.isEmpty && !diff.commentsTruncated
          ? const _PullRequestEmptyComments()
          : _PullRequestCommentsPanel(diff: diff),
    );
  }
}

class _PullRequestEmptyComments extends StatelessWidget {
  const _PullRequestEmptyComments();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 28,
            color: Color(0xFF94A3B8),
          ),
          SizedBox(height: 8),
          Text(
            'PRコメントはまだありません',
            style: TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w900,
            ),
          ),
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

class _PullRequestCommentsPanel extends StatelessWidget {
  const _PullRequestCommentsPanel({required this.diff});

  final IssuePullRequestDiff diff;

  @override
  Widget build(BuildContext context) {
    final comments = diff.comments;
    final reviewCount = comments
        .where((comment) => comment.kind == IssuePullRequestCommentKind.review)
        .length;
    final conversationCount = comments.length - reviewCount;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.forum_rounded,
                size: 18,
                color: Color(0xFF2563EB),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'PR comments',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _DiffCountPill(
                label: '$conversationCount conversation',
                color: const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              _DiffCountPill(
                label: '$reviewCount review',
                color: const Color(0xFF2563EB),
              ),
            ],
          ),
          if (diff.commentsTruncated) ...[
            const SizedBox(height: 10),
            const _PullRequestDiffNotice(
              message: 'コメントが多いため、先頭100件ずつを表示しています。',
            ),
          ],
          const SizedBox(height: 10),
          for (final entry in comments.indexed) ...[
            _PullRequestCommentTile(comment: entry.$2),
            if (entry.$1 != comments.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _PullRequestCommentTile extends StatelessWidget {
  const _PullRequestCommentTile({required this.comment});

  final IssuePullRequestComment comment;

  @override
  Widget build(BuildContext context) {
    final isReview = comment.kind == IssuePullRequestCommentKind.review;
    final accentColor = isReview
        ? const Color(0xFF2563EB)
        : const Color(0xFF64748B);
    final location = [
      if (comment.path != null) comment.path!,
      if (comment.line != null) 'L${comment.line}',
    ].join(':');
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: comment.url.isEmpty
            ? null
            : () => unawaited(launchUrlExternal(comment.url)),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isReview ? 'review' : 'conversation',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    comment.author,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (location.isNotEmpty)
                    Text(
                      location,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              MarkdownBody(
                data: _commentPreview(comment.body),
                selectable: true,
                onTapLink: (text, href, title) {
                  if (href == null || href.isEmpty) {
                    return;
                  }
                  unawaited(launchUrlExternal(href));
                },
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 12,
                    height: 1.42,
                    fontWeight: FontWeight.w600,
                  ),
                  strong: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                  ),
                  code: const TextStyle(
                    color: Color(0xFF1D4ED8),
                    backgroundColor: Color(0xFFEFF6FF),
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  blockquote: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 12,
                    height: 1.42,
                    fontWeight: FontWeight.w600,
                  ),
                  blockquoteDecoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    border: const Border(
                      left: BorderSide(color: Color(0xFFCBD5E1), width: 4),
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  listBullet: const TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 12,
                    height: 1.42,
                  ),
                  a: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    decoration: TextDecoration.underline,
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

String _commentPreview(String body) {
  final normalized = body.trim().replaceAll(RegExp(r'\n{3,}'), '\n\n');
  if (normalized.length <= 1200) {
    return normalized;
  }
  return '${normalized.substring(0, 1200).trimRight()}\n...';
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
                filename: file.filename,
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
  const _PatchBlock({required this.filename, required this.patch});

  final String filename;
  final String patch;

  @override
  Widget build(BuildContext context) {
    final lines = diffPatchLines(patch);
    final language = diffLanguageForFilename(filename);
    final lineCountDigits = lines.fold(
      2,
      (digits, line) => math.max(
        digits,
        math.max(
          line.oldLineNumber?.toString().length ?? 0,
          line.newLineNumber?.toString().length ?? 0,
        ),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.data_object_rounded,
                    size: 16,
                    color: Color(0xFF475569),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    language ?? 'plain text',
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${lines.length} lines',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectionArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final line in lines)
                      _PatchLineView(
                        line: line,
                        language: language,
                        lineNumberWidth: lineCountDigits * 8.0 + 18,
                      ),
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

class _PatchLineView extends StatelessWidget {
  const _PatchLineView({
    required this.line,
    required this.language,
    required this.lineNumberWidth,
  });

  final DiffPatchLine line;
  final String? language;
  final double lineNumberWidth;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = switch (line.kind) {
      DiffPatchLineKind.added => const Color(0xFFEFFBF1),
      DiffPatchLineKind.removed => const Color(0xFFFFF1F2),
      DiffPatchLineKind.hunk => const Color(0xFFEFF6FF),
      DiffPatchLineKind.meta => const Color(0xFFFFFBEB),
      DiffPatchLineKind.context => Colors.white,
    };
    final markerColor = switch (line.kind) {
      DiffPatchLineKind.added => const Color(0xFF15803D),
      DiffPatchLineKind.removed => const Color(0xFFB91C1C),
      DiffPatchLineKind.hunk => const Color(0xFF2563EB),
      DiffPatchLineKind.meta => const Color(0xFF92400E),
      DiffPatchLineKind.context => const Color(0xFF64748B),
    };
    final numberColor = switch (line.kind) {
      DiffPatchLineKind.added => const Color(0xFF16A34A),
      DiffPatchLineKind.removed => const Color(0xFFDC2626),
      DiffPatchLineKind.hunk => const Color(0xFF2563EB),
      DiffPatchLineKind.meta => const Color(0xFFD97706),
      DiffPatchLineKind.context => const Color(0xFF94A3B8),
    };
    final codeStyle = const TextStyle(
      color: Color(0xFF24292E),
      fontFamily: 'monospace',
      fontSize: 12,
      height: 1.42,
    );
    final gutterStyle = codeStyle.copyWith(color: numberColor);
    return Container(
      constraints: const BoxConstraints(minWidth: 760),
      color: backgroundColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PatchLineNumber(
            value: line.oldLineNumber,
            width: lineNumberWidth,
            style: gutterStyle,
          ),
          _PatchLineNumber(
            value: line.newLineNumber,
            width: lineNumberWidth,
            style: gutterStyle,
          ),
          Container(
            width: 24,
            padding: const EdgeInsets.only(top: 3),
            alignment: Alignment.topCenter,
            child: Text(
              line.marker,
              style: codeStyle.copyWith(
                color: markerColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 3, 18, 3),
              child: Text.rich(
                _highlightDiffCode(
                  line.content,
                  language: line.kind.isCode ? language : null,
                  baseStyle: line.kind == DiffPatchLineKind.hunk
                      ? codeStyle.copyWith(
                          color: const Color(0xFF1D4ED8),
                          fontWeight: FontWeight.w800,
                        )
                      : codeStyle,
                ),
                softWrap: false,
                overflow: TextOverflow.visible,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PatchLineNumber extends StatelessWidget {
  const _PatchLineNumber({
    required this.value,
    required this.width,
    required this.style,
  });

  final int? value;
  final double width;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(8, 3, 8, 3),
      alignment: Alignment.topRight,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Text(value?.toString() ?? '', style: style),
    );
  }
}

TextSpan _highlightDiffCode(
  String code, {
  required String? language,
  required TextStyle baseStyle,
}) {
  if (code.isEmpty || language == null || code.length > 1000) {
    return TextSpan(text: code, style: baseStyle);
  }
  try {
    final result = _pullRequestDiffHighlighter.highlight(
      code: code,
      language: language,
    );
    final renderer = TextSpanRenderer(baseStyle, githubTheme);
    result.render(renderer);
    return renderer.span ?? TextSpan(text: code, style: baseStyle);
  } catch (_) {
    return TextSpan(text: code, style: baseStyle);
  }
}

final _pullRequestDiffHighlighter = Highlight()
  ..registerLanguages({
    'bash': langBash,
    'c': langC,
    'cpp': langCpp,
    'csharp': langCsharp,
    'css': langCss,
    'dart': langDart,
    'dockerfile': langDockerfile,
    'go': langGo,
    'java': langJava,
    'javascript': langJavascript,
    'json': langJson,
    'kotlin': langKotlin,
    'markdown': langMarkdown,
    'php': langPhp,
    'python': langPython,
    'ruby': langRuby,
    'rust': langRust,
    'scss': langScss,
    'shell': langShell,
    'sql': langSql,
    'swift': langSwift,
    'typescript': langTypescript,
    'xml': langXml,
    'yaml': langYaml,
  });

enum DiffPatchLineKind { context, added, removed, hunk, meta }

extension on DiffPatchLineKind {
  bool get isCode {
    return switch (this) {
      DiffPatchLineKind.context ||
      DiffPatchLineKind.added ||
      DiffPatchLineKind.removed => true,
      DiffPatchLineKind.hunk || DiffPatchLineKind.meta => false,
    };
  }
}

class DiffPatchLine {
  const DiffPatchLine({
    required this.kind,
    required this.content,
    required this.marker,
    this.oldLineNumber,
    this.newLineNumber,
  });

  final DiffPatchLineKind kind;
  final String content;
  final String marker;
  final int? oldLineNumber;
  final int? newLineNumber;
}

List<DiffPatchLine> diffPatchLines(String patch) {
  final parsed = <DiffPatchLine>[];
  var oldLineNumber = 0;
  var newLineNumber = 0;
  for (final rawLine in patch.split('\n')) {
    if (rawLine.startsWith('@@')) {
      final match = RegExp(
        r'^@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@',
      ).firstMatch(rawLine);
      if (match != null) {
        oldLineNumber = int.tryParse(match.group(1) ?? '') ?? oldLineNumber;
        newLineNumber = int.tryParse(match.group(2) ?? '') ?? newLineNumber;
      }
      parsed.add(
        DiffPatchLine(
          kind: DiffPatchLineKind.hunk,
          content: rawLine,
          marker: '',
        ),
      );
      continue;
    }
    if (rawLine.startsWith(r'\ No newline') ||
        rawLine == '... patch truncated in OpenCI preview') {
      parsed.add(
        DiffPatchLine(
          kind: DiffPatchLineKind.meta,
          content: rawLine,
          marker: '',
        ),
      );
      continue;
    }
    if (rawLine.startsWith('+') && !rawLine.startsWith('+++')) {
      parsed.add(
        DiffPatchLine(
          kind: DiffPatchLineKind.added,
          content: rawLine.substring(1),
          marker: '+',
          newLineNumber: newLineNumber,
        ),
      );
      newLineNumber += 1;
      continue;
    }
    if (rawLine.startsWith('-') && !rawLine.startsWith('---')) {
      parsed.add(
        DiffPatchLine(
          kind: DiffPatchLineKind.removed,
          content: rawLine.substring(1),
          marker: '-',
          oldLineNumber: oldLineNumber,
        ),
      );
      oldLineNumber += 1;
      continue;
    }
    final content = rawLine.startsWith(' ') ? rawLine.substring(1) : rawLine;
    parsed.add(
      DiffPatchLine(
        kind: DiffPatchLineKind.context,
        content: content,
        marker: rawLine.startsWith(' ') ? ' ' : '',
        oldLineNumber: oldLineNumber,
        newLineNumber: newLineNumber,
      ),
    );
    oldLineNumber += 1;
    newLineNumber += 1;
  }
  return parsed;
}

String? diffLanguageForFilename(String filename) {
  final path = filename.toLowerCase();
  final basename = path.split('/').last;
  if (basename == 'dockerfile' || basename.startsWith('dockerfile.')) {
    return 'dockerfile';
  }
  if (basename == 'makefile') return 'bash';
  if (basename == 'gemfile') return 'ruby';
  if (basename == 'podfile') return 'ruby';
  if (basename == 'pubspec.yaml' || basename == 'pubspec.yml') return 'yaml';
  final extension = basename.contains('.') ? basename.split('.').last : '';
  return switch (extension) {
    'bash' || 'sh' || 'zsh' => 'bash',
    'c' || 'h' => 'c',
    'cc' || 'cpp' || 'cxx' || 'hpp' => 'cpp',
    'cs' => 'csharp',
    'css' => 'css',
    'dart' => 'dart',
    'go' => 'go',
    'java' => 'java',
    'js' || 'jsx' || 'mjs' || 'cjs' => 'javascript',
    'json' || 'jsonc' => 'json',
    'kt' || 'kts' => 'kotlin',
    'md' || 'mdx' => 'markdown',
    'php' => 'php',
    'py' => 'python',
    'rb' => 'ruby',
    'rs' => 'rust',
    'scss' => 'scss',
    'sql' => 'sql',
    'swift' => 'swift',
    'ts' || 'tsx' => 'typescript',
    'xml' || 'html' || 'htm' || 'svg' => 'xml',
    'yaml' || 'yml' => 'yaml',
    _ => null,
  };
}

String _pullRequestMergeConflictKey(String repository, int number) {
  return '$repository#$number';
}

String? _pullRequestMergeConflictMessageFromDiff(IssuePullRequestDiff? diff) {
  if (diff == null) {
    return null;
  }
  final mergeableState = diff.mergeableState.toLowerCase();
  if (mergeableState == 'dirty' ||
      (diff.mergeable == false && mergeableState.contains('conflict'))) {
    return 'このPRはbase branchとconflictしています。GitHubでconflictを解消してから、もう一度マージしてください。';
  }
  return null;
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
              friendlyError(error ?? '差分を読み込めませんでした'),
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
                  dueDate == null ? '締切なし' : formatDate(dueDate!),
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
