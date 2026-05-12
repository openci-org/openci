import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/build_info.dart';
import 'package:dashboard/build_logs/build_logs_page.dart';
import 'package:dashboard/build_logs/synced_spinner.dart';
import 'package:dashboard/firebase/firestore.dart'
    show
        BuildJobStatus,
        buildJobStatusFromFirestore,
        buildJobsCollection,
        dateTimeFromFirestore,
        workerInstancesCollection;
import 'package:dashboard/firebase_options.dart';
import 'package:dashboard/store_release/store_release_page.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:dashboard/variables/variables_page.dart';
import 'package:dashboard/workers/worker_status_page.dart';
import 'package:dashboard/workflow/list/workflows_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

const _functionsRegion = 'asia-northeast1';
const _reviewStatusId = 'review';
const _closedStatusId = 'done';
const _compactTextScale = 0.94;
const _boardHorizontalPadding = 16.0;
const _boardBottomPadding = 18.0;
const _boardColumnWidth = 280.0;
const _boardColumnGap = 12.0;
const _compactBoardBreakpoint = 640.0;
const _compactColumnCollapsedLimit = 0;
const _mobileDragStartDelay = Duration(milliseconds: 420);
const _defaultDailyWeightTarget = 20;
const _validIssueWeights = [0, 1, 2, 4, 8, 16, 32];
const _openCiRepositoryUrl = 'https://github.com/openci-org/openci';

enum BoardViewMode { standard, overview }

enum _BoardSidePanel { runs, workers, workflows, variables, storeRelease }

enum _CompactBoardDestination {
  issueBoard,
  runs,
  workers,
  workflows,
  variables,
  storeRelease,
}

const _boardNavigationDestinations = [
  _CompactBoardDestination.issueBoard,
  _CompactBoardDestination.runs,
  _CompactBoardDestination.workers,
  _CompactBoardDestination.workflows,
  _CompactBoardDestination.variables,
  _CompactBoardDestination.storeRelease,
];

extension _CompactBoardDestinationLabel on _CompactBoardDestination {
  String get label => switch (this) {
    _CompactBoardDestination.issueBoard => 'ワークスペース',
    _CompactBoardDestination.runs => '実行履歴',
    _CompactBoardDestination.workers => 'ワーカー',
    _CompactBoardDestination.workflows => 'ワークフロー',
    _CompactBoardDestination.variables => '変数',
    _CompactBoardDestination.storeRelease => 'ストアリリース',
  };

  IconData get icon => switch (this) {
    _CompactBoardDestination.issueBoard => Icons.view_kanban_outlined,
    _CompactBoardDestination.runs => Icons.history_rounded,
    _CompactBoardDestination.workers => Icons.dns_outlined,
    _CompactBoardDestination.workflows => Icons.schema_rounded,
    _CompactBoardDestination.variables => Icons.key_rounded,
    _CompactBoardDestination.storeRelease => Icons.rocket_launch_outlined,
  };

  IconData get selectedIcon => switch (this) {
    _CompactBoardDestination.issueBoard => Icons.view_kanban_rounded,
    _CompactBoardDestination.runs => Icons.history_rounded,
    _CompactBoardDestination.workers => Icons.dns_rounded,
    _CompactBoardDestination.workflows => Icons.schema_rounded,
    _CompactBoardDestination.variables => Icons.key_rounded,
    _CompactBoardDestination.storeRelease => Icons.rocket_launch_rounded,
  };
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const IssueBoardApp());
}

class IssueBoardApp extends StatelessWidget {
  const IssueBoardApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2563EB),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'イマ',
      locale: const Locale('ja', 'JP'),
      supportedLocales: const [Locale('ja', 'JP')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => TooltipVisibility(
        visible: false,
        child: child ?? const SizedBox.shrink(),
      ),
      theme: baseTheme.copyWith(
        textTheme: _scaledTextTheme(baseTheme.textTheme),
        primaryTextTheme: _scaledTextTheme(baseTheme.primaryTextTheme),
      ),
      home: const AuthGate(),
    );
  }
}

TextTheme _scaledTextTheme(TextTheme theme) {
  return theme.copyWith(
    displayLarge: _scaledTextStyle(theme.displayLarge),
    displayMedium: _scaledTextStyle(theme.displayMedium),
    displaySmall: _scaledTextStyle(theme.displaySmall),
    headlineLarge: _scaledTextStyle(theme.headlineLarge),
    headlineMedium: _scaledTextStyle(theme.headlineMedium),
    headlineSmall: _scaledTextStyle(theme.headlineSmall),
    titleLarge: _scaledTextStyle(theme.titleLarge),
    titleMedium: _scaledTextStyle(theme.titleMedium),
    titleSmall: _scaledTextStyle(theme.titleSmall),
    bodyLarge: _scaledTextStyle(theme.bodyLarge),
    bodyMedium: _scaledTextStyle(theme.bodyMedium),
    bodySmall: _scaledTextStyle(theme.bodySmall),
    labelLarge: _scaledTextStyle(theme.labelLarge),
    labelMedium: _scaledTextStyle(theme.labelMedium),
    labelSmall: _scaledTextStyle(theme.labelSmall),
  );
}

TextStyle? _scaledTextStyle(TextStyle? style) {
  final fontSize = style?.fontSize;
  if (style == null || fontSize == null) {
    return style;
  }
  return style.copyWith(fontSize: fontSize * _compactTextScale);
}

String? _normalizedOptionalUrl(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String? _validateOptionalHttpUrl(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return null;
  }

  final uri = Uri.tryParse(trimmed);
  final isHttpUrl =
      uri != null &&
      uri.hasScheme &&
      uri.host.isNotEmpty &&
      (uri.scheme == 'https' || uri.scheme == 'http');
  return isHttpUrl ? null : 'URL形式で入力してください';
}

void _showFloatingSnackBar(BuildContext context, String message) {
  showResponsiveSnackBar(
    context,
    content: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis),
    duration: const Duration(milliseconds: 1400),
  );
}

void _showOverlaySnackBar(BuildContext context, String message) {
  showResponsiveSnackBar(
    context,
    content: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis),
    duration: const Duration(milliseconds: 1400),
  );
}

Future<void> _copyTextToClipboard(
  BuildContext context, {
  required String text,
  required String successMessage,
}) async {
  final trimmed = text.trim();
  if (trimmed.isEmpty) {
    return;
  }

  await Clipboard.setData(ClipboardData(text: trimmed));
  if (!context.mounted) {
    return;
  }

  _showFloatingSnackBar(context, successMessage);
}

Future<void> _launchUrlExternal(String url) async {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) {
    return;
  }
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8FAFC),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return const EmailAuthPage();
        }

        return const IssueBoardPage();
      },
    );
  }
}

class EmailAuthPage extends StatefulWidget {
  const EmailAuthPage({super.key});

  @override
  State<EmailAuthPage> createState() => _EmailAuthPageState();
}

class _EmailAuthPageState extends State<EmailAuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _isCreatingAccount = false;
  var _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (_isCreatingAccount) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = _friendlyAuthMessage(error);
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _friendlyAuthMessage(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => 'メールアドレスの形式を確認してください。',
      'user-disabled' => 'このユーザーは無効化されています。',
      'user-not-found' => 'このメールアドレスのユーザーが見つかりません。',
      'wrong-password' || 'invalid-credential' => 'メールアドレスまたはパスワードが違います。',
      'email-already-in-use' => 'このメールアドレスはすでに登録されています。',
      'weak-password' => 'パスワードは6文字以上で入力してください。',
      'operation-not-allowed' => 'Firebase Consoleでメール/パスワード認証を有効にしてください。',
      _ => '認証に失敗しました。${error.code}: ${error.message ?? '詳細不明'}',
    };
  }

  void _toggleMode() {
    setState(() {
      _isCreatingAccount = !_isCreatingAccount;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'IssuePilot',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isCreatingAccount
                              ? 'メールアドレスでアカウントを作成します。'
                              : 'メールアドレスでログインしてください。',
                          style: textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'メールアドレス',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty || !email.contains('@')) {
                              return 'メールアドレスを入力してください。';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'パスワード',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _submit(),
                          validator: (value) {
                            if ((value ?? '').length < 6) {
                              return '6文字以上で入力してください。';
                            }

                            return null;
                          },
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(_isCreatingAccount ? '登録する' : 'ログイン'),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _isSubmitting ? null : _toggleMode,
                          child: Text(
                            _isCreatingAccount ? '既存アカウントでログイン' : '新しいアカウントを作成',
                          ),
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
}

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
      await _ensurePersonalWorkspace();
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

  Future<void> _ensurePersonalWorkspace() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();
    final workspaceRef = _firestore.doc('workspaces/$_workspaceId');
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

    if (!mounted) {
      return;
    }

    setState(() {
      _columns
        ..clear()
        ..addAll(nextColumns);
      _isBootstrapping = false;
      _loadError = null;
    });
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

    if (sourceColumn.id == targetColumnId && sourceIndex == targetIndex) {
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

    await _firestore
        .doc('workspaces/$_workspaceId/issues/${movingIssue.id}')
        .update({
          'statusId': targetColumnId,
          'rank': nextRankValue,
          'updatedAt': FieldValue.serverTimestamp(),
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
      _showSavedSnackBar(_friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => _isConnectingGitHub = false);
      }
    }
  }

  Future<void> _selectRepositories() async {
    if (_isLoadingRepositories) {
      return;
    }

    setState(() => _isLoadingRepositories = true);
    try {
      final data = await _callFunction('listGitHubRepositories', {
        'workspaceId': _workspaceId,
      });
      final repositories = _asList(data['repositories'])
          .map((repo) => GitHubRepository.fromMap(_asMap(repo)))
          .where((repo) => repo.fullName.isNotEmpty)
          .toList();

      if (!mounted) {
        return;
      }

      final selected = await showDialog<Set<String>>(
        context: context,
        builder: (context) => RepositoryPickerDialog(
          repositories: repositories,
          initiallySelected: _enabledRepoFullNames,
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
          backgroundColor: const Color(0xFFF8FAFC),
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
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  backgroundColor: const Color(0xFFF8FAFC),
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
                                      4,
                                      _boardHorizontalPadding,
                                      _boardBottomPadding + 72,
                                    ),
                                    itemCount: _columns.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: _boardColumnGap),
                                    itemBuilder: (context, index) {
                                      final column = _columns[index];
                                      return CompactBoardColumnView(
                                        column: column,
                                        allIssues: allIssues,
                                        buildStatusesByPullRequest:
                                            _buildStatusesByPullRequest,
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
                                      6,
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
                                              column: column,
                                              allIssues: allIssues,
                                              buildStatusesByPullRequest:
                                                  _buildStatusesByPullRequest,
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

class _CompactDestinationBody extends StatelessWidget {
  const _CompactDestinationBody({required this.destination});

  final _CompactBoardDestination destination;

  @override
  Widget build(BuildContext context) {
    return switch (destination) {
      _CompactBoardDestination.issueBoard => const SizedBox.shrink(),
      _CompactBoardDestination.runs => const LogsBody(),
      _CompactBoardDestination.workers => const WorkerStatusBody(),
      _CompactBoardDestination.workflows => const WorkflowsBody(),
      _CompactBoardDestination.variables => const VariablesBody(),
      _CompactBoardDestination.storeRelease => const StoreReleaseBody(),
    };
  }
}

class _DesktopBoardNavigationRail extends StatelessWidget {
  const _DesktopBoardNavigationRail({
    required this.selectedDestination,
    required this.workspaceName,
    required this.extended,
    required this.onSignOut,
    required this.onCollapsedChanged,
    required this.onDestinationSelected,
    this.onSwitchTeam,
  });

  final _CompactBoardDestination selectedDestination;
  final String workspaceName;
  final bool extended;
  final Future<void> Function() onSignOut;
  final ValueChanged<bool> onCollapsedChanged;
  final ValueChanged<_CompactBoardDestination> onDestinationSelected;
  final VoidCallback? onSwitchTeam;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _boardNavigationDestinations.indexOf(
      selectedDestination,
    );

    return SizedBox(
      width: extended ? 216 : 80,
      child: NavigationRail(
        backgroundColor: const Color(0xFFF8FAFC),
        extended: extended,
        minWidth: 80,
        minExtendedWidth: 216,
        groupAlignment: -1,
        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
        labelType: extended ? null : NavigationRailLabelType.all,
        leading: _DesktopRailHeader(
          extended: extended,
          onCollapsedChanged: onCollapsedChanged,
        ),
        trailing: _DesktopRailAccountSection(
          extended: extended,
          workspaceName: workspaceName,
          onSwitchTeam: onSwitchTeam,
          onSignOut: onSignOut,
        ),
        destinations: [
          for (final destination in _boardNavigationDestinations)
            NavigationRailDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: Text(destination.label),
            ),
        ],
        onDestinationSelected: (index) {
          onDestinationSelected(_boardNavigationDestinations[index]);
        },
      ),
    );
  }
}

class _DesktopRailHeader extends StatelessWidget {
  const _DesktopRailHeader({
    required this.extended,
    required this.onCollapsedChanged,
  });

  final bool extended;
  final ValueChanged<bool> onCollapsedChanged;

  @override
  Widget build(BuildContext context) {
    if (!extended) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _OpenCiMark(),
            const SizedBox(height: 12),
            IconButton.filledTonal(
              tooltip: 'ナビゲーションを展開',
              onPressed: () => onCollapsedChanged(false),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 20),
      child: Row(
        children: [
          const _OpenCiMark(),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'OpenCI',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'ナビゲーションを折りたたむ',
            onPressed: () => onCollapsedChanged(true),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
        ],
      ),
    );
  }
}

class _OpenCiMark extends StatelessWidget {
  const _OpenCiMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Text(
        'OC',
        style: TextStyle(
          color: Color(0xFF1D4ED8),
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

class _DesktopRailAccountSection extends StatelessWidget {
  const _DesktopRailAccountSection({
    required this.extended,
    required this.workspaceName,
    required this.onSignOut,
    this.onSwitchTeam,
  });

  final bool extended;
  final String workspaceName;
  final Future<void> Function() onSignOut;
  final VoidCallback? onSwitchTeam;

  @override
  Widget build(BuildContext context) {
    if (!extended) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 18, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _DesktopRailBuildInfo(extended: false),
            if (_railBuildUpdatedAt != null) const SizedBox(height: 4),
            if (onSwitchTeam != null) ...[
              IconButton(
                tooltip: workspaceName,
                onPressed: onSwitchTeam,
                icon: const Icon(Icons.groups_2_outlined),
              ),
              const SizedBox(height: 4),
            ],
            IconButton(
              tooltip: 'サインアウト',
              onPressed: () => unawaited(onSignOut()),
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _DesktopRailBuildInfo(extended: true),
          if (_railBuildUpdatedAt != null) const SizedBox(height: 10),
          if (onSwitchTeam != null) ...[
            _DesktopRailActionTile(
              icon: Icons.groups_2_outlined,
              label: workspaceName,
              onTap: onSwitchTeam!,
            ),
            const SizedBox(height: 8),
          ],
          _DesktopRailActionTile(
            icon: Icons.logout_rounded,
            label: 'サインアウト',
            onTap: () => unawaited(onSignOut()),
          ),
        ],
      ),
    );
  }
}

class _DesktopRailBuildInfo extends StatelessWidget {
  const _DesktopRailBuildInfo({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    final updatedAt = _railBuildUpdatedAt;
    if (updatedAt == null) {
      return const SizedBox.shrink();
    }

    final fullText = _formatRailBuildUpdatedText(updatedAt);
    if (!extended) {
      return Tooltip(
        message: '最終更新: $fullText',
        child: _AnimatedRailInk(
          borderRadius: BorderRadius.circular(12),
          onTap: () => unawaited(_launchUrlExternal(_openCiRepositoryUrl)),
          child: Ink(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Icon(
              Icons.update_rounded,
              size: 20,
              color: Color(0xFF2563EB),
            ),
          ),
        ),
      );
    }

    return _AnimatedRailInk(
      borderRadius: BorderRadius.circular(16),
      onTap: () => unawaited(_launchUrlExternal(_openCiRepositoryUrl)),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.update_rounded,
                size: 17,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '最終更新',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fullText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedRailInk extends StatefulWidget {
  const _AnimatedRailInk({
    required this.borderRadius,
    required this.onTap,
    required this.child,
  });

  final BorderRadius borderRadius;
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_AnimatedRailInk> createState() => _AnimatedRailInkState();
}

class _AnimatedRailInkState extends State<_AnimatedRailInk> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: widget.borderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: widget.borderRadius,
        mouseCursor: SystemMouseCursors.click,
        onTap: widget.onTap,
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return const Color(0xFF2563EB).withValues(alpha: 0.14);
          }
          if (states.contains(WidgetState.hovered)) {
            return const Color(0xFF2563EB).withValues(alpha: 0.08);
          }
          return null;
        }),
        child: widget.child,
      ),
    );
  }
}

String _formatRailBuildUpdatedText(DateTime updatedAt) {
  final formattedDate = DateFormat('MM/dd HH:mm').format(updatedAt);
  final sha = _railBuildSha;
  final shaSuffix = sha.isEmpty ? '' : ' ($sha)';
  return '$formattedDate$shaSuffix';
}

DateTime? get _railBuildUpdatedAt {
  final updatedAt = BuildInfo.updatedAt;
  if (updatedAt != null) {
    return updatedAt;
  }

  return kDebugMode
      ? DateTime.now().subtract(const Duration(minutes: 42))
      : null;
}

String get _railBuildSha {
  if (BuildInfo.sha.isNotEmpty) {
    return BuildInfo.sha;
  }

  return kDebugMode ? 'mock' : '';
}

class _DesktopRailActionTile extends StatelessWidget {
  const _DesktopRailActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF475569)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
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
        title: '実行履歴',
        onDismiss: onDismiss,
        child: const LogsBody(),
      ),
      _BoardSidePanel.workflows => _BoardSidePanelShell(
        icon: Icons.schema_rounded,
        title: 'ワークフロー',
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
              : '$passed/$total ok'
        : passed == total
        ? total == 1
              ? 'ok'
              : '$passed ok'
        : '$passed/$total ok';
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
      isSpinning: active > 0 && !queuedOnly,
      signature: jobs.map((job) => '${job.id}:${job.status.name}').join(','),
      workflowTitle: 'PR checks',
      summaryLabel: summaryLabel,
      jobs: jobs,
      tooltip: 'PR checks: $summaryLabel',
    );
  }
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

String _buildStatusKey(String repository, int pullRequestNumber) {
  return '$repository#$pullRequestNumber';
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
                  _dailyHistoryDateLabel(day.date),
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
  final bool showNavigationActions;

  @override
  Widget build(BuildContext context) {
    final isConnected = githubLogin != null && githubLogin!.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _compactBoardBreakpoint) {
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
                      label: '実行履歴',
                      tooltip: 'CI/CD の実行履歴を開く',
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
                      label: 'ワークフロー',
                      tooltip: '.openci workflows を開く',
                      onPressed: onWorkflowsTap,
                    ),
                    ToolbarChip(
                      icon: Icons.key_rounded,
                      label: '変数',
                      tooltip: '変数 / シークレットを開く',
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

class _CompactBoardDrawer extends StatelessWidget {
  const _CompactBoardDrawer({
    required this.isConnected,
    required this.isBusy,
    required this.repoCount,
    required this.onConnectGitHub,
    required this.onSelectRepositories,
    required this.onImportIssues,
    required this.onSyncIssues,
    required this.onSearchIssues,
    required this.onSignOut,
    required this.workspaceName,
    required this.selectedDestination,
    required this.onIssueBoardTap,
    required this.onRunsTap,
    required this.onWorkersTap,
    required this.onWorkflowsTap,
    required this.onVariablesTap,
    required this.onStoreReleaseTap,
    this.onSwitchTeam,
  });

  final bool isConnected;
  final bool isBusy;
  final int repoCount;
  final VoidCallback onConnectGitHub;
  final VoidCallback onSelectRepositories;
  final VoidCallback onImportIssues;
  final VoidCallback onSyncIssues;
  final VoidCallback onSearchIssues;
  final Future<void> Function() onSignOut;
  final String workspaceName;
  final _CompactBoardDestination selectedDestination;
  final VoidCallback onIssueBoardTap;
  final VoidCallback onRunsTap;
  final VoidCallback onWorkersTap;
  final VoidCallback onWorkflowsTap;
  final VoidCallback onVariablesTap;
  final VoidCallback onStoreReleaseTap;
  final VoidCallback? onSwitchTeam;

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
                  selectedDestination == _CompactBoardDestination.issueBoard,
              onTap: () => runAfterClose(onIssueBoardTap),
            ),
            _CompactDrawerTile(
              icon: Icons.history_rounded,
              label: '実行履歴',
              selected: selectedDestination == _CompactBoardDestination.runs,
              onTap: () => runAfterClose(onRunsTap),
            ),
            _CompactDrawerTile(
              icon: Icons.dns_outlined,
              label: 'ワーカー',
              selected: selectedDestination == _CompactBoardDestination.workers,
              onTap: () => runAfterClose(onWorkersTap),
            ),
            _CompactDrawerTile(
              icon: Icons.schema_rounded,
              label: 'ワークフロー',
              selected:
                  selectedDestination == _CompactBoardDestination.workflows,
              onTap: () => runAfterClose(onWorkflowsTap),
            ),
            _CompactDrawerTile(
              icon: Icons.key_rounded,
              label: '変数',
              selected:
                  selectedDestination == _CompactBoardDestination.variables,
              onTap: () => runAfterClose(onVariablesTap),
            ),
            _CompactDrawerTile(
              icon: Icons.rocket_launch_outlined,
              label: 'ストアリリース',
              selected:
                  selectedDestination == _CompactBoardDestination.storeRelease,
              onTap: () => runAfterClose(onStoreReleaseTap),
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
            const _CompactDrawerSectionLabel('アカウント'),
            _CompactDrawerTile(
              icon: Icons.search_outlined,
              label: 'issue検索',
              onTap: () => runAfterClose(onSearchIssues),
            ),
            if (onSwitchTeam != null)
              _CompactDrawerTile(
                icon: Icons.groups_2_outlined,
                label: 'チームを切り替え',
                onTap: () => runAfterClose(onSwitchTeam!),
              ),
            _CompactDrawerTile(
              icon: Icons.logout_rounded,
              label: 'サインアウト',
              onTap: () {
                closeDrawer();
                unawaited(onSignOut());
              },
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
          letterSpacing: 0.5,
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
      for (final issue in _visibleIssuesForColumn(column))
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
                      letterSpacing: -0.2,
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
                          letterSpacing: 0.2,
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
                      _IssueSearchMetaPill(label: _formatDate(issue.dueDate!)),
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

class RepositoryPickerDialog extends StatefulWidget {
  const RepositoryPickerDialog({
    super.key,
    required this.repositories,
    required this.initiallySelected,
  });

  final List<GitHubRepository> repositories;
  final Set<String> initiallySelected;

  @override
  State<RepositoryPickerDialog> createState() => _RepositoryPickerDialogState();
}

class _RepositoryPickerDialogState extends State<RepositoryPickerDialog> {
  late final Set<String> _selected = {...widget.initiallySelected};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('GitHub repoを選択'),
      content: SizedBox(
        width: 520,
        height: 480,
        child: widget.repositories.isEmpty
            ? const Center(child: Text('repoが見つかりませんでした。'))
            : ListView.builder(
                itemCount: widget.repositories.length,
                itemBuilder: (context, index) {
                  final repo = widget.repositories[index];
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
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: () => setState(_selected.clear),
          child: const Text('クリア'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: Text('${_selected.length}件のrepoを保存'),
        ),
      ],
    );
  }
}

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
        ? '${currentIssue.displayId}を編集します。⌘Enterで保存できます。'
        : 'GitHub issueを作成してボードへ追加します。入力欄にいない時はNで開けます。⌘Enterで保存できます。';
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
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
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
                      padding: dialogPadding.copyWith(top: 6, bottom: 0),
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
    final closeButton = OutlinedButton.icon(
      onPressed: onCloseIssue,
      icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
      label: const Text('issueを完了'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF15803D),
        backgroundColor: const Color(0xFFF0FDF4),
        side: const BorderSide(color: Color(0xFFBBF7D0)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
    final saveButton = FilledButton.icon(
      onPressed: onSaveIssue,
      icon: Icon(isEditing ? Icons.save_outlined : Icons.add_rounded, size: 18),
      label: Text(isEditing ? '変更を保存' : 'issueを追加'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
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

class _BottomSheetHeader extends StatelessWidget {
  const _BottomSheetHeader({required this.title, this.issueDisplayId});

  final String title;
  final String? issueDisplayId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 8, 12),
      decoration: const BoxDecoration(
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
    final closeButton = OutlinedButton.icon(
      onPressed: onCloseIssue,
      icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
      label: const Text('issueを完了'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF15803D),
        backgroundColor: const Color(0xFFF0FDF4),
        side: const BorderSide(color: Color(0xFFBBF7D0)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
    final saveButton = FilledButton.icon(
      onPressed: onSaveIssue,
      icon: Icon(isEditing ? Icons.save_outlined : Icons.add_rounded, size: 18),
      label: Text(isEditing ? '変更を保存' : 'issueを追加'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
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
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (issueDisplayId != null) ...[
                    const SizedBox(width: 8),
                    _IssueIdChip(displayId: issueDisplayId!),
                  ],
                ],
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
                      helperText: '⌘Enterでsub-issueを作成',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: canCreate ? onCreate : null,
                icon: isCreating
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_rounded, size: 18),
                label: Text(isCreating ? '作成中...' : 'sub-issueを作成'),
              ),
              Text(
                isLinkedToGitHub
                    ? 'GitHubにissueを作成して、このissueのsub-issueとして紐づけます。'
                    : 'GitHubに同期されたissueでのみ作成できます。',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
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

class BoardColumnView extends StatelessWidget {
  const BoardColumnView({
    super.key,
    required this.column,
    this.allIssues = const [],
    this.buildStatusesByPullRequest = const {},
    this.startingCursorAgentIssueIds = const {},
    required this.requiresLongPressDrag,
    required this.onIssueDropped,
    this.onIssueLinkedToPullRequest,
    required this.onAddIssue,
    required this.onIssueTapped,
    this.onStartCursorAgent,
  });

  final BoardColumn column;
  final List<Issue> allIssues;
  final Map<String, CardBuildStatus> buildStatusesByPullRequest;
  final Set<String> startingCursorAgentIssueIds;
  final bool requiresLongPressDrag;
  final IssueDropCallback onIssueDropped;
  final IssuePullRequestLinkCallback? onIssueLinkedToPullRequest;
  final ValueChanged<String> onAddIssue;
  final ValueChanged<String> onIssueTapped;
  final ValueChanged<String>? onStartCursorAgent;

  @override
  Widget build(BuildContext context) {
    final visibleIssues = _visibleIssuesForColumn(column);
    final reviewGroups = column.id == _reviewStatusId
        ? _reviewPullRequestGroupsForIssues(visibleIssues)
        : const <ReviewPullRequestGroup>[];

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
          width: _boardColumnWidth,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isHovering
                ? column.color.withValues(alpha: 0.08)
                : Colors.white,
            border: Border.all(
              color: isHovering
                  ? column.color.withValues(alpha: 0.45)
                  : const Color(0xFFE2E8F0),
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ColumnHeader(
                column: column,
                isCompact: false,
                onAddIssue: () => onAddIssue(column.id),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    if (visibleIssues.isEmpty) ...[
                      EmptyColumnIssueCreator(
                        columnTitle: column.title,
                        onPressed: () => onAddIssue(column.id),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (reviewGroups.isNotEmpty)
                      for (final group in reviewGroups) ...[
                        ReviewPullRequestGroupView(
                          group: group,
                          column: column,
                          allIssues: allIssues,
                          buildStatusesByPullRequest:
                              buildStatusesByPullRequest,
                          startingCursorAgentIssueIds:
                              startingCursorAgentIssueIds,
                          requiresLongPressDrag: requiresLongPressDrag,
                          onIssueTapped: onIssueTapped,
                          onSubIssueTap: onIssueTapped,
                          onStartCursorAgent: onStartCursorAgent,
                          onIssueDropped: onIssueDropped,
                          onIssueLinkedToPullRequest:
                              onIssueLinkedToPullRequest,
                        ),
                        const SizedBox(height: 8),
                      ]
                    else
                      for (
                        var index = 0;
                        index < visibleIssues.length;
                        index++
                      ) ...[
                        Builder(
                          builder: (context) {
                            final issue = visibleIssues[index];
                            final rankIndex = column.issues.indexWhere(
                              (candidate) => candidate.id == issue.id,
                            );

                            return IssueCardDropTarget(
                              issue: issue,
                              subIssues: _subIssuesForParent(issue, allIssues),
                              buildStatus: _buildStatusForIssue(
                                issue,
                                buildStatusesByPullRequest,
                              ),
                              sourceColumnId: column.id,
                              index: rankIndex < 0 ? index : rankIndex,
                              isStartingCursorAgent: startingCursorAgentIssueIds
                                  .contains(issue.id),
                              requiresLongPressDrag: requiresLongPressDrag,
                              onTap: () => onIssueTapped(issue.id),
                              onSubIssueTap: onIssueTapped,
                              onStartCursorAgent: onStartCursorAgent == null
                                  ? null
                                  : () => onStartCursorAgent!(issue.id),
                              onIssueDropped: onIssueDropped,
                            );
                          },
                        ),
                        const SizedBox(height: 8),
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

class CompactBoardColumnView extends StatefulWidget {
  const CompactBoardColumnView({
    super.key,
    required this.column,
    this.allIssues = const [],
    this.buildStatusesByPullRequest = const {},
    this.startingCursorAgentIssueIds = const {},
    required this.requiresLongPressDrag,
    required this.onIssueDropped,
    this.onIssueLinkedToPullRequest,
    required this.onAddIssue,
    required this.onIssueTapped,
    this.onStartCursorAgent,
  });

  final BoardColumn column;
  final List<Issue> allIssues;
  final Map<String, CardBuildStatus> buildStatusesByPullRequest;
  final Set<String> startingCursorAgentIssueIds;
  final bool requiresLongPressDrag;
  final IssueDropCallback onIssueDropped;
  final IssuePullRequestLinkCallback? onIssueLinkedToPullRequest;
  final ValueChanged<String> onAddIssue;
  final ValueChanged<String> onIssueTapped;
  final ValueChanged<String>? onStartCursorAgent;

  @override
  State<CompactBoardColumnView> createState() => _CompactBoardColumnViewState();
}

class _CompactBoardColumnViewState extends State<CompactBoardColumnView> {
  var _isShrunk = true;

  @override
  Widget build(BuildContext context) {
    final visibleIssues = _visibleIssuesForColumn(widget.column);
    final displayedIssues = _isShrunk
        ? visibleIssues.take(_compactColumnCollapsedLimit).toList()
        : visibleIssues;
    final reviewGroups = widget.column.id == _reviewStatusId
        ? _reviewPullRequestGroupsForIssues(displayedIssues)
        : const <ReviewPullRequestGroup>[];
    final hiddenIssueCount = visibleIssues.length - displayedIssues.length;
    final canToggleSize = visibleIssues.length > _compactColumnCollapsedLimit;

    return DragTarget<IssueDragData>(
      onWillAcceptWithDetails: (details) =>
          details.data.sourceColumnId != widget.column.id,
      onAcceptWithDetails: (details) {
        widget.onIssueDropped(
          issueId: details.data.issueId,
          targetColumnId: widget.column.id,
          targetIndex: widget.column.issues.length,
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isHovering
                ? widget.column.color.withValues(alpha: 0.08)
                : Colors.white,
            border: Border.all(
              color: isHovering
                  ? widget.column.color.withValues(alpha: 0.45)
                  : const Color(0xFFE2E8F0),
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ColumnHeader(
                column: widget.column,
                isCompact: true,
                onAddIssue: () => widget.onAddIssue(widget.column.id),
              ),
              const SizedBox(height: 10),
              if (visibleIssues.isEmpty) ...[
                EmptyColumnIssueCreator(
                  columnTitle: widget.column.title,
                  onPressed: () => widget.onAddIssue(widget.column.id),
                ),
                const SizedBox(height: 8),
              ],
              if (reviewGroups.isNotEmpty)
                for (final group in reviewGroups) ...[
                  ReviewPullRequestGroupView(
                    group: group,
                    column: widget.column,
                    allIssues: widget.allIssues,
                    buildStatusesByPullRequest:
                        widget.buildStatusesByPullRequest,
                    startingCursorAgentIssueIds:
                        widget.startingCursorAgentIssueIds,
                    requiresLongPressDrag: widget.requiresLongPressDrag,
                    onIssueTapped: widget.onIssueTapped,
                    onSubIssueTap: widget.onIssueTapped,
                    onStartCursorAgent: widget.onStartCursorAgent,
                    onIssueDropped: widget.onIssueDropped,
                    onIssueLinkedToPullRequest:
                        widget.onIssueLinkedToPullRequest,
                  ),
                  const SizedBox(height: 8),
                ]
              else
                for (
                  var index = 0;
                  index < displayedIssues.length;
                  index++
                ) ...[
                  Builder(
                    builder: (context) {
                      final issue = displayedIssues[index];
                      final rankIndex = widget.column.issues.indexWhere(
                        (candidate) => candidate.id == issue.id,
                      );

                      return IssueCardDropTarget(
                        issue: issue,
                        subIssues: _subIssuesForParent(issue, widget.allIssues),
                        buildStatus: _buildStatusForIssue(
                          issue,
                          widget.buildStatusesByPullRequest,
                        ),
                        sourceColumnId: widget.column.id,
                        index: rankIndex < 0 ? index : rankIndex,
                        isStartingCursorAgent: widget
                            .startingCursorAgentIssueIds
                            .contains(issue.id),
                        requiresLongPressDrag: widget.requiresLongPressDrag,
                        onTap: () => widget.onIssueTapped(issue.id),
                        onSubIssueTap: widget.onIssueTapped,
                        onStartCursorAgent: widget.onStartCursorAgent == null
                            ? null
                            : () => widget.onStartCursorAgent!(issue.id),
                        onIssueDropped: widget.onIssueDropped,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              if (canToggleSize) ...[
                InlineColumnSizeButton(
                  isShrunk: _isShrunk,
                  hiddenIssueCount: hiddenIssueCount,
                  totalIssueCount: visibleIssues.length,
                  collapsedIssueCount: _compactColumnCollapsedLimit,
                  onPressed: () => setState(() => _isShrunk = !_isShrunk),
                ),
                const SizedBox(height: 8),
              ],
              IssueDropSlot(
                columnId: widget.column.id,
                index: widget.column.issues.length,
                onIssueDropped: widget.onIssueDropped,
                isLast: true,
              ),
            ],
          ),
        );
      },
    );
  }
}

class ReviewPullRequestGroup {
  const ReviewPullRequestGroup({
    required this.repository,
    required this.pullRequest,
    required this.issues,
  });

  final String repository;
  final IssuePullRequest? pullRequest;
  final List<Issue> issues;
}

class _MutableReviewPullRequestGroup {
  _MutableReviewPullRequestGroup({
    required this.repository,
    required this.pullRequest,
  });

  final String repository;
  final IssuePullRequest? pullRequest;
  final List<Issue> issues = [];
}

class _ReviewLinkedIssueItem {
  const _ReviewLinkedIssueItem({this.issue, this.reference});

  final Issue? issue;
  final IssuePullRequestLinkedIssue? reference;

  int get number => reference?.number ?? issue?.githubNumber ?? 0;
}

List<ReviewPullRequestGroup> _reviewPullRequestGroupsForIssues(
  List<Issue> issues,
) {
  final groups = <String, _MutableReviewPullRequestGroup>{};
  for (final issue in issues) {
    final pullRequest = issue.pullRequests.isEmpty
        ? null
        : issue.pullRequests.last;
    final repository = issue.repo;
    final key = pullRequest == null
        ? 'without-pull-request'
        : '$repository#${pullRequest.number}';
    final group = groups.putIfAbsent(
      key,
      () => _MutableReviewPullRequestGroup(
        repository: repository,
        pullRequest: pullRequest,
      ),
    );
    group.issues.add(issue);
  }

  return [
    for (final group in groups.values)
      ReviewPullRequestGroup(
        repository: group.repository,
        pullRequest: group.pullRequest,
        issues: List.unmodifiable(group.issues),
      ),
  ]..sort(_compareReviewPullRequestGroups);
}

int _compareReviewPullRequestGroups(
  ReviewPullRequestGroup a,
  ReviewPullRequestGroup b,
) {
  final aCreatedAt = a.pullRequest?.createdAt;
  final bCreatedAt = b.pullRequest?.createdAt;
  if (aCreatedAt != null && bCreatedAt != null) {
    final createdAtCompare = aCreatedAt.compareTo(bCreatedAt);
    if (createdAtCompare != 0) {
      return createdAtCompare;
    }
  } else if (aCreatedAt != null) {
    return -1;
  } else if (bCreatedAt != null) {
    return 1;
  }

  final rankCompare = _firstReviewIssueRank(a).compareTo(
    _firstReviewIssueRank(b),
  );
  if (rankCompare != 0) {
    return rankCompare;
  }

  final repositoryCompare = a.repository.compareTo(b.repository);
  if (repositoryCompare != 0) {
    return repositoryCompare;
  }

  return (a.pullRequest?.number ?? 0).compareTo(b.pullRequest?.number ?? 0);
}

double _firstReviewIssueRank(ReviewPullRequestGroup group) {
  return group.issues.isEmpty ? double.infinity : group.issues.first.rank;
}

List<_ReviewLinkedIssueItem> _linkedIssueItemsForPullRequest({
  required ReviewPullRequestGroup group,
  required List<Issue> allIssues,
}) {
  final pullRequest = group.pullRequest;
  final seenNumbers = <int>{};
  final items = <_ReviewLinkedIssueItem>[];

  for (final reference
      in pullRequest?.linkedIssues ?? const <IssuePullRequestLinkedIssue>[]) {
    Issue? issue;
    for (final candidate in allIssues) {
      if (candidate.repo == group.repository &&
          candidate.githubNumber == reference.number) {
        issue = candidate;
        break;
      }
    }
    seenNumbers.add(reference.number);
    items.add(_ReviewLinkedIssueItem(issue: issue, reference: reference));
  }

  for (final issue in group.issues) {
    final issueNumber = issue.githubNumber;
    if (issueNumber > 0 && seenNumbers.contains(issueNumber)) {
      continue;
    }
    if (issueNumber > 0) {
      seenNumbers.add(issueNumber);
    }
    items.add(_ReviewLinkedIssueItem(issue: issue));
  }

  return items;
}

class ReviewPullRequestGroupView extends StatelessWidget {
  const ReviewPullRequestGroupView({
    super.key,
    required this.group,
    required this.column,
    required this.allIssues,
    required this.buildStatusesByPullRequest,
    required this.startingCursorAgentIssueIds,
    required this.requiresLongPressDrag,
    required this.onIssueTapped,
    required this.onSubIssueTap,
    required this.onIssueDropped,
    this.onIssueLinkedToPullRequest,
    this.onStartCursorAgent,
  });

  final ReviewPullRequestGroup group;
  final BoardColumn column;
  final List<Issue> allIssues;
  final Map<String, CardBuildStatus> buildStatusesByPullRequest;
  final Set<String> startingCursorAgentIssueIds;
  final bool requiresLongPressDrag;
  final ValueChanged<String> onIssueTapped;
  final ValueChanged<String> onSubIssueTap;
  final IssueDropCallback onIssueDropped;
  final IssuePullRequestLinkCallback? onIssueLinkedToPullRequest;
  final ValueChanged<String>? onStartCursorAgent;

  @override
  Widget build(BuildContext context) {
    final pullRequest = group.pullRequest;
    final linkedIssueItems = _linkedIssueItemsForPullRequest(
      group: group,
      allIssues: allIssues,
    );
    final buildStatus = pullRequest == null
        ? null
        : buildStatusesByPullRequest[_buildStatusKey(
            group.repository,
            pullRequest.number,
          )];
    final title = pullRequest?.title ?? 'PR未紐づけ';
    final url = pullRequest?.url;
    final isOpenPullRequest =
        pullRequest != null &&
        !pullRequest.merged &&
        pullRequest.state.toLowerCase() == 'open';
    final stateLabel = pullRequest == null
        ? 'no PR'
        : pullRequest.merged
        ? 'merged'
        : pullRequest.state;
    final stateColor = pullRequest == null
        ? const Color(0xFF64748B)
        : pullRequest.merged
        ? const Color(0xFF7C3AED)
        : pullRequest.state == 'closed'
        ? const Color(0xFFB45309)
        : const Color(0xFF15803D);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DragTarget<IssueDragData>(
            onWillAcceptWithDetails: (details) =>
                pullRequest != null &&
                onIssueLinkedToPullRequest != null &&
                !group.issues.any((issue) => issue.id == details.data.issueId),
            onAcceptWithDetails: (details) {
              final targetPullRequest = pullRequest;
              final onLink = onIssueLinkedToPullRequest;
              if (targetPullRequest == null || onLink == null) {
                return;
              }

              unawaited(
                onLink(
                  issueId: details.data.issueId,
                  repository: group.repository,
                  pullRequest: targetPullRequest,
                ),
              );
            },
            builder: (context, candidateData, rejectedData) {
              final isHovering = candidateData.isNotEmpty;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isHovering
                      ? const Color(0xFFEFF6FF)
                      : Colors.transparent,
                  border: Border.all(
                    color: isHovering
                        ? const Color(0xFF60A5FA)
                        : Colors.transparent,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: url == null
                        ? null
                        : () => unawaited(_launchUrlExternal(url)),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 7, 8, 9),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: const Icon(
                                  Icons.alt_route_rounded,
                                  size: 17,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pullRequest == null
                                          ? 'PRなし'
                                          : '${group.repository} #${pullRequest.number}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF475569),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontWeight: FontWeight.w900,
                                        height: 1.25,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 9),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (!isOpenPullRequest)
                                _ReviewGroupPill(
                                  label: stateLabel,
                                  color: stateColor,
                                  icon: pullRequest?.merged == true
                                      ? Icons.call_merge_rounded
                                      : Icons.circle_rounded,
                                ),
                              BuildStatusBadge(status: buildStatus),
                              if (pullRequest != null)
                                const _ReviewGroupPill(
                                  label: 'drop issue to link',
                                  color: Color(0xFF2563EB),
                                  icon: Icons.add_link_rounded,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          for (final entry in linkedIssueItems.indexed) ...[
            Builder(
              builder: (context) {
                final item = entry.$2;
                final issue = item.issue;
                if (issue == null) {
                  final reference = item.reference;
                  if (reference == null) {
                    return const SizedBox.shrink();
                  }
                  return ReviewLinkedIssueReferenceCard(reference: reference);
                }

                final isReviewColumnIssue = group.issues.any(
                  (candidate) => candidate.id == issue.id,
                );
                if (!isReviewColumnIssue) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onIssueTapped(issue.id),
                    child: ReviewGroupIssueCard(issue: issue),
                  );
                }

                final rankIndex = column.issues.indexWhere(
                  (candidate) => candidate.id == issue.id,
                );

                return IssueCardDropTarget(
                  issue: issue,
                  subIssues: _subIssuesForParent(issue, allIssues),
                  buildStatus: pullRequest == null
                      ? _buildStatusForIssue(issue, buildStatusesByPullRequest)
                      : null,
                  isReviewGroupCard: true,
                  sourceColumnId: column.id,
                  index: rankIndex < 0 ? entry.$1 : rankIndex,
                  isStartingCursorAgent: startingCursorAgentIssueIds.contains(
                    issue.id,
                  ),
                  requiresLongPressDrag: requiresLongPressDrag,
                  onTap: () => onIssueTapped(issue.id),
                  onSubIssueTap: onSubIssueTap,
                  onStartCursorAgent: onStartCursorAgent == null
                      ? null
                      : () => onStartCursorAgent!(issue.id),
                  onIssueDropped: onIssueDropped,
                );
              },
            ),
            if (entry.$1 != linkedIssueItems.length - 1)
              const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ReviewGroupPill extends StatelessWidget {
  const _ReviewGroupPill({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

class InlineColumnSizeButton extends StatelessWidget {
  const InlineColumnSizeButton({
    super.key,
    required this.isShrunk,
    required this.hiddenIssueCount,
    required this.totalIssueCount,
    required this.collapsedIssueCount,
    required this.onPressed,
  });

  final bool isShrunk;
  final int hiddenIssueCount;
  final int totalIssueCount;
  final int collapsedIssueCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = isShrunk
        ? 'さらに$hiddenIssueCount件表示（全$totalIssueCount件）'
        : collapsedIssueCount == 0
        ? '縮小して件数だけ表示'
        : '縮小して先頭$collapsedIssueCount件だけ表示';
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          isShrunk
              ? Icons.keyboard_arrow_down_rounded
              : Icons.keyboard_arrow_up_rounded,
          size: 20,
        ),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          foregroundColor: const Color(0xFF2563EB),
          backgroundColor: const Color(0xFFEFF6FF),
          side: const BorderSide(color: Color(0xFFBFDBFE)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class OverviewBoard extends StatelessWidget {
  const OverviewBoard({
    super.key,
    required this.columns,
    required this.isCompact,
    required this.onIssueTapped,
    required this.onIssueDropped,
  });

  final List<BoardColumn> columns;
  final bool isCompact;
  final ValueChanged<String> onIssueTapped;
  final IssueDropCallback onIssueDropped;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: OverviewList(
            columns: columns,
            isCompact: isCompact,
            onIssueTapped: onIssueTapped,
            onIssueDropped: onIssueDropped,
          ),
        ),
      ],
    );
  }
}

class OverviewList extends StatelessWidget {
  const OverviewList({
    super.key,
    required this.columns,
    required this.isCompact,
    required this.onIssueTapped,
    required this.onIssueDropped,
  });

  final List<BoardColumn> columns;
  final bool isCompact;
  final ValueChanged<String> onIssueTapped;
  final IssueDropCallback onIssueDropped;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = isCompact ? _boardBottomPadding + 72 : 14.0;

    if (isCompact) {
      return CompactOverviewList(
        columns: columns,
        bottomPadding: bottomPadding,
        onIssueTapped: onIssueTapped,
        onIssueDropped: onIssueDropped,
      );
    }

    final allIssues = [
      for (final column in columns)
        for (final issue in _visibleIssuesForColumn(column)) issue,
    ];
    final totalWeight = allIssues.fold<int>(
      0,
      (total, issue) =>
          total +
          (issue.statusId == _closedStatusId
              ? issue.resolution?.actualWeight ?? 0
              : issue.weightEstimate?.value ?? 0),
    );
    final summary = OverviewSummaryCard(
      issueCount: allIssues.length,
      totalWeight: totalWeight,
      columnCount: columns.length,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            _boardHorizontalPadding,
            4,
            _boardHorizontalPadding,
            0,
          ),
          child: summary,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              _boardHorizontalPadding,
              0,
              _boardHorizontalPadding,
              bottomPadding,
            ),
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final column in columns) ...[
                  SizedBox(
                    width: 286,
                    child: OverviewSection(
                      column: column,
                      isCompact: false,
                      requiresLongPressDrag: false,
                      fillHeight: true,
                      onIssueTapped: onIssueTapped,
                      onIssueDropped: onIssueDropped,
                    ),
                  ),
                  if (column != columns.last) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class CompactOverviewList extends StatefulWidget {
  const CompactOverviewList({
    super.key,
    required this.columns,
    required this.bottomPadding,
    required this.onIssueTapped,
    required this.onIssueDropped,
  });

  final List<BoardColumn> columns;
  final double bottomPadding;
  final ValueChanged<String> onIssueTapped;
  final IssueDropCallback onIssueDropped;

  @override
  State<CompactOverviewList> createState() => _CompactOverviewListState();
}

class _CompactOverviewListState extends State<CompactOverviewList> {
  final _expandedColumnIds = <String>{};

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        for (final entry in widget.columns.indexed) ...[
          SliverStickyHeader(
            header: Padding(
              padding: EdgeInsets.fromLTRB(
                _boardHorizontalPadding,
                entry.$1 == 0 ? 4 : 8,
                _boardHorizontalPadding,
                0,
              ),
              child: OverviewSectionHeader(
                column: entry.$2,
                isShrunk: !_expandedColumnIds.contains(entry.$2.id),
                onToggleSize: () => setState(() {
                  final columnId = entry.$2.id;
                  if (!_expandedColumnIds.remove(columnId)) {
                    _expandedColumnIds.add(columnId);
                  }
                }),
              ),
            ),
            sliver: _expandedColumnIds.contains(entry.$2.id)
                ? SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: _boardHorizontalPadding,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _CompactOverviewSectionBody(
                        column: entry.$2,
                        onIssueTapped: widget.onIssueTapped,
                        onIssueDropped: widget.onIssueDropped,
                      ),
                    ),
                  )
                : const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
        ],
        SliverToBoxAdapter(child: SizedBox(height: widget.bottomPadding)),
      ],
    );
  }
}

class OverviewSectionHeader extends StatelessWidget {
  const OverviewSectionHeader({
    super.key,
    required this.column,
    required this.isShrunk,
    required this.onToggleSize,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
  });

  final BoardColumn column;
  final bool isShrunk;
  final VoidCallback onToggleSize;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final visibleIssues = _visibleIssuesForColumn(column);
    final totalWeight = visibleIssues.fold<int>(
      0,
      (total, issue) =>
          total +
          (issue.statusId == _closedStatusId
              ? issue.resolution?.actualWeight ?? 0
              : issue.weightEstimate?.value ?? 0),
    );

    return Material(
      color: const Color(0xFFFAFBFC),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onToggleSize,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 9, 8, 8),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 24,
                decoration: BoxDecoration(
                  color: column.color,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  column.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _OverviewMiniPill(
                label: '${visibleIssues.length}件 / W$totalWeight',
                foregroundColor: column.color,
                backgroundColor: column.color.withValues(alpha: 0.1),
              ),
              const SizedBox(width: 4),
              Icon(
                isShrunk
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.keyboard_arrow_up_rounded,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactOverviewSectionBody extends StatelessWidget {
  const _CompactOverviewSectionBody({
    required this.column,
    required this.onIssueTapped,
    required this.onIssueDropped,
  });

  final BoardColumn column;
  final ValueChanged<String> onIssueTapped;
  final IssueDropCallback onIssueDropped;

  @override
  Widget build(BuildContext context) {
    final visibleIssues = _visibleIssuesForColumn(column);

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border.fromBorderSide(BorderSide(color: Color(0xFFE2E8F0))),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
        child: Column(
          children: [
            for (final entry in visibleIssues.indexed) ...[
              Builder(
                builder: (context) {
                  final issue = entry.$2;
                  final rankIndex = column.issues.indexWhere(
                    (candidate) => candidate.id == issue.id,
                  );
                  return OverviewIssueDropTarget(
                    issue: issue,
                    columnId: column.id,
                    index: rankIndex < 0 ? entry.$1 : rankIndex,
                    accentColor: column.color,
                    isCompact: true,
                    requiresLongPressDrag: true,
                    onIssueTapped: onIssueTapped,
                    onIssueDropped: onIssueDropped,
                  );
                },
              ),
              if (entry.$1 != visibleIssues.length - 1)
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
            ],
            OverviewColumnDropSlot(
              columnId: column.id,
              index: column.issues.length,
              onIssueDropped: onIssueDropped,
            ),
          ],
        ),
      ),
    );
  }
}

class OverviewSummaryCard extends StatelessWidget {
  const OverviewSummaryCard({
    super.key,
    required this.issueCount,
    required this.totalWeight,
    required this.columnCount,
  });

  final int issueCount;
  final int totalWeight;
  final int columnCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            '全体リスト',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          _OverviewMiniPill(
            label: '$issueCount件',
            foregroundColor: const Color(0xFF2563EB),
            backgroundColor: const Color(0xFFEFF6FF),
          ),
          _OverviewMiniPill(
            label: 'W$totalWeight',
            foregroundColor: const Color(0xFF15803D),
            backgroundColor: const Color(0xFFDCFCE7),
          ),
          _OverviewMiniPill(
            label: '$columnCount列',
            foregroundColor: const Color(0xFF64748B),
            backgroundColor: const Color(0xFFF1F5F9),
          ),
        ],
      ),
    );
  }
}

class OverviewSection extends StatefulWidget {
  const OverviewSection({
    super.key,
    required this.column,
    required this.isCompact,
    required this.requiresLongPressDrag,
    required this.onIssueTapped,
    required this.onIssueDropped,
    this.fillHeight = false,
  });

  final BoardColumn column;
  final bool isCompact;
  final bool requiresLongPressDrag;
  final ValueChanged<String> onIssueTapped;
  final IssueDropCallback onIssueDropped;
  final bool fillHeight;

  @override
  State<OverviewSection> createState() => _OverviewSectionState();
}

class _OverviewSectionState extends State<OverviewSection> {
  late var _isShrunk = widget.isCompact;

  @override
  void didUpdateWidget(covariant OverviewSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCompact != widget.isCompact) {
      _isShrunk = widget.isCompact;
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleIssues = _visibleIssuesForColumn(widget.column);
    final displayedIssues = widget.isCompact && _isShrunk
        ? visibleIssues.take(_compactColumnCollapsedLimit).toList()
        : visibleIssues;
    final hiddenIssueCount = visibleIssues.length - displayedIssues.length;
    final canToggleSize =
        widget.isCompact && visibleIssues.length > _compactColumnCollapsedLimit;
    final showDropSlot = !widget.isCompact || !_isShrunk;
    final totalWeight = visibleIssues.fold<int>(
      0,
      (total, issue) =>
          total +
          (issue.statusId == _closedStatusId
              ? issue.resolution?.actualWeight ?? 0
              : issue.weightEstimate?.value ?? 0),
    );

    return DragTarget<IssueDragData>(
      onWillAcceptWithDetails: (details) =>
          details.data.sourceColumnId != widget.column.id,
      onAcceptWithDetails: (details) {
        widget.onIssueDropped(
          issueId: details.data.issueId,
          targetColumnId: widget.column.id,
          targetIndex: widget.column.issues.length,
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          decoration: BoxDecoration(
            color: isHovering
                ? widget.column.color.withValues(alpha: 0.06)
                : Colors.white,
            border: Border.all(
              color: isHovering
                  ? widget.column.color.withValues(alpha: 0.38)
                  : const Color(0xFFE2E8F0),
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
                color: const Color(0xFFFAFBFC),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 24,
                      decoration: BoxDecoration(
                        color: widget.column.color,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.column.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _OverviewMiniPill(
                      label: '${visibleIssues.length}件 / W$totalWeight',
                      foregroundColor: widget.column.color,
                      backgroundColor: widget.column.color.withValues(
                        alpha: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.fillHeight)
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      ..._issueRows(displayedIssues),
                      if (canToggleSize)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: InlineColumnSizeButton(
                            isShrunk: _isShrunk,
                            hiddenIssueCount: hiddenIssueCount,
                            totalIssueCount: visibleIssues.length,
                            collapsedIssueCount: _compactColumnCollapsedLimit,
                            onPressed: () =>
                                setState(() => _isShrunk = !_isShrunk),
                          ),
                        ),
                      if (showDropSlot)
                        OverviewColumnDropSlot(
                          columnId: widget.column.id,
                          index: widget.column.issues.length,
                          onIssueDropped: widget.onIssueDropped,
                        ),
                    ],
                  ),
                )
              else ...[
                ..._issueRows(displayedIssues),
                if (canToggleSize)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                    child: InlineColumnSizeButton(
                      isShrunk: _isShrunk,
                      hiddenIssueCount: hiddenIssueCount,
                      totalIssueCount: visibleIssues.length,
                      collapsedIssueCount: _compactColumnCollapsedLimit,
                      onPressed: () => setState(() => _isShrunk = !_isShrunk),
                    ),
                  ),
                if (showDropSlot)
                  OverviewColumnDropSlot(
                    columnId: widget.column.id,
                    index: widget.column.issues.length,
                    onIssueDropped: widget.onIssueDropped,
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  List<Widget> _issueRows(List<Issue> visibleIssues) {
    return [
      for (final entry in visibleIssues.indexed) ...[
        Builder(
          builder: (context) {
            final issue = entry.$2;
            final rankIndex = widget.column.issues.indexWhere(
              (candidate) => candidate.id == issue.id,
            );
            return OverviewIssueDropTarget(
              issue: issue,
              columnId: widget.column.id,
              index: rankIndex < 0 ? entry.$1 : rankIndex,
              accentColor: widget.column.color,
              isCompact: widget.isCompact,
              requiresLongPressDrag: widget.requiresLongPressDrag,
              onIssueTapped: widget.onIssueTapped,
              onIssueDropped: widget.onIssueDropped,
            );
          },
        ),
        if (entry.$1 != visibleIssues.length - 1)
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
      ],
    ];
  }
}

class OverviewIssueDropTarget extends StatelessWidget {
  const OverviewIssueDropTarget({
    super.key,
    required this.issue,
    required this.columnId,
    required this.index,
    required this.accentColor,
    required this.isCompact,
    required this.requiresLongPressDrag,
    required this.onIssueTapped,
    required this.onIssueDropped,
  });

  final Issue issue;
  final String columnId;
  final int index;
  final Color accentColor;
  final bool isCompact;
  final bool requiresLongPressDrag;
  final ValueChanged<String> onIssueTapped;
  final IssueDropCallback onIssueDropped;

  @override
  Widget build(BuildContext context) {
    return DragTarget<IssueDragData>(
      onWillAcceptWithDetails: (details) => details.data.issueId != issue.id,
      onAcceptWithDetails: (details) {
        onIssueDropped(
          issueId: details.data.issueId,
          targetColumnId: columnId,
          targetIndex: index,
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              height: isHovering ? 4 : 0,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            OverviewIssueRow(
              issue: issue,
              sourceColumnId: columnId,
              accentColor: accentColor,
              isCompact: isCompact,
              requiresLongPressDrag: requiresLongPressDrag,
              onTap: () => onIssueTapped(issue.id),
            ),
          ],
        );
      },
    );
  }
}

class OverviewColumnDropSlot extends StatelessWidget {
  const OverviewColumnDropSlot({
    super.key,
    required this.columnId,
    required this.index,
    required this.onIssueDropped,
  });

  final String columnId;
  final int index;
  final IssueDropCallback onIssueDropped;

  @override
  Widget build(BuildContext context) {
    return DragTarget<IssueDragData>(
      onWillAcceptWithDetails: (details) => true,
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
          height: isHovering ? 34 : 10,
          margin: const EdgeInsets.fromLTRB(10, 6, 10, 8),
          decoration: BoxDecoration(
            color: isHovering
                ? const Color(0xFFEFF6FF)
                : const Color(0xFFF8FAFC),
            border: Border.all(
              color: isHovering
                  ? const Color(0xFF93C5FD)
                  : const Color(0xFFE2E8F0),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: isHovering
              ? const Text(
                  'ここに移動',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }
}

class OverviewIssueRow extends StatelessWidget {
  const OverviewIssueRow({
    super.key,
    required this.issue,
    required this.sourceColumnId,
    required this.accentColor,
    required this.isCompact,
    required this.requiresLongPressDrag,
    required this.onTap,
  });

  final Issue issue;
  final String sourceColumnId;
  final Color accentColor;
  final bool isCompact;
  final bool requiresLongPressDrag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final repoName = _overviewRepoName(issue.repo);
    final weight = issue.statusId == _closedStatusId
        ? issue.resolution?.actualWeight
        : issue.weightEstimate?.value;
    final weightPill = weight == null
        ? const SizedBox(width: 38)
        : _OverviewMiniPill(
            label: 'W$weight',
            foregroundColor: accentColor,
            backgroundColor: accentColor.withValues(alpha: 0.1),
          );

    final row = _OverviewIssueRowContent(
      repoName: repoName,
      title: issue.title,
      weightPill: weightPill,
      isCompact: isCompact,
    );

    final data = IssueDragData(
      issueId: issue.id,
      sourceColumnId: sourceColumnId,
    );
    final feedback = Material(
      color: Colors.transparent,
      child: SizedBox(
        width: isCompact ? 320 : 286,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: accentColor.withValues(alpha: 0.35)),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: row,
        ),
      ),
    );
    final child = Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: row),
    );

    if (requiresLongPressDrag) {
      return LongPressDraggable<IssueDragData>(
        data: data,
        delay: _mobileDragStartDelay,
        feedback: feedback,
        childWhenDragging: Opacity(opacity: 0.35, child: row),
        child: child,
      );
    }

    return Draggable<IssueDragData>(
      data: data,
      feedback: feedback,
      childWhenDragging: Opacity(opacity: 0.35, child: row),
      child: child,
    );
  }
}

class _OverviewIssueRowContent extends StatelessWidget {
  const _OverviewIssueRowContent({
    required this.repoName,
    required this.title,
    required this.weightPill,
    required this.isCompact,
  });

  final String repoName;
  final String title;
  final Widget weightPill;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        10,
        isCompact ? 9 : 7,
        10,
        isCompact ? 9 : 7,
      ),
      child: Row(
        crossAxisAlignment: isCompact
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: isCompact ? 58 : 72,
            child: Text(
              repoName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: isCompact ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.24,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Align(alignment: Alignment.topRight, child: weightPill),
        ],
      ),
    );
  }
}

String _overviewRepoName(String repo) {
  final parts = repo.split('/');
  return parts.isEmpty ? repo : parts.last;
}

class _OverviewMiniPill extends StatelessWidget {
  const _OverviewMiniPill({
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final String label;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

List<Issue> _visibleIssuesForColumn(BoardColumn column) {
  if (column.id != _closedStatusId) {
    return column.issues;
  }

  return [...column.issues]..sort(_compareDoneIssues);
}

List<Issue> _subIssuesForParent(Issue parent, List<Issue> allIssues) {
  final subIssues = allIssues
      .where((issue) => issue.parentIssue?.issueId == parent.id)
      .toList();
  subIssues.sort((left, right) => left.rank.compareTo(right.rank));
  return subIssues;
}

List<Issue> _descendantSubIssuesForParent(Issue parent, List<Issue> allIssues) {
  final descendants = <Issue>[];
  final seenIssueIds = <String>{parent.id};
  var frontier = <Issue>[parent];

  while (frontier.isNotEmpty) {
    final nextFrontier = <Issue>[];
    for (final issue in frontier) {
      final children = _subIssuesForParent(issue, allIssues);
      for (final child in children) {
        if (!seenIssueIds.add(child.id)) {
          continue;
        }
        descendants.add(child);
        nextFrontier.add(child);
      }
    }
    frontier = nextFrontier;
  }

  return descendants;
}

int _compareDoneIssues(Issue left, Issue right) {
  final leftClosedAt = left.closedAt;
  final rightClosedAt = right.closedAt;

  if (leftClosedAt != null && rightClosedAt != null) {
    final closedAtComparison = rightClosedAt.compareTo(leftClosedAt);
    if (closedAtComparison != 0) {
      return closedAtComparison;
    }
  }

  return left.rank.compareTo(right.rank);
}

class ColumnHeader extends StatelessWidget {
  const ColumnHeader({
    super.key,
    required this.column,
    required this.isCompact,
    required this.onAddIssue,
  });

  final BoardColumn column;
  final bool isCompact;
  final VoidCallback onAddIssue;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 34,
          decoration: BoxDecoration(
            color: column.color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
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
                  const SizedBox(width: 6),
                  CountPill(count: column.issues.length),
                  const SizedBox(width: 2),
                  AddIssueToColumnButton(
                    columnTitle: column.title,
                    isCompact: isCompact,
                    onPressed: onAddIssue,
                  ),
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

class AddIssueToColumnButton extends StatelessWidget {
  const AddIssueToColumnButton({
    super.key,
    required this.columnTitle,
    required this.isCompact,
    required this.onPressed,
  });

  final String columnTitle;
  final bool isCompact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final buttonSize = isCompact ? 36.0 : 26.0;
    final iconSize = isCompact ? 24.0 : 16.0;

    return SizedBox.square(
      dimension: buttonSize,
      child: IconButton(
        tooltip: '$columnTitleにissueを作成',
        padding: EdgeInsets.zero,
        constraints: BoxConstraints.tightFor(
          width: buttonSize,
          height: buttonSize,
        ),
        onPressed: onPressed,
        icon: Icon(Icons.add_rounded, size: iconSize),
      ),
    );
  }
}

class CountPill extends StatelessWidget {
  const CountPill({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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

class EmptyColumnIssueCreator extends StatelessWidget {
  const EmptyColumnIssueCreator({
    super.key,
    required this.columnTitle,
    required this.onPressed,
  });

  final String columnTitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, color: Color(0xFF94A3B8), size: 24),
          const SizedBox(height: 6),
          const Text(
            'まだチケットがありません',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Tooltip(
            message: '$columnTitleにチケットを作成',
            child: OutlinedButton(
              onPressed: onPressed,
              child: const Text('+ チケット作成'),
            ),
          ),
        ],
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
    this.subIssues = const [],
    this.buildStatus,
    this.isReviewGroupCard = false,
    required this.sourceColumnId,
    required this.index,
    required this.isStartingCursorAgent,
    required this.requiresLongPressDrag,
    required this.onTap,
    this.onSubIssueTap,
    this.onStartCursorAgent,
    required this.onIssueDropped,
  });

  final Issue issue;
  final List<Issue> subIssues;
  final CardBuildStatus? buildStatus;
  final bool isReviewGroupCard;
  final String sourceColumnId;
  final int index;
  final bool isStartingCursorAgent;
  final bool requiresLongPressDrag;
  final VoidCallback onTap;
  final ValueChanged<String>? onSubIssueTap;
  final VoidCallback? onStartCursorAgent;
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
                subIssues: widget.subIssues,
                buildStatus: widget.buildStatus,
                isReviewGroupCard: widget.isReviewGroupCard,
                sourceColumnId: widget.sourceColumnId,
                isStartingCursorAgent: widget.isStartingCursorAgent,
                requiresLongPressDrag: widget.requiresLongPressDrag,
                onTap: widget.onTap,
                onSubIssueTap: widget.onSubIssueTap,
                onStartCursorAgent: widget.onStartCursorAgent,
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

class IssueCardDraggable extends StatefulWidget {
  const IssueCardDraggable({
    super.key,
    required this.issue,
    this.subIssues = const [],
    this.buildStatus,
    this.isReviewGroupCard = false,
    required this.sourceColumnId,
    required this.isStartingCursorAgent,
    required this.requiresLongPressDrag,
    required this.onTap,
    this.onSubIssueTap,
    this.onStartCursorAgent,
  });

  final Issue issue;
  final List<Issue> subIssues;
  final CardBuildStatus? buildStatus;
  final bool isReviewGroupCard;
  final String sourceColumnId;
  final bool isStartingCursorAgent;
  final bool requiresLongPressDrag;
  final VoidCallback onTap;
  final ValueChanged<String>? onSubIssueTap;
  final VoidCallback? onStartCursorAgent;

  @override
  State<IssueCardDraggable> createState() => _IssueCardDraggableState();
}

class _IssueCardDraggableState extends State<IssueCardDraggable> {
  static const _liftPreviewDelay = Duration(milliseconds: 280);
  static const _liftPreviewCancelSlop = 8.0;

  Timer? _liftPreviewTimer;
  Timer? _tapSuppressionTimer;
  Offset? _pressStartPosition;
  bool _isLiftPreviewVisible = false;
  bool _suppressNextTap = false;

  @override
  void dispose() {
    _liftPreviewTimer?.cancel();
    _tapSuppressionTimer?.cancel();
    super.dispose();
  }

  void _startLiftPreviewTimer(PointerDownEvent event) {
    _liftPreviewTimer?.cancel();
    _pressStartPosition = event.position;
    _liftPreviewTimer = Timer(_liftPreviewDelay, () {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLiftPreviewVisible = true;
        _suppressNextTap = true;
      });
    });
  }

  void _cancelLiftPreview() {
    _liftPreviewTimer?.cancel();
    _liftPreviewTimer = null;
    _pressStartPosition = null;

    if (!_isLiftPreviewVisible || !mounted) {
      return;
    }

    setState(() {
      _isLiftPreviewVisible = false;
    });
  }

  void _handlePointerUp() {
    final shouldSuppressTap = _suppressNextTap;
    _cancelLiftPreview();

    if (!shouldSuppressTap) {
      return;
    }

    _tapSuppressionTimer?.cancel();
    _tapSuppressionTimer = Timer(const Duration(milliseconds: 250), () {
      _suppressNextTap = false;
      _tapSuppressionTimer = null;
    });
  }

  void _clearTapSuppression() {
    _tapSuppressionTimer?.cancel();
    _tapSuppressionTimer = null;
    _suppressNextTap = false;
  }

  void _handleTap() {
    final shouldSuppressTap = _suppressNextTap;
    _clearTapSuppression();

    if (shouldSuppressTap) {
      return;
    }

    widget.onTap();
  }

  void _finishDragInteraction() {
    _cancelLiftPreview();
    _clearTapSuppression();
  }

  void _handlePointerMove(PointerMoveEvent event) {
    final startPosition = _pressStartPosition;
    if (startPosition == null || _isLiftPreviewVisible) {
      return;
    }

    if ((event.position - startPosition).distance > _liftPreviewCancelSlop) {
      _liftPreviewTimer?.cancel();
      _liftPreviewTimer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = IssueDragData(
      issueId: widget.issue.id,
      sourceColumnId: widget.sourceColumnId,
    );
    Widget buildCard({
      bool isDragging = false,
      bool isDragPlaceholder = false,
      bool includeActions = true,
    }) {
      if (widget.isReviewGroupCard) {
        return ReviewGroupIssueCard(
          issue: widget.issue,
          isDragging: isDragging,
          isDragPlaceholder: isDragPlaceholder,
        );
      }

      return IssueCard(
        issue: widget.issue,
        subIssues: widget.subIssues,
        buildStatus: widget.buildStatus,
        onSubIssueTap: widget.onSubIssueTap,
        isDragging: isDragging,
        isDragPlaceholder: isDragPlaceholder,
        isStartingCursorAgent: includeActions && widget.isStartingCursorAgent,
        onStartCursorAgent: includeActions ? widget.onStartCursorAgent : null,
      );
    }

    final feedback = Material(
      color: Colors.transparent,
      child: SizedBox(
        width: 290,
        child: Opacity(
          opacity: 0.96,
          child: Transform.translate(
            offset: const Offset(0, -8),
            child: Transform.rotate(
              angle: -0.035,
              child: Transform.scale(
                scale: 1.04,
                child: buildCard(isDragging: true, includeActions: false),
              ),
            ),
          ),
        ),
      ),
    );
    final childWhenDragging = Transform.scale(
      scale: 0.98,
      child: Opacity(
        opacity: 0.28,
        child: buildCard(isDragPlaceholder: true, includeActions: false),
      ),
    );
    final child = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _isLiftPreviewVisible ? 1.025 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(
            0,
            _isLiftPreviewVisible ? -6 : 0,
            0,
          ),
          child: buildCard(isDragging: _isLiftPreviewVisible),
        ),
      ),
    );

    final draggable = widget.requiresLongPressDrag
        ? LongPressDraggable<IssueDragData>(
            data: data,
            delay: _mobileDragStartDelay,
            hitTestBehavior: HitTestBehavior.opaque,
            onDragStarted: _finishDragInteraction,
            onDragCompleted: _finishDragInteraction,
            onDraggableCanceled: (_, _) => _finishDragInteraction(),
            onDragEnd: (_) => _finishDragInteraction(),
            feedback: feedback,
            childWhenDragging: childWhenDragging,
            child: child,
          )
        : Draggable<IssueDragData>(
            data: data,
            hitTestBehavior: HitTestBehavior.opaque,
            onDragStarted: _finishDragInteraction,
            onDragCompleted: _finishDragInteraction,
            onDraggableCanceled: (_, _) => _finishDragInteraction(),
            onDragEnd: (_) => _finishDragInteraction(),
            feedback: feedback,
            childWhenDragging: childWhenDragging,
            child: child,
          );

    if (widget.requiresLongPressDrag) {
      return draggable;
    }

    return Listener(
      onPointerDown: _startLiftPreviewTimer,
      onPointerMove: _handlePointerMove,
      onPointerUp: (_) => _handlePointerUp(),
      onPointerCancel: (_) => _finishDragInteraction(),
      child: draggable,
    );
  }
}

class IssueCard extends StatelessWidget {
  const IssueCard({
    super.key,
    required this.issue,
    this.subIssues = const [],
    this.buildStatus,
    this.onSubIssueTap,
    this.isDragging = false,
    this.isDragPlaceholder = false,
    this.isStartingCursorAgent = false,
    this.onStartCursorAgent,
  });

  final Issue issue;
  final List<Issue> subIssues;
  final CardBuildStatus? buildStatus;
  final ValueChanged<String>? onSubIssueTap;
  final bool isDragging;
  final bool isDragPlaceholder;
  final bool isStartingCursorAgent;
  final VoidCallback? onStartCursorAgent;

  @override
  Widget build(BuildContext context) {
    final githubUrl = issue.githubUrl;
    final weightEstimate = issue.weightEstimate;
    final cardWeight = issue.statusId == _closedStatusId
        ? issue.resolution?.actualWeight
        : weightEstimate?.value;
    final cardWeightTooltip = issue.statusId == _closedStatusId
        ? '実績weight $cardWeight'
        : 'Weight $cardWeight / 信頼度 ${((weightEstimate?.confidence ?? 0) * 100).round()}%';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: const EdgeInsets.fromLTRB(11, 11, 11, 10),
      decoration: BoxDecoration(
        color: isDragPlaceholder ? const Color(0xFFF8FAFC) : Colors.white,
        border: Border.all(
          color: isDragging || isDragPlaceholder
              ? const Color(0xFF38BDF8).withValues(alpha: 0.48)
              : const Color(0xFFDDE7F0),
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDragging
                  ? 0.22
                  : isDragPlaceholder
                  ? 0
                  : 0.035,
            ),
            blurRadius: isDragging ? 30 : 14,
            offset: Offset(0, isDragging ? 18 : 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTight = constraints.maxWidth < 300;
          final body = issue.body.trim();
          final visibleLabelLimit = isTight ? 3 : 5;
          final visibleLabels = issue.labels.take(visibleLabelLimit).toList();
          final hiddenLabelCount = issue.labels.length - visibleLabels.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        RepoBadge(repo: issue.repo),
                        if (cardWeight != null)
                          WeightBadge(
                            value: cardWeight,
                            tooltip: cardWeightTooltip,
                            isActual: issue.statusId == _closedStatusId,
                          ),
                      ],
                    ),
                  ),
                  if (githubUrl != null) ...[
                    const SizedBox(width: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        GitHubLinkCopyButton(url: githubUrl),
                        CursorAgentCardButton(
                          issue: issue,
                          isStarting: isStartingCursorAgent,
                          onStart: onStartCursorAgent,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(
                issue.title,
                maxLines: isTight ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.w700,
                  height: 1.28,
                ),
              ),
              if (body.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  body,
                  maxLines: isTight ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ],
              if (issue.subIssuesSummary != null || subIssues.isNotEmpty) ...[
                const SizedBox(height: 10),
                IssueCardSubIssuesSection(
                  summary: issue.subIssuesSummary,
                  subIssues: subIssues,
                  onIssueTap: onSubIssueTap,
                ),
              ],
              if (visibleLabels.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    for (final label in visibleLabels) LabelPill(label: label),
                    if (hiddenLabelCount > 0)
                      LabelPill(label: '+$hiddenLabelCount'),
                  ],
                ),
              ],
              const SizedBox(height: 11),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  IssueIdMetaChip(issueId: issue.displayId),
                  if (issue.dueDate != null)
                    DueDatePill(dueDate: issue.dueDate!),
                  if (issue.parentIssue != null)
                    ParentIssueMetaChip(parentIssue: issue.parentIssue!),
                  if (issue.pullRequests.isNotEmpty)
                    PullRequestBadge(pullRequests: issue.pullRequests),
                  BuildStatusBadge(status: buildStatus),
                  CommentMetaChip(comments: issue.comments),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class ReviewGroupIssueCard extends StatelessWidget {
  const ReviewGroupIssueCard({
    super.key,
    required this.issue,
    this.isDragging = false,
    this.isDragPlaceholder = false,
  });

  final Issue issue;
  final bool isDragging;
  final bool isDragPlaceholder;

  @override
  Widget build(BuildContext context) {
    final weight = issue.statusId == _closedStatusId
        ? issue.resolution?.actualWeight
        : issue.weightEstimate?.value;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: isDragPlaceholder ? const Color(0xFFF8FAFC) : Colors.white,
        border: Border.all(
          color: isDragging || isDragPlaceholder
              ? const Color(0xFF38BDF8).withValues(alpha: 0.48)
              : const Color(0xFFE2E8F0),
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDragging
                  ? 0.18
                  : isDragPlaceholder
                  ? 0
                  : 0.02,
            ),
            blurRadius: isDragging ? 24 : 8,
            offset: Offset(0, isDragging ? 14 : 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  issue.displayId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  issue.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (weight != null)
                _ReviewGroupPill(
                  label: 'W$weight',
                  color: issue.statusId == _closedStatusId
                      ? const Color(0xFF15803D)
                      : const Color(0xFF2563EB),
                  icon: Icons.speed_rounded,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class ReviewLinkedIssueReferenceCard extends StatelessWidget {
  const ReviewLinkedIssueReferenceCard({super.key, required this.reference});

  final IssuePullRequestLinkedIssue reference;

  @override
  Widget build(BuildContext context) {
    final isClosed = reference.state == 'closed';
    final stateColor = isClosed
        ? const Color(0xFF15803D)
        : const Color(0xFF64748B);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: reference.url == null
          ? null
          : () => unawaited(_launchUrlExternal(reference.url!)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '#${reference.number}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    reference.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            _ReviewGroupPill(
              label: isClosed ? 'closed' : 'open',
              color: stateColor,
              icon: isClosed
                  ? Icons.check_circle_rounded
                  : Icons.circle_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class SubIssuesProgressMeter extends StatelessWidget {
  const SubIssuesProgressMeter({super.key, required this.summary});

  final IssueSubIssuesSummary summary;

  @override
  Widget build(BuildContext context) {
    final color = summary.completed == summary.total
        ? const Color(0xFF16A34A)
        : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
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
              Icon(Icons.account_tree_outlined, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Sub-issues ${summary.completed}/${summary.total}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${summary.percentCompleted}%',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: summary.progress,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class IssueCardSubIssuesSection extends StatelessWidget {
  const IssueCardSubIssuesSection({
    super.key,
    required this.summary,
    required this.subIssues,
    this.onIssueTap,
  });

  final IssueSubIssuesSummary? summary;
  final List<Issue> subIssues;
  final ValueChanged<String>? onIssueTap;

  @override
  Widget build(BuildContext context) {
    final currentSummary = summary;
    final completed = currentSummary?.completed ?? 0;
    final total = currentSummary?.total ?? subIssues.length;
    final percentCompleted = currentSummary?.percentCompleted ?? 0;
    final progress = currentSummary?.progress ?? 0;
    final color = total > 0 && completed == total
        ? const Color(0xFF16A34A)
        : Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_tree_outlined, size: 14, color: color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Sub-issues $completed/$total',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$percentCompleted%',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    value: progress,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
          if (subIssues.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            SubIssuesList(
              subIssues: subIssues,
              onIssueTap: onIssueTap,
              isEmbedded: true,
            ),
          ],
        ],
      ),
    );
  }
}

class SubIssuesList extends StatelessWidget {
  const SubIssuesList({
    super.key,
    required this.subIssues,
    this.workspaceId,
    this.referenceSubIssues = const [],
    this.onIssueTap,
    this.isEmbedded = false,
  });

  final List<Issue> subIssues;
  final String? workspaceId;
  final List<IssueSubIssueReference> referenceSubIssues;
  final ValueChanged<String>? onIssueTap;
  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      for (final issue in subIssues)
        SubIssueListRow(issue: issue, onTap: onIssueTap),
      for (final subIssue in referenceSubIssues)
        SubIssueReferenceRow(
          subIssue: subIssue,
          workspaceId: workspaceId,
          onTap: onIssueTap,
        ),
    ];
    final list = Column(
      children: [
        for (final entry in rows.indexed) ...[
          entry.$2,
          if (entry.$1 != rows.length - 1)
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
        ],
      ],
    );
    if (isEmbedded) {
      return list;
    }
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: list,
    );
  }
}

class SubIssueReferenceList extends StatelessWidget {
  const SubIssueReferenceList({
    super.key,
    required this.subIssues,
    this.workspaceId,
    this.onIssueTap,
  });

  final List<IssueSubIssueReference> subIssues;
  final String? workspaceId;
  final ValueChanged<String>? onIssueTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          for (final entry in subIssues.indexed) ...[
            SubIssueReferenceRow(
              subIssue: entry.$2,
              workspaceId: workspaceId,
              onTap: onIssueTap,
            ),
            if (entry.$1 != subIssues.length - 1)
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
          ],
        ],
      ),
    );
  }
}

class SubIssueListRow extends StatelessWidget {
  const SubIssueListRow({super.key, required this.issue, this.onTap});

  final Issue issue;
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    final isClosed = issue.statusId == _closedStatusId;
    final isCreating = issue.parentIssue != null && issue.issueKey == null;
    final iconColor = isClosed
        ? const Color(0xFF8250DF)
        : const Color(0xFF1F883D);
    return InkWell(
      onTap: onTap == null || isCreating ? null : () => onTap!(issue.id),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        child: Row(
          children: [
            Icon(
              isClosed
                  ? Icons.check_circle_outline_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 15,
              color: iconColor,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                issue.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isClosed
                      ? const Color(0xFF64748B)
                      : const Color(0xFF334155),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  decoration: isClosed ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            const SizedBox(width: 7),
            isCreating
                ? const _SubIssueCreatingBadge()
                : Text(
                    issue.displayId,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class SubIssueReferenceRow extends StatelessWidget {
  const SubIssueReferenceRow({
    super.key,
    required this.subIssue,
    this.workspaceId,
    this.onTap,
  });

  final IssueSubIssueReference subIssue;
  final String? workspaceId;
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    final issueId = subIssue.issueId;
    final currentWorkspaceId = workspaceId;
    if (issueId.isNotEmpty &&
        currentWorkspaceId != null &&
        currentWorkspaceId.isNotEmpty) {
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .doc('workspaces/$currentWorkspaceId/issues/$issueId')
            .snapshots(),
        builder: (context, snapshot) {
          final issueSnapshot = snapshot.data;
          if (issueSnapshot != null && issueSnapshot.exists) {
            final issue = Issue.fromDocument(issueSnapshot);
            if (issue.issueKey == null) {
              return _SubIssueReferenceContent(
                title: issue.title,
                isClosed: issue.statusId == _closedStatusId,
                isCreating: true,
              );
            }
            return SubIssueListRow(issue: issue, onTap: onTap);
          }
          return _SubIssueReferenceContent(
            title: subIssue.title,
            isClosed: subIssue.state == 'closed',
            isCreating: true,
          );
        },
      );
    }
    return _SubIssueReferenceContent(
      title: subIssue.title,
      isClosed: subIssue.state == 'closed',
      trailingLabel: subIssue.number > 0 ? '#${subIssue.number}' : '',
      onTap: onTap == null || issueId.isEmpty ? null : () => onTap!(issueId),
    );
  }
}

class _SubIssueReferenceContent extends StatelessWidget {
  const _SubIssueReferenceContent({
    required this.title,
    required this.isClosed,
    this.trailingLabel = '',
    this.isCreating = false,
    this.onTap,
  });

  final String title;
  final bool isClosed;
  final String trailingLabel;
  final bool isCreating;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = isClosed
        ? const Color(0xFF8250DF)
        : const Color(0xFF1F883D);
    return InkWell(
      onTap: isCreating ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        child: Row(
          children: [
            Icon(
              isClosed
                  ? Icons.check_circle_outline_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 15,
              color: iconColor,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isClosed
                      ? const Color(0xFF64748B)
                      : const Color(0xFF334155),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  decoration: isClosed ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            const SizedBox(width: 7),
            isCreating
                ? const _SubIssueCreatingBadge()
                : Text(
                    trailingLabel,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _SubIssueCreatingBadge extends StatelessWidget {
  const _SubIssueCreatingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFD97706),
            ),
          ),
          SizedBox(width: 5),
          Text(
            '作成中',
            style: TextStyle(
              color: Color(0xFF92400E),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class IssueIdMetaChip extends StatelessWidget {
  const IssueIdMetaChip({super.key, required this.issueId});

  final String issueId;

  @override
  Widget build(BuildContext context) {
    return IssueMetaChip(
      label: issueId,
      trailing: IssueIdCopyButton(issueId: issueId),
    );
  }
}

class ParentIssueMetaChip extends StatelessWidget {
  const ParentIssueMetaChip({super.key, required this.parentIssue});

  final IssueParentIssue parentIssue;

  @override
  Widget build(BuildContext context) {
    return IssueMetaChip(
      icon: Icons.account_tree_outlined,
      label: parentIssue.number > 0
          ? 'Parent #${parentIssue.number}'
          : 'Parent',
    );
  }
}

class CommentMetaChip extends StatelessWidget {
  const CommentMetaChip({super.key, required this.comments});

  final int comments;

  @override
  Widget build(BuildContext context) {
    return IssueMetaChip(
      icon: Icons.chat_bubble_outline_rounded,
      label: '$comments',
    );
  }
}

class IssueMetaChip extends StatelessWidget {
  const IssueMetaChip({
    super.key,
    required this.label,
    this.icon,
    this.leading,
    this.trailing,
  });

  final String label;
  final IconData? icon;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        leading == null && icon == null ? 8 : 5,
        3,
        6,
        3,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 5),
          ] else if (icon != null) ...[
            Icon(icon, size: 13, color: const Color(0xFF94A3B8)),
            const SizedBox(width: 4),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 96),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 1), trailing!],
        ],
      ),
    );
  }
}

class IssueIdCopyButton extends StatelessWidget {
  const IssueIdCopyButton({super.key, required this.issueId});

  final String issueId;

  @override
  Widget build(BuildContext context) {
    return _CopyFeedbackIconButton(
      tooltip: 'Issue IDをコピー',
      copiedTooltip: 'Issue IDをコピーしました',
      text: issueId,
      successMessage: 'Issue IDをコピーしました',
      icon: const Icon(
        Icons.copy_rounded,
        size: 13,
        color: Color(0xFF94A3B8),
      ),
      iconSize: 13,
      dimension: 22,
    );
  }
}

class PullRequestBadge extends StatelessWidget {
  const PullRequestBadge({super.key, required this.pullRequests});

  final List<IssuePullRequest> pullRequests;

  @override
  Widget build(BuildContext context) {
    final latest = pullRequests.last;
    final label = pullRequests.length == 1
        ? 'PR #${latest.number}'
        : '${pullRequests.length} PRs';
    final prUrl = latest.url;
    return Tooltip(
      message: prUrl ?? 'Linked pull request',
      child: GestureDetector(
        onTap: prUrl != null
            ? () => unawaited(_launchUrlExternal(prUrl))
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            border: Border.all(color: const Color(0xFFBFDBFE)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.alt_route_rounded,
                size: 14,
                color: Color(0xFF0EA5E9),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF0369A1),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GitHubLinkCopyButton extends StatelessWidget {
  const GitHubLinkCopyButton({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return _CopyFeedbackIconButton(
      tooltip: 'GitHubリンクをコピー',
      copiedTooltip: 'GitHubリンクをコピーしました',
      text: url,
      successMessage: 'GitHubリンクをコピーしました',
      icon: const _CopyLinkIcon(),
      iconSize: 14,
      dimension: 26,
    );
  }
}

class _CopyLinkIcon extends StatelessWidget {
  const _CopyLinkIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Symbols.link_2_rounded,
      size: 17,
      color: Color(0xFF475569),
    );
  }
}

class _CopyFeedbackIconButton extends StatefulWidget {
  const _CopyFeedbackIconButton({
    required this.tooltip,
    required this.copiedTooltip,
    required this.text,
    required this.successMessage,
    required this.icon,
    required this.iconSize,
    required this.dimension,
  });

  final String tooltip;
  final String copiedTooltip;
  final String text;
  final String successMessage;
  final Widget icon;
  final double iconSize;
  final double dimension;

  @override
  State<_CopyFeedbackIconButton> createState() =>
      _CopyFeedbackIconButtonState();
}

class _CopyFeedbackIconButtonState extends State<_CopyFeedbackIconButton> {
  bool _copied = false;
  int _copyVersion = 0;

  Future<void> _handleCopy() async {
    final version = ++_copyVersion;
    await _copyTextToClipboard(
      context,
      text: widget.text,
      successMessage: widget.successMessage,
    );
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted || version != _copyVersion) return;
    setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.dimension,
      child: IconButton(
        tooltip: _copied ? widget.copiedTooltip : widget.tooltip,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        onPressed: () => unawaited(_handleCopy()),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: _copied
              ? Icon(
                  Icons.check_rounded,
                  key: const ValueKey('copied'),
                  size: widget.iconSize,
                  color: const Color(0xFF22C55E),
                )
              : KeyedSubtree(
                  key: const ValueKey('copyIcon'),
                  child: widget.icon,
                ),
        ),
      ),
    );
  }
}

class CursorAgentCardButton extends StatelessWidget {
  const CursorAgentCardButton({
    super.key,
    required this.issue,
    required this.isStarting,
    this.onStart,
  });

  final Issue issue;
  final bool isStarting;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final hasPullRequest = issue.pullRequests.isNotEmpty;
    final isRunning = issue.cursorAgent?.isActive == true && !hasPullRequest;
    final isBusy = isStarting || isRunning;
    return SizedBox.square(
      dimension: 26,
      child: IconButton(
        tooltip: isRunning ? 'Cursor agentを実行中' : 'Cursor agentを開始',
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        onPressed: isBusy ? null : onStart,
        icon: isBusy
            ? const SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.smart_toy_outlined, size: 16),
      ),
    );
  }
}

class RepoBadge extends StatelessWidget {
  const RepoBadge({super.key, required this.repo});

  final String repo;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 150),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 128),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          maxLines: 1,
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_outlined, size: 12, color: colors.foreground),
          const SizedBox(width: 3),
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

class WeightBadge extends StatelessWidget {
  const WeightBadge({
    super.key,
    required this.value,
    required this.tooltip,
    this.isActual = false,
  });

  final int value;
  final String tooltip;
  final bool isActual;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: isActual ? const Color(0xFFF0FDF4) : const Color(0xFFEEF2FF),
          border: Border.all(
            color: isActual ? const Color(0xFFBBF7D0) : const Color(0xFFC7D2FE),
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          'W$value',
          style: TextStyle(
            color: isActual ? const Color(0xFF15803D) : const Color(0xFF4338CA),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class IssueWeightOverrideDialog extends StatefulWidget {
  const IssueWeightOverrideDialog({super.key, required this.issue});

  final Issue issue;

  @override
  State<IssueWeightOverrideDialog> createState() =>
      _IssueWeightOverrideDialogState();
}

class _IssueWeightOverrideDialogState extends State<IssueWeightOverrideDialog> {
  int? _estimateWeight;
  int? _actualWeight;

  @override
  void initState() {
    super.initState();
    final estimateWeight = widget.issue.weightEstimate?.value;
    final actualWeight = widget.issue.resolution?.actualWeight;
    _estimateWeight = _validIssueWeights.contains(estimateWeight)
        ? estimateWeight
        : null;
    _actualWeight = _validIssueWeights.contains(actualWeight)
        ? actualWeight
        : _estimateWeight;
  }

  void _save() {
    final estimateWeight = _estimateWeight;
    if (estimateWeight == null) {
      return;
    }
    final actualWeight = widget.issue.statusId == _closedStatusId
        ? _actualWeight
        : null;
    if (widget.issue.statusId == _closedStatusId && actualWeight == null) {
      return;
    }
    Navigator.of(context).pop(
      IssueWeightOverrideDraft(
        estimateWeight: estimateWeight,
        actualWeight: actualWeight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isClosed = widget.issue.statusId == _closedStatusId;
    final canSave =
        _estimateWeight != null && (!isClosed || _actualWeight != null);

    return AlertDialog(
      title: const Text('Weight上書き'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LLM estimateと完了時のactual weightを手動で補正します。',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _estimateWeight,
            decoration: const InputDecoration(
              labelText: '推定weight',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final weight in _validIssueWeights)
                DropdownMenuItem(value: weight, child: Text('W$weight')),
            ],
            onChanged: (value) => setState(() => _estimateWeight = value),
          ),
          if (isClosed) ...[
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              initialValue: _actualWeight,
              decoration: const InputDecoration(
                labelText: '実績weight',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final weight in _validIssueWeights)
                  DropdownMenuItem(value: weight, child: Text('W$weight')),
              ],
              onChanged: (value) => setState(() => _actualWeight = value),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: canSave ? _save : null,
          child: const Text('保存'),
        ),
      ],
    );
  }
}

class IssueWeightPanel extends StatelessWidget {
  const IssueWeightPanel({
    super.key,
    required this.issue,
    required this.isEstimating,
    this.isOverriding = false,
    this.onEstimate,
    this.onOverride,
  });

  final Issue issue;
  final bool isEstimating;
  final bool isOverriding;
  final Future<void> Function()? onEstimate;
  final Future<void> Function()? onOverride;

  @override
  Widget build(BuildContext context) {
    final estimate = issue.weightEstimate;
    final value = estimate?.value;
    final resolution = issue.resolution;
    final actualWeight = resolution?.actualWeight;
    final isClosed = issue.statusId == 'done';
    final subtitle = switch (estimate?.status) {
      'done' when estimate?.manualOverride == true && value != null => '手動上書き',
      'done' when value != null =>
        '信頼度 ${(estimate!.confidence * 100).round()}%'
            '${estimate.estimatedAt == null ? '' : ' / ${_formatDate(estimate.estimatedAt!)}'}',
      'failed' => estimate?.error ?? 'Weight推定に失敗しました',
      'estimating' => 'Weightを推定中...',
      _ => 'まだ推定していません',
    };
    final reason = estimate?.reason;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: isEstimating
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        value == null ? 'W?' : 'W$value',
                        style: const TextStyle(
                          color: Color(0xFF4338CA),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LLM weight',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                    if (reason != null && reason.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        reason,
                        style: const TextStyle(color: Color(0xFF475569)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: isEstimating || isOverriding ? null : onEstimate,
                    icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: Text(value == null ? '推定' : '再推定'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: isEstimating || isOverriding ? null : onOverride,
                    icon: isOverriding
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.tune_rounded, size: 16),
                    label: const Text('上書き'),
                  ),
                ],
              ),
            ],
          ),
          if (isClosed && actualWeight != null) ...[
            const SizedBox(height: 12),
            _ActualWeightRow(
              predictedWeight: value,
              actualWeight: actualWeight,
              delta: resolution?.weightDelta,
              isManualOverride: resolution?.actualWeightManualOverride == true,
            ),
          ],
        ],
      ),
    );
  }
}

class _ActualWeightRow extends StatelessWidget {
  const _ActualWeightRow({
    required this.predictedWeight,
    required this.actualWeight,
    this.delta,
    this.isManualOverride = false,
  });

  static const _validWeights = [1, 2, 4, 8, 16, 32];

  static bool _isAdjacent(int a, int b) {
    final idxA = _validWeights.indexOf(a);
    final idxB = _validWeights.indexOf(b);
    if (idxA < 0 || idxB < 0) return (a - b).abs() <= 1;
    return (idxA - idxB).abs() <= 1;
  }

  final int? predictedWeight;
  final int actualWeight;
  final int? delta;
  final bool isManualOverride;

  @override
  Widget build(BuildContext context) {
    final isExact = predictedWeight == actualWeight;
    final isClose =
        predictedWeight != null && _isAdjacent(predictedWeight!, actualWeight);
    final deltaColor = isExact
        ? const Color(0xFF15803D)
        : isClose
        ? const Color(0xFFA16207)
        : const Color(0xFFDC2626);
    final deltaBg = isExact
        ? const Color(0xFFF0FDF4)
        : isClose
        ? const Color(0xFFFEFCE8)
        : const Color(0xFFFEF2F2);
    final deltaLabel = delta == null
        ? ''
        : delta == 0
        ? '一致'
        : delta! > 0
        ? '過大推定 +$delta'
        : '過小推定 $delta';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: deltaBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.assessment_outlined, size: 16, color: deltaColor),
          const SizedBox(width: 8),
          Text(
            '実績 W$actualWeight',
            style: TextStyle(
              color: deltaColor,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          if (predictedWeight != null) ...[
            const SizedBox(width: 6),
            Text(
              '(予測 W$predictedWeight)',
              style: TextStyle(color: deltaColor.withAlpha(180), fontSize: 12),
            ),
          ],
          if (isManualOverride) ...[
            const SizedBox(width: 6),
            Text(
              'manual',
              style: TextStyle(
                color: deltaColor.withAlpha(180),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const Spacer(),
          if (deltaLabel.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: deltaColor.withAlpha(25),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: deltaColor.withAlpha(60)),
              ),
              child: Text(
                deltaLabel,
                style: TextStyle(
                  color: deltaColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CursorAgentPanel extends StatelessWidget {
  const CursorAgentPanel({
    super.key,
    required this.issue,
    required this.isStarting,
    this.onStart,
  });

  final Issue issue;
  final bool isStarting;
  final Future<void> Function()? onStart;

  @override
  Widget build(BuildContext context) {
    final hasGitHubIssue = issue.githubUrl != null;
    final hasPullRequest = issue.pullRequests.isNotEmpty;
    final agent = issue.cursorAgent;
    final isRunning = agent?.isActive == true && !hasPullRequest;
    final isBusy = isStarting || isRunning;
    final subtitle = switch (agent?.status) {
      'running' when !hasPullRequest =>
        'Cursor agentを実行中です。Run ID: ${agent!.shortRunId}',
      'starting' when !hasPullRequest => 'Cursor agentを開始中...',
      'done' || 'running' || 'starting' => 'Cursor agentがpull requestを作成しました。',
      'failed' => agent?.errorMessage ?? 'Cursor agentの開始に失敗しました。',
      _ when hasGitHubIssue => 'Cursor Cloud Agentを開始して、このissueの対応PRを作成します。',
      _ => 'agentを開始する前に、このissueをGitHubに接続してください。',
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: isBusy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.smart_toy_outlined,
                    color: Color(0xFF2563EB),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cursor agent',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: hasGitHubIssue && !isBusy ? onStart : null,
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: Text(isRunning ? '実行中' : '開始'),
          ),
        ],
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

typedef IssuePullRequestLinkCallback =
    Future<void> Function({
      required String issueId,
      required String repository,
      required IssuePullRequest pullRequest,
    });

typedef IssueWeightOverrideCallback =
    Future<void> Function({
      required String issueId,
      required IssueWeightOverrideDraft draft,
    });

class IssueDragData {
  const IssueDragData({required this.issueId, required this.sourceColumnId});

  final String issueId;
  final String sourceColumnId;
}

class CloseIssueDialogResult {
  const CloseIssueDialogResult(this.issueId);

  final String issueId;
}

class EditIssueDialogResult {
  const EditIssueDialogResult({required this.issueId, required this.draft});

  final String issueId;
  final NewIssueDraft draft;
}

class IssueWeightOverrideDraft {
  const IssueWeightOverrideDraft({
    required this.estimateWeight,
    this.actualWeight,
  });

  final int estimateWeight;
  final int? actualWeight;
}

class NewIssueDraft {
  const NewIssueDraft({
    required this.title,
    required this.body,
    required this.repo,
    required this.githubUrl,
    required this.labels,
    required this.columnId,
    required this.priority,
    required this.dueDate,
  });

  final String title;
  final String body;
  final String repo;
  final String? githubUrl;
  final List<String> labels;
  final String columnId;
  final Priority priority;
  final DateTime? dueDate;
}

class BoardColumn {
  const BoardColumn({
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

class IssueResolution {
  const IssueResolution({
    this.actualWeight,
    this.weightDelta,
    this.cycleTimeMs,
    this.leadTimeMs,
    this.workStartSource = '',
    this.actualWeightManualOverride = false,
  });

  static IssueResolution? fromMap(Map<String, dynamic> data) {
    if (data.isEmpty) {
      return null;
    }
    final hasActualWeight = data.containsKey('actualWeight');
    final actualWeight = _asInt(data['actualWeight']);
    return IssueResolution(
      actualWeight: hasActualWeight && actualWeight >= 0 ? actualWeight : null,
      weightDelta: data['weightDelta'] is num
          ? (data['weightDelta'] as num).toInt()
          : null,
      cycleTimeMs: data['cycleTimeMs'] is num
          ? (data['cycleTimeMs'] as num).toInt()
          : null,
      leadTimeMs: data['leadTimeMs'] is num
          ? (data['leadTimeMs'] as num).toInt()
          : null,
      workStartSource: _asString(data['workStartSource']),
      actualWeightManualOverride: data['actualWeightManualOverride'] == true,
    );
  }

  final int? actualWeight;
  final int? weightDelta;
  final int? cycleTimeMs;
  final int? leadTimeMs;
  final String workStartSource;
  final bool actualWeightManualOverride;
}

class IssueSubIssuesSummary {
  const IssueSubIssuesSummary({
    required this.total,
    required this.completed,
    required this.percentCompleted,
  });

  static IssueSubIssuesSummary? fromMap(Map<String, dynamic> data) {
    final total = _asInt(data['total']);
    if (total <= 0) {
      return null;
    }
    final completed = _asInt(data['completed']).clamp(0, total).toInt();
    final rawPercent = _asInt(data['percentCompleted']);
    final percentCompleted = rawPercent > 0
        ? rawPercent.clamp(0, 100).toInt()
        : ((completed / total) * 100).round();
    return IssueSubIssuesSummary(
      total: total,
      completed: completed,
      percentCompleted: percentCompleted,
    );
  }

  double get progress => (percentCompleted / 100).clamp(0, 1).toDouble();

  Map<String, Object> toFirestore() {
    return {
      'total': total,
      'completed': completed,
      'percentCompleted': percentCompleted,
    };
  }

  final int total;
  final int completed;
  final int percentCompleted;
}

class IssueParentIssue {
  const IssueParentIssue({
    required this.issueId,
    required this.nodeId,
    required this.number,
    this.url,
  });

  static IssueParentIssue? fromMap(Map<String, dynamic> data) {
    if (data.isEmpty) {
      return null;
    }
    final issueId = _asString(data['issueId']);
    final nodeId = _asString(data['nodeId']);
    final number = _asInt(data['number']);
    final url = _normalizedOptionalUrl(_asString(data['url']));
    if (issueId.isEmpty && nodeId.isEmpty && number <= 0 && url == null) {
      return null;
    }
    return IssueParentIssue(
      issueId: issueId,
      nodeId: nodeId,
      number: number,
      url: url,
    );
  }

  final String issueId;
  final String nodeId;
  final int number;
  final String? url;
}

class IssueSubIssueReference {
  const IssueSubIssueReference({
    required this.issueId,
    required this.nodeId,
    required this.number,
    required this.title,
    this.url,
    required this.state,
  });

  static IssueSubIssueReference? fromMap(Map<String, dynamic> data) {
    final title = _asString(data['title']);
    final number = _asInt(data['number']);
    if (title.isEmpty && number <= 0) {
      return null;
    }
    return IssueSubIssueReference(
      issueId: _asString(data['issueId']),
      nodeId: _asString(data['nodeId']),
      number: number,
      title: title.isEmpty ? '#$number' : title,
      url: _normalizedOptionalUrl(_asString(data['url'])),
      state: _asString(data['state'], 'open'),
    );
  }

  final String issueId;
  final String nodeId;
  final int number;
  final String title;
  final String? url;
  final String state;
}

class Issue {
  const Issue({
    required this.id,
    String? displayId,
    this.issueKey,
    this.githubNumber = 0,
    required this.repo,
    required this.title,
    this.body = '',
    this.githubUrl,
    required this.labels,
    required this.comments,
    required this.priority,
    this.dueDate,
    this.statusId = 'triage',
    this.rank = 0,
    this.closedAt,
    this.weightEstimate,
    this.resolution,
    this.pullRequests = const [],
    this.subIssuesSummary,
    this.subIssues = const [],
    this.parentIssue,
    this.cursorAgent,
  }) : displayId = displayId ?? issueKey ?? id;

  factory Issue.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final githubIssue = _asMap(data['githubIssue']);
    final number = _asInt(githubIssue['number']);
    final repo = _asString(data['repo']);
    final issueKey = _asString(data['issueKey']);

    return Issue(
      id: doc.id,
      issueKey: issueKey.isEmpty ? null : issueKey,
      githubNumber: number,
      displayId: issueKey.isNotEmpty
          ? issueKey
          : number > 0
          ? '#$number'
          : doc.id,
      repo: repo,
      title: _asString(data['title'], '#$number'),
      body: _asString(data['body']),
      githubUrl: _normalizedOptionalUrl(_asString(githubIssue['url'])),
      labels: _asStringList(data['labels']),
      comments: _asInt(data['comments']),
      priority: _priorityFromString(_asString(data['priority'], 'medium')),
      dueDate: _asDate(data['dueDate']),
      statusId: _asString(data['statusId'], 'triage'),
      rank: _asDouble(data['rank']),
      closedAt: _asDate(data['closedAt']),
      weightEstimate: IssueWeightEstimate.fromMap(
        _asMap(data['weightEstimate']),
      ),
      resolution: IssueResolution.fromMap(_asMap(data['resolution'])),
      pullRequests: _asList(data['pullRequests'])
          .map((value) => IssuePullRequest.fromMap(_asMap(value)))
          .where((pullRequest) => pullRequest.number > 0)
          .toList(),
      subIssuesSummary: IssueSubIssuesSummary.fromMap(
        _asMap(
          githubIssue['subIssuesSummary'] ?? githubIssue['sub_issues_summary'],
        ),
      ),
      subIssues: _asList(githubIssue['subIssues'])
          .map((value) => IssueSubIssueReference.fromMap(_asMap(value)))
          .whereType<IssueSubIssueReference>()
          .toList(),
      parentIssue: IssueParentIssue.fromMap(_asMap(githubIssue['parentIssue'])),
      cursorAgent: CursorAgentState.fromMap(_asMap(data['cursorAgent'])),
    );
  }

  Issue copyWith({String? statusId, double? rank, DateTime? closedAt}) {
    return Issue(
      id: id,
      displayId: displayId,
      issueKey: issueKey,
      githubNumber: githubNumber,
      repo: repo,
      title: title,
      body: body,
      githubUrl: githubUrl,
      labels: labels,
      comments: comments,
      priority: priority,
      dueDate: dueDate,
      statusId: statusId ?? this.statusId,
      rank: rank ?? this.rank,
      closedAt: closedAt,
      weightEstimate: weightEstimate,
      resolution: resolution,
      pullRequests: pullRequests,
      subIssuesSummary: subIssuesSummary,
      subIssues: subIssues,
      parentIssue: parentIssue,
      cursorAgent: cursorAgent,
    );
  }

  final String id;
  final String displayId;
  final String? issueKey;
  final int githubNumber;
  final String repo;
  final String title;
  final String body;
  final String? githubUrl;
  final List<String> labels;
  final int comments;
  final Priority priority;
  final DateTime? dueDate;
  final String statusId;
  final double rank;
  final DateTime? closedAt;
  final IssueWeightEstimate? weightEstimate;
  final IssueResolution? resolution;
  final List<IssuePullRequest> pullRequests;
  final IssueSubIssuesSummary? subIssuesSummary;
  final List<IssueSubIssueReference> subIssues;
  final IssueParentIssue? parentIssue;
  final CursorAgentState? cursorAgent;
}

class CursorAgentState {
  const CursorAgentState({
    required this.status,
    this.agentId = '',
    this.runId = '',
    this.errorMessage = '',
  });

  static CursorAgentState? fromMap(Map<String, dynamic> data) {
    final status = _asString(data['status']);
    if (status.isEmpty) {
      return null;
    }

    return CursorAgentState(
      status: status,
      agentId: _asString(data['agentId']),
      runId: _asString(data['runId']),
      errorMessage: _asString(data['errorMessage']),
    );
  }

  bool get isActive => status == 'starting' || status == 'running';

  String get shortRunId {
    if (runId.length <= 8) {
      return runId;
    }
    return runId.substring(0, 8);
  }

  final String status;
  final String agentId;
  final String runId;
  final String errorMessage;
}

class IssuePullRequest {
  const IssuePullRequest({
    required this.number,
    required this.title,
    this.url,
    required this.state,
    required this.merged,
    required this.branch,
    this.createdAt,
    this.linkedIssues = const [],
  });

  factory IssuePullRequest.fromMap(Map<String, dynamic> data) {
    return IssuePullRequest(
      number: _asInt(data['number']),
      title: _asString(data['title'], 'Pull request'),
      url: _normalizedOptionalUrl(_asString(data['url'])),
      state: _asString(data['state'], 'open'),
      merged: data['merged'] == true,
      branch: _asString(data['branch']),
      createdAt: _asDate(data['createdAt']),
      linkedIssues: _asList(data['linkedIssues'])
          .map((value) => IssuePullRequestLinkedIssue.fromMap(_asMap(value)))
          .where((issue) => issue.number > 0)
          .toList(),
    );
  }

  Map<String, Object?> toFirestore({required String repository}) {
    final parts = repository.split('/');
    final owner = parts.isEmpty ? '' : parts.first;
    final repo = parts.length > 1 ? parts[1] : '';
    return {
      'owner': owner,
      'repo': repo,
      'number': number,
      'url': url,
      'title': title,
      'branch': branch,
      'state': state,
      'merged': merged,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      'linkedIssues': [
        for (final issue in linkedIssues) issue.toFirestore(),
      ],
    };
  }

  final int number;
  final String title;
  final String? url;
  final String state;
  final bool merged;
  final String branch;
  final DateTime? createdAt;
  final List<IssuePullRequestLinkedIssue> linkedIssues;
}

class IssuePullRequestLinkedIssue {
  const IssuePullRequestLinkedIssue({
    required this.number,
    required this.title,
    this.url,
    required this.state,
  });

  factory IssuePullRequestLinkedIssue.fromMap(Map<String, dynamic> data) {
    final number = _asInt(data['number']);
    return IssuePullRequestLinkedIssue(
      number: number,
      title: _asString(data['title'], '#$number'),
      url: _normalizedOptionalUrl(_asString(data['url'])),
      state: _asString(data['state'], 'open').toLowerCase(),
    );
  }

  Map<String, Object?> toFirestore() {
    return {
      'number': number,
      'title': title,
      'url': url,
      'state': state,
    };
  }

  final int number;
  final String title;
  final String? url;
  final String state;
}

class IssueWeightEstimate {
  const IssueWeightEstimate({
    required this.status,
    this.value,
    this.confidence = 0,
    this.reason = '',
    this.model = '',
    this.promptVersion = '',
    this.inputHash = '',
    this.source = '',
    this.manualOverride = false,
    this.estimatedAt,
    this.error,
  });

  static IssueWeightEstimate? fromMap(Map<String, dynamic> data) {
    if (data.isEmpty) {
      return null;
    }
    final hasValue = data.containsKey('value');
    final value = _asInt(data['value']);
    final normalizedValue = hasValue && value >= 0 ? value : null;
    return IssueWeightEstimate(
      status: _asString(
        data['status'],
        normalizedValue == null ? 'unknown' : 'done',
      ),
      value: normalizedValue,
      confidence: _asDouble(data['confidence']),
      reason: _asString(data['reason']),
      model: _asString(data['model']),
      promptVersion: _asString(data['promptVersion']),
      inputHash: _asString(data['inputHash']),
      source: _asString(data['source']),
      manualOverride: data['manualOverride'] == true,
      estimatedAt: _asDate(data['estimatedAt']),
      error: _asString(data['error']).isEmpty ? null : _asString(data['error']),
    );
  }

  final String status;
  final int? value;
  final double confidence;
  final String reason;
  final String model;
  final String promptVersion;
  final String inputHash;
  final String source;
  final bool manualOverride;
  final DateTime? estimatedAt;
  final String? error;
}

class GitHubRepository {
  const GitHubRepository({
    required this.fullName,
    required this.name,
    required this.owner,
    required this.private,
    required this.defaultBranch,
  });

  factory GitHubRepository.fromMap(Map<String, dynamic> data) {
    final fullName = _asString(data['fullName']);
    final parts = fullName.split('/');

    return GitHubRepository(
      fullName: fullName,
      name: _asString(data['name'], parts.length > 1 ? parts[1] : fullName),
      owner: _asString(data['owner'], parts.isEmpty ? '' : parts.first),
      private: data['private'] == true,
      defaultBranch: _asString(data['defaultBranch'], 'main'),
    );
  }

  final String fullName;
  final String name;
  final String owner;
  final bool private;
  final String defaultBranch;
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return {};
}

List<Object?> _asList(Object? value) {
  return value is List ? value : const [];
}

String _asString(Object? value, [String fallback = '']) {
  return value is String && value.isNotEmpty ? value : fallback;
}

int _asInt(Object? value, [int fallback = 0]) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return fallback;
}

double _asDouble(Object? value, [double fallback = 0]) {
  if (value is num) {
    return value.toDouble();
  }
  return fallback;
}

List<String> _asStringList(Object? value) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<String>()
      .where((label) => label.trim().isNotEmpty)
      .toList();
}

String _pullRequestLinkId(String repository, int number) {
  return '${repository}_$number'.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
}

int _issueProgressWeight(Issue issue) {
  return issue.resolution?.actualWeight ?? issue.weightEstimate?.value ?? 0;
}

DailyProgressPrediction _buildDailyProgressPrediction({
  required int targetWeight,
  required _DailyPaceBucket todayBucket,
  required List<_DailyPaceBucket> historicalBuckets,
  required DateTime now,
}) {
  if (targetWeight <= 0) {
    return const DailyProgressPrediction(
      finishProbability: 0,
      paceLabel: '未設定',
      advice: '目標を設定してください',
      color: Color(0xFF64748B),
      requiredAfternoonWeight: 0,
      historicalAfternoonMedian: 0,
      sampleCount: 0,
      usesFallback: true,
    );
  }

  final remainingWeight = _positive(targetWeight - todayBucket.totalWeight);
  final requiredAfternoonWeight = now.hour < 12
      ? _positive(targetWeight - todayBucket.morningWeight)
      : remainingWeight;
  final historicalAfternoonMedian = _median(
    historicalBuckets.map((bucket) => bucket.afternoonWeight).toList(),
  );

  if (todayBucket.totalWeight >= targetWeight) {
    final overWeight = todayBucket.totalWeight - targetWeight;
    return DailyProgressPrediction(
      finishProbability: 100,
      paceLabel: '達成',
      advice: overWeight > 0 ? '達成 · +W$overWeight' : '達成',
      color: const Color(0xFF15803D),
      requiredAfternoonWeight: 0,
      historicalAfternoonMedian: historicalAfternoonMedian,
      sampleCount: historicalBuckets.length,
      usesFallback: false,
    );
  }

  final comparableBuckets = historicalBuckets
      .where(
        (bucket) =>
            bucket.totalWeight > 0 &&
            bucket.weightAtCurrentTime <= todayBucket.weightAtCurrentTime,
      )
      .toList();
  final futureWeights = historicalBuckets
      .where((bucket) => bucket.totalWeight > 0)
      .map(
        (bucket) => _positive(bucket.totalWeight - bucket.weightAtCurrentTime),
      )
      .toList();

  final int finishProbability;
  final int sampleCount;
  final bool usesFallback;
  if (comparableBuckets.length >= 3) {
    final achievedDays = comparableBuckets
        .where((bucket) => bucket.totalWeight >= targetWeight)
        .length;
    finishProbability = (achievedDays / comparableBuckets.length * 100).round();
    sampleCount = comparableBuckets.length;
    usesFallback = false;
  } else {
    final projectedWeight = todayBucket.totalWeight + _median(futureWeights);
    finishProbability = (projectedWeight / targetWeight * 100)
        .round()
        .clamp(0, 95)
        .toInt();
    sampleCount = futureWeights.length;
    usesFallback = true;
  }

  final isMorning = now.hour < 12;
  if (finishProbability >= 75) {
    return DailyProgressPrediction(
      finishProbability: finishProbability,
      paceLabel: '順調',
      advice: '順調 · このペースなら達成見込み',
      color: const Color(0xFF15803D),
      requiredAfternoonWeight: requiredAfternoonWeight,
      historicalAfternoonMedian: historicalAfternoonMedian,
      sampleCount: sampleCount,
      usesFallback: usesFallback,
    );
  }

  if (finishProbability >= 45) {
    final advice = isMorning
        ? '午前遅め · 午後にW$requiredAfternoonWeight必要'
        : 'ペース遅め · 残りW$remainingWeight';
    return DailyProgressPrediction(
      finishProbability: finishProbability,
      paceLabel: '遅め',
      advice: advice,
      color: const Color(0xFFA16207),
      requiredAfternoonWeight: requiredAfternoonWeight,
      historicalAfternoonMedian: historicalAfternoonMedian,
      sampleCount: sampleCount,
      usesFallback: usesFallback,
    );
  }

  final advice = isMorning
      ? '達成厳しめ · 午後にW$requiredAfternoonWeight必要'
      : '達成厳しめ · いつもより速いペースが必要';
  return DailyProgressPrediction(
    finishProbability: finishProbability,
    paceLabel: '厳しめ',
    advice: advice,
    color: const Color(0xFFDC2626),
    requiredAfternoonWeight: requiredAfternoonWeight,
    historicalAfternoonMedian: historicalAfternoonMedian,
    sampleCount: sampleCount,
    usesFallback: usesFallback,
  );
}

int _positive(num value) {
  return value > 0 ? value.round() : 0;
}

double _median(List<int> values) {
  if (values.isEmpty) {
    return 0;
  }
  values.sort();
  final middle = values.length ~/ 2;
  if (values.length.isOdd) {
    return values[middle].toDouble();
  }
  return (values[middle - 1] + values[middle]) / 2;
}

bool _isAtOrBeforeTimeOfDay(DateTime value, DateTime cutoff) {
  if (value.hour != cutoff.hour) {
    return value.hour < cutoff.hour;
  }
  if (value.minute != cutoff.minute) {
    return value.minute <= cutoff.minute;
  }
  return value.second <= cutoff.second;
}

DateTime? _asDate(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return null;
}

Priority _priorityFromString(String value) {
  return Priority.values.firstWhere(
    (priority) => priority.name == value,
    orElse: () => Priority.medium,
  );
}

double _rankBetween(double? previousRank, double? nextRank) {
  if (previousRank != null && nextRank != null) {
    return (previousRank + nextRank) / 2;
  }
  if (previousRank != null) {
    return previousRank + 1000;
  }
  if (nextRank != null) {
    return nextRank - 1000;
  }
  return DateTime.now().millisecondsSinceEpoch.toDouble();
}

String _friendlyError(Object error) {
  if (error is FirebaseFunctionsException) {
    return error.message ?? error.code;
  }
  if (error is FirebaseException) {
    return error.message ?? error.code;
  }
  if (error is Error) {
    return error.toString();
  }
  return '$error';
}

DateTime _dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

String _formatDate(DateTime date) {
  return '${date.month}月${date.day}日';
}

String _dailyHistoryDateLabel(DateTime date) {
  final today = _dateOnly(DateTime.now());
  final targetDate = _dateOnly(date);
  final daysAgo = today.difference(targetDate).inDays;

  if (daysAgo == 0) {
    return '今日';
  }
  if (daysAgo == 1) {
    return '昨日';
  }
  return _formatDate(targetDate);
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
