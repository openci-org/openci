part of 'issue_board_ima_page.dart';

class IssueBoardPage extends StatefulWidget {
  const IssueBoardPage({
    super.key,
    this.workspaceId = '',
    this.workspaceName = '個人ワークスペース',
    this.onSwitchTeam,
  });

  final String workspaceId;
  final String workspaceName;
  final VoidCallback? onSwitchTeam;

  @override
  State<IssueBoardPage> createState() => _IssueBoardPageState();
}

class _IssueBoardPageState extends State<IssueBoardPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _boardScrollController = ScrollController();
  late final String _workspaceId;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _issuesSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _githubConnectionSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _buildJobsSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _workspaceSettingsSubscription;
  var _isBootstrapping = true;
  var _isConnectingGitHub = false;
  var _isLoadingRepositories = false;
  var _isImportingIssues = false;
  var _isSyncingIssues = false;
  var _isIssueSearchDialogOpen = false;
  var _hasLoadedIssuesSnapshot = false;
  String? _githubLogin;
  String? _loadError;
  int _enabledRepoCount = 0;
  int _dailyWeightTarget = _defaultDailyWeightTarget;
  BoardViewMode? _boardViewMode;
  final _BoardSidePanel _sidePanel = _BoardSidePanel.workers;
  _CompactBoardDestination _compactDestination =
      _CompactBoardDestination.issueBoard;
  bool _isDesktopRailCollapsed = false;
  Set<String> _enabledRepoFullNames = {};
  final Set<String> _closingIssueIds = {};
  final Set<String> _estimatingIssueIds = {};
  final Set<String> _startingCursorAgentIssueIds = {};
  Map<String, CardBuildStatus> _buildStatusesByPullRequest = {};
  final List<BoardColumn> _columns = [
    BoardColumn(
      id: 'triage',
      title: 'トリアージ',
      description: '新着と要件確認',
      color: const Color(0xFF6366F1),
      issues: [],
    ),
    BoardColumn(
      id: 'backlog',
      title: 'バックログ',
      description: '着手待ち',
      color: const Color(0xFF0EA5E9),
      issues: [],
    ),
    BoardColumn(
      id: 'doing',
      title: '進行中',
      description: '今やっていること',
      color: const Color(0xFFF59E0B),
      issues: [],
    ),
    BoardColumn(
      id: 'review',
      title: 'レビュー',
      description: 'レビューと検証',
      color: const Color(0xFFA855F7),
      issues: [],
    ),
    BoardColumn(
      id: 'done',
      title: '完了',
      description: '今週完了',
      color: const Color(0xFF22C55E),
      issues: [],
    ),
  ];

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: _functionsRegion);

  bool get _isBusy =>
      _isConnectingGitHub ||
      _isLoadingRepositories ||
      _isImportingIssues ||
      _isSyncingIssues;

  List<String> get _enabledRepositoryOptions =>
      (_enabledRepoFullNames.toList()..sort());

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleIssueBoardKeyEvent);
    final user = FirebaseAuth.instance.currentUser;
    _workspaceId = widget.workspaceId.isNotEmpty
        ? widget.workspaceId
        : user?.uid ?? '';
    unawaited(_bootstrapWorkspace());
  }

  bool _handleIssueBoardKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return false;
    }

    if (!mounted || ModalRoute.of(context)?.isCurrent != true) {
      return false;
    }

    if (event.logicalKey != LogicalKeyboardKey.keyK ||
        !HardwareKeyboard.instance.isMetaPressed) {
      return false;
    }

    unawaited(_openIssueSearchDialog());
    return true;
  }

  void _selectCompactDestination(_CompactBoardDestination destination) {
    if (_compactDestination == destination) {
      return;
    }
    setState(() => _compactDestination = destination);
  }

  Future<void> _bootstrapWorkspace() async {
    if (_workspaceId.isEmpty) {
      return;
    }

    try {
      await _ensureWorkspace();
      _listenToWorkspace();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isBootstrapping = false;
        _loadError = _friendlyError(error);
      });
    }
  }

  Future<void> _ensureWorkspace() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();
    final workspaceRef = _firestore.doc('workspaces/$_workspaceId');
    final isPersonalWorkspace = _workspaceId == user.uid;
    if (isPersonalWorkspace) {
      batch.set(workspaceRef, {
        'ownerUid': user.uid,
        'name': widget.workspaceName,
        'updatedAt': now,
        'createdAt': now,
      }, SetOptions(merge: true));
      batch.set(workspaceRef.collection('members').doc(user.uid), {
        'role': 'owner',
        'updatedAt': now,
        'createdAt': now,
      }, SetOptions(merge: true));
    }

    for (final column in _columns) {
      batch.set(
        workspaceRef.collection('statuses').doc(column.id),
        {
          'title': column.title,
          'description': column.description,
          'updatedAt': now,
          'createdAt': now,
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  void _listenToWorkspace() {
    final workspaceRef = _firestore.doc('workspaces/$_workspaceId');
    _issuesSubscription = workspaceRef
        .collection('issues')
        .orderBy('rank')
        .snapshots()
        .listen(_replaceIssuesFromSnapshot, onError: _handleStreamError);
    _githubConnectionSubscription = workspaceRef
        .collection('githubConnections')
        .doc('default')
        .snapshots()
        .listen(_replaceGitHubConnection, onError: _handleStreamError);
    _buildJobsSubscription = _firestore
        .collection(buildJobsCollection)
        .where('teamId', isEqualTo: _workspaceId)
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .listen(_replaceBuildStatuses, onError: _handleStreamError);
    _workspaceSettingsSubscription = workspaceRef.snapshots().listen(
      _replaceWorkspaceSettings,
      onError: _handleStreamError,
    );
  }

  void _replaceWorkspaceSettings(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (!mounted || data == null) {
      return;
    }

    final storedDailyWeightTarget = data['dailyWeightTarget'];
    final repoFullNames = _asList(
      data['syncedGitHubRepoFullNames'],
    ).map(_asString).where((repo) => repo.isNotEmpty).toList();

    setState(() {
      if (storedDailyWeightTarget is int && storedDailyWeightTarget > 0) {
        _dailyWeightTarget = storedDailyWeightTarget;
      }
      _enabledRepoCount = repoFullNames.length;
      _enabledRepoFullNames = repoFullNames.toSet();
    });
  }

  void _replaceIssuesFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (!mounted) {
      return;
    }

    if (_hasLoadedIssuesSnapshot) {
      _applyIssueDocumentChanges(snapshot.docChanges);
      return;
    }

    final nextColumns = [
      for (final column in _columns)
        BoardColumn(
          id: column.id,
          title: column.title,
          description: column.description,
          color: column.color,
          issues: [],
        ),
    ];

    for (final doc in snapshot.docs) {
      final issue = Issue.fromDocument(doc);
      final column = nextColumns.firstWhere(
        (column) => column.id == issue.statusId,
        orElse: () => nextColumns.first,
      );
      column.issues.add(issue);
    }

    setState(() {
      _columns
        ..clear()
        ..addAll(nextColumns);
      _hasLoadedIssuesSnapshot = true;
      _isBootstrapping = false;
      _loadError = null;
    });
  }

  void _applyIssueDocumentChanges(
    List<DocumentChange<Map<String, dynamic>>> changes,
  ) {
    if (changes.isEmpty) {
      setState(() {
        _isBootstrapping = false;
        _loadError = null;
      });
      return;
    }

    setState(() {
      for (final change in changes) {
        switch (change.type) {
          case DocumentChangeType.added:
          case DocumentChangeType.modified:
            final issue = Issue.fromDocument(change.doc);
            _removeIssueFromColumns(issue.id);
            _insertIssueInRankOrder(issue);
            break;
          case DocumentChangeType.removed:
            _removeIssueFromColumns(change.doc.id);
            break;
        }
      }
      _isBootstrapping = false;
      _loadError = null;
    });
  }

  void _removeIssueFromColumns(String issueId) {
    for (final column in _columns) {
      column.issues.removeWhere((issue) => issue.id == issueId);
    }
  }

  void _insertIssueInRankOrder(Issue issue) {
    final column = _columns.firstWhere(
      (column) => column.id == issue.statusId,
      orElse: () => _columns.first,
    );
    final insertIndex = column.issues.indexWhere(
      (candidate) => candidate.rank > issue.rank,
    );
    if (insertIndex == -1) {
      column.issues.add(issue);
      return;
    }
    column.issues.insert(insertIndex, issue);
  }

  void _replaceGitHubConnection(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (!mounted) {
      return;
    }

    setState(() {
      _githubLogin = data?['connected'] == true
          ? _asString(data?['login'])
          : null;
    });
  }

  void _replaceBuildStatuses(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final runsByPullRequest = <String, List<_RecentRunSummary>>{};
    for (final doc in snapshot.docs) {
      final run = _RecentRunSummary.fromDoc(doc);
      if (run == null || run.pullRequestNumber <= 0 || run.repository.isEmpty) {
        continue;
      }
      runsByPullRequest
          .putIfAbsent(
            _buildStatusKey(run.repository, run.pullRequestNumber),
            () => [],
          )
          .add(run);
    }

    final nextStatuses = <String, CardBuildStatus>{};
    for (final entry in runsByPullRequest.entries) {
      final status = CardBuildStatus._fromRuns(entry.value);
      if (status != null) {
        nextStatuses[entry.key] = status;
      }
    }

    if (!mounted ||
        _buildStatusMapSignature(_buildStatusesByPullRequest) ==
            _buildStatusMapSignature(nextStatuses)) {
      return;
    }

    setState(() => _buildStatusesByPullRequest = nextStatuses);
  }

  void _handleStreamError(Object error) {
    if (!mounted) {
      return;
    }

    setState(() {
      _isBootstrapping = false;
      _loadError = _friendlyError(error);
    });
  }

  Future<void> _moveIssue({
    required String issueId,
    required String targetColumnId,
    required int targetIndex,
    bool clearPullRequests = false,
  }) async {
    final sourceColumn = _columns.firstWhere(
      (column) => column.issues.any((issue) => issue.id == issueId),
    );
    final sourceIndex = sourceColumn.issues.indexWhere(
      (issue) => issue.id == issueId,
    );
    final targetColumn = _columns.firstWhere(
      (column) => column.id == targetColumnId,
    );

    if (sourceColumn.id == targetColumnId &&
        sourceIndex == targetIndex &&
        !clearPullRequests) {
      return;
    }

    final movingIssue = sourceColumn.issues[sourceIndex];
    final targetIssues = [
      for (final issue in targetColumn.issues)
        if (issue.id != issueId) issue,
    ];
    final normalizedTargetIndex =
        sourceColumn.id == targetColumnId && sourceIndex < targetIndex
        ? targetIndex - 1
        : targetIndex;
    final insertIndex = normalizedTargetIndex.clamp(0, targetIssues.length);
    final previousRank = insertIndex == 0
        ? null
        : targetIssues[insertIndex - 1].rank;
    final nextRank = insertIndex >= targetIssues.length
        ? null
        : targetIssues[insertIndex].rank;
    final nextRankValue = _rankBetween(previousRank, nextRank);
    final shouldUnlinkPullRequests =
        clearPullRequests || targetColumnId != _reviewStatusId;
    _applyOptimisticIssueMove(
      movingIssue.copyWith(
        statusId: targetColumnId,
        rank: nextRankValue,
        clearClosedAt: targetColumnId != _closedStatusId,
        pullRequests: shouldUnlinkPullRequests
            ? const <IssuePullRequest>[]
            : null,
      ),
    );

    await _firestore
        .doc('workspaces/$_workspaceId/issues/${movingIssue.id}')
        .update({
          'statusId': targetColumnId,
          'rank': nextRankValue,
          if (targetColumnId != _closedStatusId)
            'closedAt': FieldValue.delete(),
          if (shouldUnlinkPullRequests) 'pullRequests': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  void _applyOptimisticIssueMove(Issue issue) {
    if (!mounted) {
      return;
    }

    setState(() {
      _removeIssueFromColumns(issue.id);
      _insertIssueInRankOrder(issue);
    });
  }

  Future<void> _linkIssueToPullRequest({
    required String issueId,
    required String repository,
    required IssuePullRequest pullRequest,
  }) async {
    try {
      final issue = _columns
          .expand((column) => column.issues)
          .firstWhere((issue) => issue.id == issueId);
      final linkId = _pullRequestLinkId(repository, pullRequest.number);

      final issueRef = _firestore.doc(
        'workspaces/$_workspaceId/issues/$issueId',
      );
      final snapshot = await issueRef.get();
      final data = snapshot.data();
      Map<String, dynamic>? existingLink;
      final currentPullRequests = <Map<String, dynamic>>[];
      for (final value in _asList(data?['pullRequests'])) {
        final pullRequest = _asMap(value);
        if (_asString(pullRequest['id']) == linkId) {
          existingLink = pullRequest;
        } else {
          currentPullRequests.add(pullRequest);
        }
      }
      final now = Timestamp.now();
      final nextPullRequests = [
        ...currentPullRequests,
        {
          'id': linkId,
          ...pullRequest.toFirestore(repository: repository),
          'linkedAt': existingLink?['linkedAt'] ?? now,
          'updatedAt': now,
        },
      ];
      final update = <String, Object?>{
        'pullRequests': nextPullRequests,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (issue.statusId != _reviewStatusId &&
          issue.statusId != _closedStatusId) {
        final reviewColumn = _columns.firstWhere(
          (column) => column.id == _reviewStatusId,
        );
        final reviewIssues = [
          for (final candidate in reviewColumn.issues)
            if (candidate.id != issueId) candidate,
        ];
        final previousRank = reviewIssues.isEmpty
            ? null
            : reviewIssues.last.rank;
        update['statusId'] = _reviewStatusId;
        update['rank'] = _rankBetween(previousRank, null);
      }

      final nextStatusId = _asString(update['statusId'], issue.statusId);
      final nextRank = update['rank'] is double
          ? update['rank']! as double
          : issue.rank;
      _applyOptimisticIssueMove(
        issue.copyWith(
          statusId: nextStatusId,
          rank: nextRank,
          pullRequests: [
            for (final existingPullRequest in issue.pullRequests)
              if (existingPullRequest.number != pullRequest.number)
                existingPullRequest,
            pullRequest,
          ],
        ),
      );

      await issueRef.update(update);
      _showSavedSnackBar('PR #${pullRequest.number}に紐づけました');
    } catch (error) {
      _showSavedSnackBar(_friendlyError(error));
    }
  }

  Future<void> _closeIssue(String issueId) async {
    if (_closingIssueIds.contains(issueId)) {
      return;
    }

    final sourceColumn = _columns.firstWhere(
      (column) => column.issues.any((issue) => issue.id == issueId),
    );
    final issue = sourceColumn.issues.firstWhere(
      (issue) => issue.id == issueId,
    );
    if (issue.statusId == _closedStatusId) {
      _showSavedSnackBar('すでに完了しています');
      return;
    }

    final allIssues = _columns.expand((column) => column.issues).toList();
    final subIssuesToClose = _descendantSubIssuesForParent(
      issue,
      allIssues,
    ).where((subIssue) => subIssue.statusId != _closedStatusId).toList();
    final closingIssueIds = {
      issueId,
      for (final subIssue in subIssuesToClose) subIssue.id,
    };

    setState(() => _closingIssueIds.addAll(closingIssueIds));
    try {
      await _moveIssue(
        issueId: issueId,
        targetColumnId: _closedStatusId,
        targetIndex: 0,
      );
      if (subIssuesToClose.isNotEmpty) {
        final batch = _firestore.batch();
        final nowRank = DateTime.now().millisecondsSinceEpoch.toDouble();
        for (var index = 0; index < subIssuesToClose.length; index++) {
          final subIssue = subIssuesToClose[index];
          batch.update(
            _firestore.doc('workspaces/$_workspaceId/issues/${subIssue.id}'),
            {
              'statusId': _closedStatusId,
              'rank': nowRank + index + 1,
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );
        }
        await batch.commit();
      }
      _showSavedSnackBar(
        subIssuesToClose.isEmpty
            ? '完了にしました'
            : '${subIssuesToClose.length}件のsub-issueと一緒に完了にしました',
      );
    } catch (error) {
      _showSavedSnackBar(_friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => _closingIssueIds.removeAll(closingIssueIds));
      }
    }
  }

  Future<void> _openAddIssueDialog({String? initialColumnId}) async {
    final useBottomSheet = _usesBottomSheetEditor;
    final draft = await _showIssueEditor<NewIssueDraft>(
      useBottomSheet: useBottomSheet,
      builder: (context) => AddIssueDialog(
        columns: _columns,
        repositoryOptions: _enabledRepositoryOptions,
        initialColumnId: initialColumnId,
        isBottomSheet: useBottomSheet,
      ),
    );

    if (draft == null) {
      return;
    }

    try {
      await _addIssue(draft);
      _showSavedSnackBar('保存しました');
    } catch (error) {
      _showSavedSnackBar(_friendlyError(error));
    }
  }

  Future<void> _openEditIssueDialog(String issueId) async {
    final sourceColumn = _columns.firstWhere(
      (column) => column.issues.any((issue) => issue.id == issueId),
    );
    final issue = sourceColumn.issues.firstWhere(
      (issue) => issue.id == issueId,
    );
    final allIssues = _columns.expand((column) => column.issues).toList();

    final useBottomSheet = _usesBottomSheetEditor;
    final result = await _showIssueEditor<Object?>(
      useBottomSheet: useBottomSheet,
      builder: (context) => AddIssueDialog(
        columns: _columns,
        repositoryOptions: _enabledRepositoryOptions,
        initialIssue: issue,
        allIssues: allIssues,
        initialColumnId: sourceColumn.id,
        isEstimatingWeight: _estimatingIssueIds.contains(issueId),
        onEstimateIssueWeight: _estimateIssueWeight,
        onOverrideIssueWeight: _overrideIssueWeight,
        isStartingCursorAgent: _startingCursorAgentIssueIds.contains(issueId),
        onStartCursorAgent: _startCursorAgent,
        onCreateGitHubSubIssue: _createGitHubSubIssue,
        isBottomSheet: useBottomSheet,
        workspaceId: _workspaceId,
      ),
    );

    if (result == null) {
      return;
    }

    if (result is CloseIssueDialogResult) {
      await _closeIssue(result.issueId);
      return;
    }

    if (result is EditIssueDialogResult) {
      try {
        await _updateIssue(issueId: result.issueId, draft: result.draft);
        _showSavedSnackBar('保存しました');
      } catch (error) {
        _showSavedSnackBar(_friendlyError(error));
      }
      return;
    }

    if (result is! NewIssueDraft) {
      return;
    }

    try {
      await _updateIssue(issueId: issueId, draft: result);
      _showSavedSnackBar('保存しました');
    } catch (error) {
      _showSavedSnackBar(_friendlyError(error));
    }
  }

  Future<void> _openIssueSearchDialog() async {
    if (_isIssueSearchDialogOpen) {
      return;
    }

    _isIssueSearchDialogOpen = true;
    final hasIssues = _columns.any((column) => column.issues.isNotEmpty);
    if (!hasIssues) {
      _isIssueSearchDialogOpen = false;
      _showSavedSnackBar('検索できるIssueがありません');
      return;
    }

    final result = await showDialog<IssueSearchDialogResult>(
      context: context,
      builder: (context) => IssueSearchDialog(columns: _columns),
    ).whenComplete(() => _isIssueSearchDialogOpen = false);
    if (result == null || !mounted) {
      return;
    }

    await _openEditIssueDialog(result.issueId);
  }

  bool get _usesBottomSheetEditor =>
      MediaQuery.sizeOf(context).width < _compactBoardBreakpoint;

  Future<T?> _showIssueEditor<T>({
    required bool useBottomSheet,
    required WidgetBuilder builder,
  }) {
    if (useBottomSheet) {
      return showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: builder,
      );
    }

    return showDialog<T>(context: context, builder: builder);
  }

  Future<void> _addIssue(NewIssueDraft draft) async {
    final targetColumn = _columns.firstWhere(
      (column) => column.id == draft.columnId,
    );
    final rank = targetColumn.issues.isEmpty
        ? DateTime.now().millisecondsSinceEpoch.toDouble()
        : targetColumn.issues.first.rank - 1000;

    final docRef = _firestore
        .collection('workspaces/$_workspaceId/issues')
        .doc();

    await docRef.set({
      'title': draft.title,
      'body': draft.body,
      'repo': draft.repo,
      'labels': draft.labels,
      'comments': 0,
      'priority': draft.priority.name,
      'statusId': draft.columnId,
      'rank': rank,
      if (draft.githubUrl != null) 'githubIssue': {'url': draft.githubUrl},
      if (draft.dueDate != null) 'dueDate': Timestamp.fromDate(draft.dueDate!),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (draft.repo.isNotEmpty) {
      unawaited(
        _callFunction('createGitHubIssue', {
          ..._issueDraftToFunctionData(draft, rank: rank),
          'issueId': docRef.id,
        }),
      );
    }
  }

  Future<void> _estimateIssueWeight(String issueId) async {
    if (_estimatingIssueIds.contains(issueId)) {
      return;
    }

    setState(() => _estimatingIssueIds.add(issueId));
    try {
      await _callFunction('estimateIssueWeight', {
        'workspaceId': _workspaceId,
        'issueId': issueId,
        'force': true,
      });
      _showSavedSnackBar('Weightを推定しました');
    } catch (error) {
      _showSavedSnackBar(_friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => _estimatingIssueIds.remove(issueId));
      }
    }
  }

  Future<void> _overrideIssueWeight({
    required String issueId,
    required IssueWeightOverrideDraft draft,
  }) async {
    final issue = _columns
        .expand((column) => column.issues)
        .firstWhere((issue) => issue.id == issueId);
    final now = FieldValue.serverTimestamp();
    final updatedBy = FirebaseAuth.instance.currentUser?.uid;
    final actualWeight = draft.actualWeight;
    final data = <String, Object?>{
      'weightEstimate.value': draft.estimateWeight,
      'weightEstimate.status': 'done',
      'weightEstimate.confidence': 1.0,
      'weightEstimate.reason': 'Manual override',
      'weightEstimate.model': 'manual',
      'weightEstimate.promptVersion': 'manual',
      'weightEstimate.source': 'manual',
      'weightEstimate.manualOverride': true,
      'weightEstimate.overriddenAt': now,
      'weightEstimate.updatedAt': now,
      'updatedAt': now,
    };
    if (updatedBy != null) {
      data['weightEstimate.requestedBy'] = updatedBy;
    }

    if (issue.statusId == _closedStatusId) {
      data['resolution.weightValue'] = draft.estimateWeight;
      if (actualWeight != null) {
        data['resolution.actualWeight'] = actualWeight;
        data['resolution.weightDelta'] = draft.estimateWeight - actualWeight;
        data['resolution.actualWeightSource'] = 'manual';
        data['resolution.actualWeightManualOverride'] = true;
        data['resolution.actualWeightOverriddenAt'] = now;
        if (updatedBy != null) {
          data['resolution.actualWeightOverriddenBy'] = updatedBy;
        }
      }
    }

    await _firestore
        .doc('workspaces/$_workspaceId/issues/$issueId')
        .update(data);
    _showSavedSnackBar('Weightを上書きしました');
  }

  Future<void> _startCursorAgent(String issueId) async {
    if (_startingCursorAgentIssueIds.contains(issueId)) {
      return;
    }

    setState(() => _startingCursorAgentIssueIds.add(issueId));
    try {
      await _callFunction('startIssueCursorAgent', {
        'workspaceId': _workspaceId,
        'issueId': issueId,
      });
      _showSavedSnackBar('Cursor agentを開始しました');
    } catch (error) {
      _showSavedSnackBar(_friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => _startingCursorAgentIssueIds.remove(issueId));
      }
    }
  }

  Future<Map<String, dynamic>> _createGitHubSubIssue({
    required String parentIssueId,
    required String title,
    required String body,
  }) async {
    final parentIssue = _columns
        .expand((column) => column.issues)
        .firstWhere((issue) => issue.id == parentIssueId);
    final parentGithubUrl = parentIssue.githubUrl;
    final subIssueRef = _firestore
        .collection('workspaces/$_workspaceId/issues')
        .doc();
    final rank = DateTime.now().millisecondsSinceEpoch.toDouble();
    final subIssueSummary = <String, Object?>{
      'issueId': subIssueRef.id,
      'number': 0,
      'title': title,
      'url': null,
      'state': 'open',
    };

    await subIssueRef.set({
      'title': title,
      'body': body,
      'repo': parentIssue.repo,
      'labels': parentIssue.labels,
      'comments': 0,
      'priority': parentIssue.priority.name,
      'statusId': parentIssue.statusId,
      'rank': rank,
      'githubIssue': {
        'state': 'open',
        'parentIssue': {
          'issueId': parentIssueId,
          'number': _issueNumberFromDisplayId(parentIssue.displayId),
          'url': ?parentGithubUrl,
        },
      },
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    final nextSummaryTotal = (parentIssue.subIssuesSummary?.total ?? 0) + 1;
    final nextSummaryCompleted = parentIssue.subIssuesSummary?.completed ?? 0;
    await _firestore
        .doc('workspaces/$_workspaceId/issues/$parentIssueId')
        .update({
          'githubIssue.subIssues': FieldValue.arrayUnion([subIssueSummary]),
          'githubIssue.subIssuesSummary': {
            'total': nextSummaryTotal,
            'completed': nextSummaryCompleted,
            'percentCompleted': nextSummaryTotal <= 0
                ? 0
                : (nextSummaryCompleted / nextSummaryTotal * 100).round(),
          },
          'updatedAt': FieldValue.serverTimestamp(),
        });

    unawaited(
      _callFunction('createGitHubSubIssue', {
        'workspaceId': _workspaceId,
        'parentIssueId': parentIssueId,
        'issueId': subIssueRef.id,
        'title': title,
        'body': body,
      }).catchError((Object error) {
        if (mounted) {
          _showOverlaySnackBar(context, _friendlyError(error));
        }
        return <String, dynamic>{};
      }),
    );
    return {'issueId': subIssueRef.id, 'number': 0, 'url': ''};
  }

  int _issueNumberFromDisplayId(String displayId) {
    if (!displayId.startsWith('#')) {
      return 0;
    }
    return int.tryParse(displayId.substring(1)) ?? 0;
  }

  Map<String, Object?> _issueDraftToFunctionData(
    NewIssueDraft draft, {
    required double rank,
  }) {
    return {
      'workspaceId': _workspaceId,
      'title': draft.title,
      'body': draft.body,
      'repo': draft.repo,
      'labels': draft.labels,
      'statusId': draft.columnId,
      'priority': draft.priority.name,
      'rank': rank,
      if (draft.dueDate != null) 'dueDate': draft.dueDate!.toIso8601String(),
    };
  }

  Future<void> _updateIssue({
    required String issueId,
    required NewIssueDraft draft,
  }) async {
    final issue = _columns
        .expand((column) => column.issues)
        .firstWhere((issue) => issue.id == issueId);

    final data = _issueDraftToFirestore(draft, rank: issue.rank)
      ..remove('createdAt')
      ..remove('comments');

    await _firestore
        .doc('workspaces/$_workspaceId/issues/$issueId')
        .update(data);
  }

  Map<String, Object?> _issueDraftToFirestore(
    NewIssueDraft draft, {
    required double rank,
  }) {
    return {
      'title': draft.title,
      'body': draft.body,
      'repo': draft.repo,
      'labels': draft.labels,
      'comments': 0,
      'priority': draft.priority.name,
      'statusId': draft.columnId,
      'rank': rank,
      'githubIssue.url': draft.githubUrl ?? FieldValue.delete(),
      'dueDate': draft.dueDate == null
          ? FieldValue.delete()
          : Timestamp.fromDate(draft.dueDate!),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  void _showSavedSnackBar(String message) {
    if (!mounted) {
      return;
    }

    showResponsiveSnackBar(
      context,
      content: Text(message),
      duration: const Duration(milliseconds: 1400),
    );
  }

  Future<void> _connectGitHub() async {
    if (_isConnectingGitHub) {
      return;
    }

    setState(() => _isConnectingGitHub = true);
    try {
      final data = await _callFunction('connectGitHub', {
        'workspaceId': _workspaceId,
      });
      _showSavedSnackBar('GitHub Appに${_asString(data['login'])}として接続しました');
    } catch (error) {
      if (_isGitHubAppNotInstalledError(error)) {
        try {
          await _launchGitHubSetup();
          _showSavedSnackBar('GitHub Appのインストール画面を開きました');
        } catch (setupError) {
          _showSavedSnackBar(_friendlyError(setupError));
        }
      } else {
        _showSavedSnackBar(_friendlyError(error));
      }
    } finally {
      if (mounted) {
        setState(() => _isConnectingGitHub = false);
      }
    }
  }

  Future<void> _launchGitHubSetup() async {
    final data = await _callFunction('createGitHubSetupUrl', {
      'teamId': _workspaceId,
    });
    final url = _asString(data['url']);
    if (url.isEmpty) {
      throw StateError('GitHub setup URL was not returned');
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !await canLaunchUrl(uri)) {
      throw StateError('GitHub setup URL could not be opened');
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _selectRepositories() async {
    if (_isLoadingRepositories) {
      return;
    }

    setState(() => _isLoadingRepositories = true);
    try {
      final selected = await showModalBottomSheet<Set<String>>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        useSafeArea: true,
        builder: (context) => RepositoryPickerBottomSheet(
          initiallySelected: _enabledRepoFullNames,
          loadRepositories: _loadGitHubRepositories,
        ),
      );
      if (selected == null) {
        return;
      }

      final selectedRepoFullNames = selected.toList()..sort();
      await _firestore.doc('workspaces/$_workspaceId').set({
        'syncedGitHubRepoFullNames': selectedRepoFullNames,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _showSavedSnackBar('${selected.length}件のrepoを選択しました');
    } catch (error) {
      _showSavedSnackBar(_friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => _isLoadingRepositories = false);
      }
    }
  }

  Future<List<GitHubRepository>> _loadGitHubRepositories() async {
    final data = await _callFunction('listGitHubRepositories', {
      'workspaceId': _workspaceId,
    });
    return _asList(data['repositories'])
        .map((repo) => GitHubRepository.fromMap(_asMap(repo)))
        .where((repo) => repo.fullName.isNotEmpty)
        .toList();
  }

  Future<void> _importGitHubIssues() async {
    if (_isImportingIssues) {
      return;
    }

    if (_enabledRepoCount == 0) {
      _showSavedSnackBar('先に同期するrepoを選択してください');
      return;
    }

    setState(() => _isImportingIssues = true);
    try {
      final data = await _callFunction('importGitHubIssues', {
        'workspaceId': _workspaceId,
      });
      _showSavedSnackBar(
        '${_asInt(data['repositories'])}件のrepoから${_asInt(data['imported'])}件のissueを取り込みました',
      );
    } catch (error) {
      _showSavedSnackBar(_friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => _isImportingIssues = false);
      }
    }
  }

  Future<void> _syncGitHubIssues() async {
    if (_isSyncingIssues) {
      return;
    }

    setState(() => _isSyncingIssues = true);
    try {
      final data = await _callFunction('syncGitHubIssues', {
        'workspaceId': _workspaceId,
      });
      _showSavedSnackBar(
        '${_asInt(data['synced'])}件同期、${_asInt(data['failed'])}件失敗',
      );
    } catch (error) {
      _showSavedSnackBar(_friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => _isSyncingIssues = false);
      }
    }
  }

  Future<Map<String, dynamic>> _callFunction(
    String name,
    Map<String, Object?> data,
  ) async {
    final result = await _functions.httpsCallable(name).call(data);
    return _asMap(result.data);
  }

  DailyProgressStats _dailyProgressStats(List<Issue> closedIssues) {
    final now = DateTime.now();
    final today = _dateOnly(now);
    final tomorrow = today.add(const Duration(days: 1));
    final recentStart = today.subtract(const Duration(days: 29));
    final paceBuckets = <DateTime, _DailyPaceBucket>{};

    for (final issue in closedIssues) {
      final closedAt = issue.closedAt;
      if (closedAt == null) {
        continue;
      }
      final closedDate = _dateOnly(closedAt);
      final weight = _issueProgressWeight(issue);

      if (!closedDate.isBefore(recentStart) && closedDate.isBefore(tomorrow)) {
        final bucket = paceBuckets.putIfAbsent(
          closedDate,
          _DailyPaceBucket.new,
        );
        bucket.add(closedAt: closedAt, weight: weight, now: now);
      }
    }

    final history = [
      for (var index = 0; index < 30; index++)
        DailyProgressHistoryDay(
          date: today.subtract(Duration(days: index)),
          completedWeight:
              paceBuckets[today.subtract(Duration(days: index))]?.totalWeight ??
              0,
          completedCount:
              paceBuckets[today.subtract(Duration(days: index))]
                  ?.completedCount ??
              0,
          morningWeight:
              paceBuckets[today.subtract(Duration(days: index))]
                  ?.morningWeight ??
              0,
          afternoonWeight:
              paceBuckets[today.subtract(Duration(days: index))]
                  ?.afternoonWeight ??
              0,
        ),
    ];
    final todayBucket = paceBuckets[today] ?? _DailyPaceBucket();
    final historicalBuckets = [
      for (final entry in paceBuckets.entries)
        if (entry.key != today) entry.value,
    ];
    final recentWeight = history.fold<int>(
      0,
      (total, day) => total + day.completedWeight,
    );
    final prediction = _buildDailyProgressPrediction(
      targetWeight: _dailyWeightTarget,
      todayBucket: todayBucket,
      historicalBuckets: historicalBuckets,
      now: now,
    );

    return DailyProgressStats(
      targetWeight: _dailyWeightTarget,
      completedWeight: todayBucket.totalWeight,
      completedCount: todayBucket.completedCount,
      recentAverageWeight: recentWeight / 30,
      history: history,
      prediction: prediction,
    );
  }

  Future<void> _recomputeResolutionWeights() async {
    try {
      final result = await _callFunction('recomputeResolutionWeights', {
        'workspaceId': _workspaceId,
      });
      if (mounted) {
        _showSavedSnackBar(
          'Weight再計算: ${result['updated']}件更新, ${result['skipped']}件スキップ',
        );
      }
    } catch (error) {
      if (mounted) {
        _showSavedSnackBar(_friendlyError(error));
      }
    }
  }

  Future<void> _openDailyWeightTargetDialog(DailyProgressStats stats) async {
    final nextTarget = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DailyProgressSheet(
        currentTarget: _dailyWeightTarget,
        stats: stats,
        onRecomputeWeights: _recomputeResolutionWeights,
      ),
    );

    if (nextTarget == null || !mounted) {
      return;
    }

    setState(() => _dailyWeightTarget = nextTarget);
    unawaited(
      _firestore.doc('workspaces/$_workspaceId').update({
        'dailyWeightTarget': nextTarget,
        'updatedAt': FieldValue.serverTimestamp(),
      }),
    );
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleIssueBoardKeyEvent);
    unawaited(_issuesSubscription?.cancel());
    unawaited(_githubConnectionSubscription?.cancel());
    unawaited(_buildJobsSubscription?.cancel());
    unawaited(_workspaceSettingsSubscription?.cancel());
    _boardScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final openIssues = _columns.fold<int>(
      0,
      (total, column) =>
          column.id == _closedStatusId ? total : total + column.issues.length,
    );
    final closedIssues = _columns
        .where((col) => col.id == _closedStatusId)
        .expand((col) => col.issues)
        .toList();
    final dailyProgressStats = _dailyProgressStats(closedIssues);
    final isCompactLayout =
        MediaQuery.sizeOf(context).width < _compactBoardBreakpoint;
    final boardViewMode =
        _boardViewMode ??
        (isCompactLayout ? BoardViewMode.overview : BoardViewMode.standard);
    final isConnected = _githubLogin != null && _githubLogin!.isNotEmpty;
    final onSignOut = FirebaseAuth.instance.signOut;
    void onRunsTap() =>
        _selectCompactDestination(_CompactBoardDestination.runs);
    void onWorkersTap() =>
        _selectCompactDestination(_CompactBoardDestination.workers);
    void onWorkflowsTap() =>
        _selectCompactDestination(_CompactBoardDestination.workflows);
    void onVariablesTap() =>
        _selectCompactDestination(_CompactBoardDestination.variables);
    void onStoreReleaseTap() =>
        _selectCompactDestination(_CompactBoardDestination.storeRelease);

    return SyncedSpinnerScope(
      child: _IssueBoardShortcuts(
        onAddIssue: () => unawaited(_openAddIssueDialog()),
        onSearchIssues: () => unawaited(_openIssueSearchDialog()),
        onToggleNavigation: () {
          if (isCompactLayout) {
            return;
          }
          setState(
            () => _isDesktopRailCollapsed = !_isDesktopRailCollapsed,
          );
        },
        onDestinationSelected: _selectCompactDestination,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF4F7FB),
          endDrawer: isCompactLayout
              ? null
              : Drawer(
                  width: _sidePanel == _BoardSidePanel.workers ? 420 : 560,
                  shape: const RoundedRectangleBorder(
                    side: BorderSide(color: Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(22),
                    ),
                  ),
                  child: Builder(
                    builder: (context) => _BoardSidePanelDrawer(
                      panel: _sidePanel,
                      onDismiss: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ),
          appBar: isCompactLayout
              ? AppBar(
                  title: Text(
                    _compactDestination.label,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  backgroundColor: const Color(0xFFF4F7FB),
                  foregroundColor: const Color(0xFF0F172A),
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  actions:
                      _compactDestination == _CompactBoardDestination.issueBoard
                      ? [
                          IconButton(
                            tooltip: 'issueを検索',
                            onPressed: () =>
                                unawaited(_openIssueSearchDialog()),
                            icon: const Icon(Icons.search_rounded),
                          ),
                          CompactBoardViewModeButton(
                            value: boardViewMode,
                            onChanged: (mode) =>
                                setState(() => _boardViewMode = mode),
                          ),
                          const SizedBox(width: 4),
                        ]
                      : null,
                )
              : null,
          drawer: isCompactLayout
              ? _CompactBoardDrawer(
                  isConnected: isConnected,
                  isBusy: _isBusy,
                  repoCount: _enabledRepoCount,
                  onConnectGitHub: _connectGitHub,
                  onSelectRepositories: _selectRepositories,
                  onImportIssues: _importGitHubIssues,
                  onSyncIssues: _syncGitHubIssues,
                  onSearchIssues: _openIssueSearchDialog,
                  onSignOut: onSignOut,
                  workspaceName: widget.workspaceName,
                  onSwitchTeam: widget.onSwitchTeam,
                  selectedDestination: _compactDestination,
                  onIssueBoardTap: () => _selectCompactDestination(
                    _CompactBoardDestination.issueBoard,
                  ),
                  onRunsTap: onRunsTap,
                  onWorkersTap: onWorkersTap,
                  onWorkflowsTap: onWorkflowsTap,
                  onVariablesTap: onVariablesTap,
                  onStoreReleaseTap: onStoreReleaseTap,
                )
              : null,
          floatingActionButton:
              isCompactLayout &&
                  _compactDestination == _CompactBoardDestination.issueBoard
              ? FloatingActionButton.extended(
                  onPressed: () => unawaited(_openAddIssueDialog()),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('新規'),
                )
              : null,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final content = SafeArea(
                child:
                    _compactDestination != _CompactBoardDestination.issueBoard
                    ? _CompactDestinationBody(destination: _compactDestination)
                    : Column(
                        children: [
                          if (!isCompactLayout)
                            BoardHeader(
                              openIssues: openIssues,
                              closedIssues: closedIssues,
                              dailyProgressStats: dailyProgressStats,
                              onChangeDailyWeightTarget: () => unawaited(
                                _openDailyWeightTargetDialog(
                                  dailyProgressStats,
                                ),
                              ),
                              onWorkerOverviewTap: onWorkersTap,
                            ),
                          if (_isBootstrapping) const LinearProgressIndicator(),
                          if (isCompactLayout)
                            DailyProgressStrip(
                              stats: dailyProgressStats,
                              isCompact: true,
                              onTap: () => unawaited(
                                _openDailyWeightTargetDialog(
                                  dailyProgressStats,
                                ),
                              ),
                            ),
                          BoardToolbar(
                            onConnectGitHub: _connectGitHub,
                            onSelectRepositories: _selectRepositories,
                            onImportIssues: _importGitHubIssues,
                            onSyncIssues: _syncGitHubIssues,
                            onSearchIssues: _openIssueSearchDialog,
                            boardViewMode: boardViewMode,
                            onBoardViewModeChanged: (mode) =>
                                setState(() => _boardViewMode = mode),
                            githubLogin: _githubLogin,
                            repoCount: _enabledRepoCount,
                            isBusy: _isBusy,
                            onRunsTap: onRunsTap,
                            onWorkersTap: onWorkersTap,
                            onWorkflowsTap: onWorkflowsTap,
                            onVariablesTap: onVariablesTap,
                            onStoreReleaseTap: onStoreReleaseTap,
                            showNavigationActions: isCompactLayout,
                          ),
                          if (_loadError != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                              child: Text(
                                _loadError!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final boardHeight = constraints.maxHeight > 32
                                    ? constraints.maxHeight - 24
                                    : constraints.maxHeight;
                                final isCompactBoard =
                                    constraints.maxWidth <
                                    _compactBoardBreakpoint;
                                final allIssues = _columns
                                    .expand((column) => column.issues)
                                    .toList();
                                final subIssuesByParentId =
                                    _subIssuesByParentId(allIssues);
                                final buildStatusesByIssueId =
                                    _buildStatusesByIssueId(
                                      allIssues,
                                      _buildStatusesByPullRequest,
                                    );
                                final issuesByRepositoryNumber =
                                    _issuesByRepositoryNumber(allIssues);

                                if (boardViewMode == BoardViewMode.overview) {
                                  return OverviewBoard(
                                    columns: _columns,
                                    isCompact: isCompactBoard,
                                    onIssueTapped: _openEditIssueDialog,
                                    onIssueDropped: _moveIssue,
                                  );
                                }

                                if (isCompactBoard) {
                                  return ListView.separated(
                                    controller: _boardScrollController,
                                    padding: const EdgeInsets.fromLTRB(
                                      _boardHorizontalPadding,
                                      12,
                                      _boardHorizontalPadding,
                                      _boardBottomPadding + 72,
                                    ),
                                    itemCount: _columns.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: _boardColumnGap),
                                    itemBuilder: (context, index) {
                                      final column = _columns[index];
                                      return CompactBoardColumnView(
                                        key: ValueKey(column.id),
                                        column: column,
                                        subIssuesByParentId:
                                            subIssuesByParentId,
                                        buildStatusesByIssueId:
                                            buildStatusesByIssueId,
                                        issuesByRepositoryNumber:
                                            issuesByRepositoryNumber,
                                        startingCursorAgentIssueIds:
                                            _startingCursorAgentIssueIds,
                                        requiresLongPressDrag: true,
                                        onIssueDropped: _moveIssue,
                                        onIssueLinkedToPullRequest:
                                            _linkIssueToPullRequest,
                                        onAddIssue: (columnId) => unawaited(
                                          _openAddIssueDialog(
                                            initialColumnId: columnId,
                                          ),
                                        ),
                                        onIssueTapped: _openEditIssueDialog,
                                        onStartCursorAgent: _startCursorAgent,
                                      );
                                    },
                                  );
                                }

                                return Scrollbar(
                                  controller: _boardScrollController,
                                  thumbVisibility: true,
                                  child: SingleChildScrollView(
                                    controller: _boardScrollController,
                                    padding: const EdgeInsets.fromLTRB(
                                      _boardHorizontalPadding,
                                      12,
                                      _boardHorizontalPadding,
                                      _boardBottomPadding,
                                    ),
                                    scrollDirection: Axis.horizontal,
                                    child: SizedBox(
                                      height: boardHeight,
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          for (final column in _columns) ...[
                                            BoardColumnView(
                                              key: ValueKey(column.id),
                                              column: column,
                                              subIssuesByParentId:
                                                  subIssuesByParentId,
                                              buildStatusesByIssueId:
                                                  buildStatusesByIssueId,
                                              issuesByRepositoryNumber:
                                                  issuesByRepositoryNumber,
                                              startingCursorAgentIssueIds:
                                                  _startingCursorAgentIssueIds,
                                              requiresLongPressDrag: false,
                                              onIssueDropped: _moveIssue,
                                              onIssueLinkedToPullRequest:
                                                  _linkIssueToPullRequest,
                                              onAddIssue: (columnId) =>
                                                  unawaited(
                                                    _openAddIssueDialog(
                                                      initialColumnId: columnId,
                                                    ),
                                                  ),
                                              onIssueTapped:
                                                  _openEditIssueDialog,
                                              onStartCursorAgent:
                                                  _startCursorAgent,
                                            ),
                                            if (column != _columns.last)
                                              const SizedBox(
                                                width: _boardColumnGap,
                                              ),
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
              );

              if (isCompactLayout) {
                return content;
              }

              return Row(
                children: [
                  _DesktopBoardNavigationRail(
                    selectedDestination: _compactDestination,
                    workspaceName: widget.workspaceName,
                    extended:
                        constraints.maxWidth >= 960 && !_isDesktopRailCollapsed,
                    onSwitchTeam: widget.onSwitchTeam,
                    onSignOut: onSignOut,
                    onCollapsedChanged: (collapsed) =>
                        setState(() => _isDesktopRailCollapsed = collapsed),
                    onDestinationSelected: _selectCompactDestination,
                  ),
                  const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
                  Expanded(child: content),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _IssueBoardShortcuts extends StatelessWidget {
  const _IssueBoardShortcuts({
    required this.onAddIssue,
    required this.onSearchIssues,
    required this.onToggleNavigation,
    required this.onDestinationSelected,
    required this.child,
  });

  final VoidCallback onAddIssue;
  final VoidCallback onSearchIssues;
  final VoidCallback onToggleNavigation;
  final ValueChanged<_CompactBoardDestination> onDestinationSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bindings = <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.keyN): () {
        if (_hasTextInputFocus()) {
          return;
        }
        onAddIssue();
      },
      const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
          onSearchIssues,
      const SingleActivator(LogicalKeyboardKey.digit1, meta: true): () =>
          onDestinationSelected(_CompactBoardDestination.issueBoard),
      const SingleActivator(LogicalKeyboardKey.digit2, meta: true): () =>
          onDestinationSelected(_CompactBoardDestination.runs),
      const SingleActivator(LogicalKeyboardKey.digit3, meta: true): () =>
          onDestinationSelected(_CompactBoardDestination.workers),
      const SingleActivator(LogicalKeyboardKey.digit4, meta: true): () =>
          onDestinationSelected(_CompactBoardDestination.workflows),
      const SingleActivator(LogicalKeyboardKey.digit5, meta: true): () =>
          onDestinationSelected(_CompactBoardDestination.variables),
      const SingleActivator(LogicalKeyboardKey.digit6, meta: true): () =>
          onDestinationSelected(_CompactBoardDestination.storeRelease),
    };

    if (!kIsWeb) {
      bindings.addAll({
        const SingleActivator(LogicalKeyboardKey.keyT, meta: true): onAddIssue,
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true):
            onToggleNavigation,
      });
    }

    return CallbackShortcuts(
      bindings: bindings,
      child: Focus(autofocus: true, child: child),
    );
  }

  bool _hasTextInputFocus() {
    final context = FocusManager.instance.primaryFocus?.context;
    return context?.findAncestorWidgetOfExactType<EditableText>() != null;
  }
}
