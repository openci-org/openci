import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import 'firebase_options.dart';

const _functionsRegion = 'asia-northeast1';
const _githubOAuthClientId = String.fromEnvironment('GITHUB_OAUTH_CLIENT_ID');
const _closedStatusId = 'done';
const _compactTextScale = 0.94;
const _boardHorizontalPadding = 16.0;
const _boardBottomPadding = 18.0;
const _boardColumnWidth = 280.0;
const _boardColumnGap = 12.0;
const _compactBoardBreakpoint = 640.0;
const _compactColumnCollapsedLimit = 4;
const _defaultDailyWeightTarget = 20;

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
  final messenger = ScaffoldMessenger.maybeOf(context);
  final screenWidth = MediaQuery.sizeOf(context).width;
  final snackBarWidth = (screenWidth - 32).clamp(160.0, 260.0);
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        width: snackBarWidth,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1400),
      ),
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
  const IssueBoardPage({super.key});

  @override
  State<IssueBoardPage> createState() => _IssueBoardPageState();
}

class _IssueBoardPageState extends State<IssueBoardPage> {
  final _boardScrollController = ScrollController();
  late final String _workspaceId;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _issuesSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _githubConnectionSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _reposSubscription;
  var _isBootstrapping = true;
  var _isConnectingGitHub = false;
  var _isLoadingRepositories = false;
  var _isImportingIssues = false;
  var _isSyncingIssues = false;
  String? _githubLogin;
  String? _loadError;
  int _enabledRepoCount = 0;
  int _dailyWeightTarget = _defaultDailyWeightTarget;
  Set<String> _enabledRepoFullNames = {};
  final Set<String> _closingIssueIds = {};
  final Set<String> _estimatingIssueIds = {};
  final Set<String> _startingCursorAgentIssueIds = {};
  final List<BoardColumn> _columns = [
    BoardColumn(
      id: 'triage',
      title: 'Triage',
      description: '新着と要件確認',
      color: const Color(0xFF6366F1),
      issues: [],
    ),
    BoardColumn(
      id: 'backlog',
      title: 'Backlog',
      description: '着手待ち',
      color: const Color(0xFF0EA5E9),
      issues: [],
    ),
    BoardColumn(
      id: 'doing',
      title: 'In Progress',
      description: '今やっていること',
      color: const Color(0xFFF59E0B),
      issues: [],
    ),
    BoardColumn(
      id: 'review',
      title: 'Review',
      description: 'レビューと検証',
      color: const Color(0xFFA855F7),
      issues: [],
    ),
    BoardColumn(
      id: 'done',
      title: 'Done',
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
    final user = FirebaseAuth.instance.currentUser;
    _workspaceId = user?.uid ?? '';
    unawaited(_bootstrapWorkspace());
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
      'name': user.email ?? 'Personal workspace',
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
    _reposSubscription = workspaceRef
        .collection('githubRepos')
        .snapshots()
        .listen(_replaceRepositories, onError: _handleStreamError);
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

  void _replaceRepositories(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final enabledDocs = snapshot.docs
        .where((doc) => doc.data()['enabled'] == true)
        .toList();

    if (!mounted) {
      return;
    }

    setState(() {
      _enabledRepoCount = enabledDocs.length;
      _enabledRepoFullNames = {
        for (final doc in enabledDocs) _asString(doc.data()['fullName']),
      }..remove('');
    });
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
      _showSavedSnackBar('Already closed');
      return;
    }

    setState(() => _closingIssueIds.add(issueId));
    try {
      await _moveIssue(
        issueId: issueId,
        targetColumnId: _closedStatusId,
        targetIndex: 0,
      );
      _showSavedSnackBar('Closed');
    } catch (error) {
      _showSavedSnackBar(_friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => _closingIssueIds.remove(issueId));
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
      _showSavedSnackBar('Saved');
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

    final useBottomSheet = _usesBottomSheetEditor;
    final result = await _showIssueEditor<Object?>(
      useBottomSheet: useBottomSheet,
      builder: (context) => AddIssueDialog(
        columns: _columns,
        repositoryOptions: _enabledRepositoryOptions,
        initialIssue: issue,
        initialColumnId: sourceColumn.id,
        isEstimatingWeight: _estimatingIssueIds.contains(issueId),
        onEstimateIssueWeight: _estimateIssueWeight,
        isStartingCursorAgent: _startingCursorAgentIssueIds.contains(issueId),
        onStartCursorAgent: _startCursorAgent,
        isBottomSheet: useBottomSheet,
        workspaceId: _workspaceId,
      ),
    );

    if (result == null) {
      return;
    }

    if (result is CloseIssueDialogResult) {
      await _closeIssue(issueId);
      return;
    }

    if (result is! NewIssueDraft) {
      return;
    }

    try {
      await _updateIssue(issueId: issueId, draft: result);
      _showSavedSnackBar('Saved');
    } catch (error) {
      _showSavedSnackBar(_friendlyError(error));
    }
  }

  Future<void> _openIssueSearchDialog() async {
    final hasIssues = _columns.any((column) => column.issues.isNotEmpty);
    if (!hasIssues) {
      _showSavedSnackBar('検索できるIssueがありません');
      return;
    }

    final issueId = await showDialog<String>(
      context: context,
      builder: (context) => IssueSearchDialog(columns: _columns),
    );
    if (issueId == null || !mounted) {
      return;
    }

    await _openEditIssueDialog(issueId);
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
      'assignee': draft.assignee,
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
      _showSavedSnackBar('Weight estimated');
    } catch (error) {
      _showSavedSnackBar(_friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => _estimatingIssueIds.remove(issueId));
      }
    }
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
      _showSavedSnackBar('Cursor agent started');
    } catch (error) {
      _showSavedSnackBar(_friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => _startingCursorAgentIssueIds.remove(issueId));
      }
    }
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
      'assignee': draft.assignee,
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
      'assignee': draft.assignee,
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

    final screenWidth = MediaQuery.sizeOf(context).width;
    final snackBarWidth = screenWidth < 420 ? screenWidth - 32 : 320.0;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          width: snackBarWidth,
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1400),
        ),
      );
  }

  Future<void> _connectGitHub() async {
    if (_isConnectingGitHub) {
      return;
    }

    setState(() => _isConnectingGitHub = true);
    try {
      if (_githubOAuthClientId.isEmpty) {
        final token = await _openAccessTokenDialog();
        if (token == null || token.isEmpty) {
          return;
        }
        final data = await _callFunction('connectGitHub', {
          'workspaceId': _workspaceId,
          'accessToken': token,
        });
        _showSavedSnackBar('GitHub connected as ${_asString(data['login'])}');
        return;
      }

      final flowData = await _callFunction('startGitHubDeviceFlow', {
        'workspaceId': _workspaceId,
        'clientId': _githubOAuthClientId,
      });
      final flow = GitHubDeviceFlow.fromMap(flowData);
      if (!mounted) {
        return;
      }

      final completed = await showDialog<bool>(
        context: context,
        builder: (context) => GitHubDeviceFlowDialog(flow: flow),
      );
      if (completed != true) {
        return;
      }

      final data = await _callFunction('completeGitHubDeviceFlow', {
        'workspaceId': _workspaceId,
        'clientId': _githubOAuthClientId,
        'deviceCode': flow.deviceCode,
      });
      _showSavedSnackBar('GitHub connected as ${_asString(data['login'])}');
    } catch (error) {
      _showSavedSnackBar(_friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => _isConnectingGitHub = false);
      }
    }
  }

  Future<String?> _openAccessTokenDialog() async {
    final controller = TextEditingController();
    try {
      return showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('GitHub access token'),
          content: TextField(
            controller: controller,
            autofocus: true,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Personal access token',
              helperText:
                  '--dart-define=GITHUB_OAUTH_CLIENT_ID=... がないため、tokenで接続します。',
            ),
            onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Connect'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
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

      final batch = _firestore.batch();
      final reposRef = _firestore.collection(
        'workspaces/$_workspaceId/githubRepos',
      );
      for (final repo in repositories) {
        batch.set(reposRef.doc(_repoDocId(repo.fullName)), {
          ...repo.toFirestore(),
          'enabled': selected.contains(repo.fullName),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      await batch.commit();
      _showSavedSnackBar('${selected.length} repos selected');
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
        '${_asInt(data['imported'])} issues imported from ${_asInt(data['repositories'])} repos',
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
        '${_asInt(data['synced'])} synced, ${_asInt(data['failed'])} failed',
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

  Future<void> _openDailyWeightTargetDialog(DailyProgressStats stats) async {
    final nextTarget = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          DailyProgressSheet(currentTarget: _dailyWeightTarget, stats: stats),
    );

    if (nextTarget == null || !mounted) {
      return;
    }

    setState(() => _dailyWeightTarget = nextTarget);
  }

  @override
  void dispose() {
    unawaited(_issuesSubscription?.cancel());
    unawaited(_githubConnectionSubscription?.cancel());
    unawaited(_reposSubscription?.cancel());
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
    final isConnected = _githubLogin != null && _githubLogin!.isNotEmpty;
    final onSignOut = FirebaseAuth.instance.signOut;

    return IssueBoardShortcuts(
      onAddIssue: () => unawaited(_openAddIssueDialog()),
      onSearchIssues: () => unawaited(_openIssueSearchDialog()),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: isCompactLayout
            ? AppBar(
                title: const Text(
                  'イマ',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                backgroundColor: const Color(0xFFF8FAFC),
                foregroundColor: const Color(0xFF0F172A),
                elevation: 0,
                scrolledUnderElevation: 0,
                actions: [
                  CompactBoardMenuButton(
                    isConnected: isConnected,
                    isBusy: _isBusy,
                    repoCount: _enabledRepoCount,
                    onConnectGitHub: _connectGitHub,
                    onSelectRepositories: _selectRepositories,
                    onImportIssues: _importGitHubIssues,
                    onSyncIssues: _syncGitHubIssues,
                    onSearchIssues: _openIssueSearchDialog,
                    onSignOut: onSignOut,
                  ),
                  const SizedBox(width: 4),
                ],
              )
            : null,
        floatingActionButton: isCompactLayout
            ? FloatingActionButton.extended(
                onPressed: () => unawaited(_openAddIssueDialog()),
                icon: const Icon(Icons.add_rounded),
                label: const Text('New'),
              )
            : null,
        body: SafeArea(
          child: Column(
            children: [
              if (!isCompactLayout)
                BoardHeader(
                  openIssues: openIssues,
                  closedIssues: closedIssues,
                  dailyProgressStats: dailyProgressStats,
                  onChangeDailyWeightTarget: () => unawaited(
                    _openDailyWeightTargetDialog(dailyProgressStats),
                  ),
                  onSignOut: onSignOut,
                ),
              if (_isBootstrapping) const LinearProgressIndicator(),
              if (isCompactLayout)
                DailyProgressStrip(
                  stats: dailyProgressStats,
                  isCompact: true,
                  onTap: () => unawaited(
                    _openDailyWeightTargetDialog(dailyProgressStats),
                  ),
                ),
              BoardToolbar(
                onConnectGitHub: _connectGitHub,
                onSelectRepositories: _selectRepositories,
                onImportIssues: _importGitHubIssues,
                onSyncIssues: _syncGitHubIssues,
                onSearchIssues: _openIssueSearchDialog,
                githubLogin: _githubLogin,
                repoCount: _enabledRepoCount,
                isBusy: _isBusy,
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
                        constraints.maxWidth < _compactBoardBreakpoint;

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
                            startingCursorAgentIssueIds:
                                _startingCursorAgentIssueIds,
                            onIssueDropped: _moveIssue,
                            onAddIssue: (columnId) => unawaited(
                              _openAddIssueDialog(initialColumnId: columnId),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final column in _columns) ...[
                                BoardColumnView(
                                  column: column,
                                  startingCursorAgentIssueIds:
                                      _startingCursorAgentIssueIds,
                                  onIssueDropped: _moveIssue,
                                  onAddIssue: (columnId) => unawaited(
                                    _openAddIssueDialog(
                                      initialColumnId: columnId,
                                    ),
                                  ),
                                  onIssueTapped: _openEditIssueDialog,
                                  onStartCursorAgent: _startCursorAgent,
                                ),
                                if (column != _columns.last)
                                  const SizedBox(width: _boardColumnGap),
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
    );
  }
}

class IssueBoardShortcuts extends StatelessWidget {
  const IssueBoardShortcuts({
    super.key,
    required this.onAddIssue,
    required this.onSearchIssues,
    required this.child,
  });

  final VoidCallback onAddIssue;
  final VoidCallback onSearchIssues;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyT, meta: true): onAddIssue,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
            onSearchIssues,
      },
      child: Focus(autofocus: true, child: child),
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
    required this.onSignOut,
  });

  final int openIssues;
  final List<Issue> closedIssues;
  final DailyProgressStats dailyProgressStats;
  final VoidCallback onChangeDailyWeightTarget;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 520;
        final title = Text(
          'イマ',
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
                Align(alignment: Alignment.centerLeft, child: title),
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
                children: [
                  Expanded(child: title),
                  TextButton(
                    onPressed: () => unawaited(onSignOut()),
                    child: const Text('サインアウト'),
                  ),
                ],
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
            'open issues',
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
  });

  final int openIssues;
  final List<Issue> closedIssues;
  final DailyProgressStats dailyProgressStats;
  final VoidCallback onDailyProgressTap;

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
              label: 'Open',
              value: '$openIssues',
              detail: 'issues',
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
          ],
        ),
      ),
    );
  }
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
  });

  final String label;
  final String value;
  final String detail;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
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
    final sumAbsError = deltas.fold<int>(0, (sum, delta) => sum + delta.abs());
    final sumDelta = deltas.fold<int>(0, (sum, delta) => sum + delta);

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
  });

  final int currentTarget;
  final DailyProgressStats stats;

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
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
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
    required this.githubLogin,
    required this.repoCount,
    required this.isBusy,
  });

  final VoidCallback onConnectGitHub;
  final VoidCallback onSelectRepositories;
  final VoidCallback onImportIssues;
  final VoidCallback onSyncIssues;
  final VoidCallback onSearchIssues;
  final String? githubLogin;
  final int repoCount;
  final bool isBusy;

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
              constraints: const BoxConstraints(maxWidth: 820),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (!isConnected)
                    FilledButton.icon(
                      onPressed: isBusy ? null : onConnectGitHub,
                      icon: const Icon(Icons.link_rounded, size: 16),
                      label: const Text('Connect GitHub'),
                    ),
                  if (isConnected) ...[
                    ToolbarChip(
                      icon: Icons.account_tree_outlined,
                      label: '$repoCount repos',
                      tooltip: 'Select GitHub repositories',
                      onPressed: isBusy ? null : onSelectRepositories,
                    ),
                    ToolbarChip(
                      icon: Icons.download_rounded,
                      label: 'Import',
                      tooltip: 'Import GitHub issues',
                      onPressed: isBusy ? null : onImportIssues,
                    ),
                    ToolbarChip(
                      icon: Icons.sync_outlined,
                      label: 'Sync',
                      tooltip: 'Sync pending issues',
                      onPressed: isBusy ? null : onSyncIssues,
                    ),
                  ],
                  ToolbarChip(
                    icon: Icons.search_outlined,
                    label: 'Search',
                    tooltip: 'Search issues (⌘K)',
                    onPressed: onSearchIssues,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class CompactBoardMenuButton extends StatelessWidget {
  const CompactBoardMenuButton({
    super.key,
    required this.isConnected,
    required this.isBusy,
    required this.repoCount,
    required this.onConnectGitHub,
    required this.onSelectRepositories,
    required this.onImportIssues,
    required this.onSyncIssues,
    required this.onSearchIssues,
    required this.onSignOut,
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

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'ボード操作',
      icon: const Icon(Icons.menu_rounded),
      onSelected: (value) {
        switch (value) {
          case 'github':
            onConnectGitHub();
          case 'repos':
            onSelectRepositories();
          case 'import':
            onImportIssues();
          case 'sync':
            onSyncIssues();
          case 'search':
            onSearchIssues();
          case 'signOut':
            unawaited(onSignOut());
        }
      },
      itemBuilder: (context) => [
        if (!isConnected)
          PopupMenuItem(
            value: 'github',
            enabled: !isBusy,
            child: const _CompactMenuItem(
              icon: Icons.link_rounded,
              label: 'Connect GitHub',
            ),
          ),
        PopupMenuItem(
          value: 'repos',
          enabled: !isBusy && isConnected,
          child: _CompactMenuItem(
            icon: Icons.account_tree_outlined,
            label: '$repoCount repos',
          ),
        ),
        PopupMenuItem(
          value: 'import',
          enabled: !isBusy && isConnected,
          child: const _CompactMenuItem(
            icon: Icons.download_rounded,
            label: 'Import issues',
          ),
        ),
        PopupMenuItem(
          value: 'sync',
          enabled: !isBusy && isConnected,
          child: const _CompactMenuItem(
            icon: Icons.sync_outlined,
            label: 'Sync pending',
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'search',
          child: _CompactMenuItem(
            icon: Icons.search_outlined,
            label: 'Search issues',
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'signOut',
          child: _CompactMenuItem(icon: Icons.logout_rounded, label: 'サインアウト'),
        ),
      ],
    );
  }
}

class _CompactMenuItem extends StatelessWidget {
  const _CompactMenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 10),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
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
  const IssueSearchDialog({super.key, required this.columns});

  final List<BoardColumn> columns;

  @override
  State<IssueSearchDialog> createState() => _IssueSearchDialogState();
}

class _IssueSearchDialogState extends State<IssueSearchDialog> {
  final _queryController = TextEditingController();

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

  void _select(_IssueSearchEntry entry) {
    Navigator.of(context).pop(entry.issue.id);
  }

  void _selectFirstMatch() {
    final entries = _filteredEntries;
    if (entries.isEmpty) {
      return;
    }

    _select(entries.first);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final query = _queryController.text;
    final entries = _filteredEntries;
    final resultMaxHeight = (screenSize.height - 230)
        .clamp(180.0, 420.0)
        .toDouble();

    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.fromLTRB(16, 72, 16, 16),
      backgroundColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 42,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
                    ),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF2563EB),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _queryController,
                          autofocus: true,
                          textInputAction: TextInputAction.search,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _selectFirstMatch(),
                          decoration: const InputDecoration.collapsed(
                            hintText: 'Search issues...',
                            hintStyle: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (query.isNotEmpty)
                        IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _queryController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded),
                        )
                      else
                        const _IssueSearchShortcutPill(label: '⌘K'),
                      IconButton(
                        tooltip: 'Close search',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
                  child: Row(
                    children: [
                      Text(
                        '${entries.length} results',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const Spacer(),
                      const _IssueSearchShortcutPill(label: 'Enter to open'),
                    ],
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: resultMaxHeight),
                  child: entries.isEmpty
                      ? _IssueSearchEmptyState(hasQuery: query.isNotEmpty)
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                          itemCount: entries.length,
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            return _IssueSearchResultTile(
                              entry: entry,
                              onTap: () => _select(entry),
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
  const _IssueSearchResultTile({required this.entry, required this.onTap});

  final _IssueSearchEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final issue = entry.issue;
    final labels = issue.labels.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                          if (issue.assignee.trim().isNotEmpty)
                            _IssueSearchMetaPill(label: issue.assignee),
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
      issue.assignee,
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

class GitHubDeviceFlowDialog extends StatelessWidget {
  const GitHubDeviceFlowDialog({super.key, required this.flow});

  final GitHubDeviceFlow flow;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('GitHub device login'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('GitHubで下のコードを入力して、認証が終わったら続行してください。'),
            const SizedBox(height: 16),
            SelectableText(
              flow.userCode,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(flow.verificationUri),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: flow.userCode)),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy code'),
                ),
                OutlinedButton.icon(
                  onPressed: () => Clipboard.setData(
                    ClipboardData(text: flow.verificationUri),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy URL'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('認証したので続行'),
        ),
      ],
    );
  }
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
      title: const Text('Select GitHub repositories'),
      content: SizedBox(
        width: 520,
        height: 480,
        child: widget.repositories.isEmpty
            ? const Center(child: Text('Repositoryが見つかりませんでした。'))
            : ListView.builder(
                itemCount: widget.repositories.length,
                itemBuilder: (context, index) {
                  final repo = widget.repositories[index];
                  final selected = _selected.contains(repo.fullName);

                  return CheckboxListTile(
                    value: selected,
                    title: Text(repo.fullName),
                    subtitle: Text(
                      '${repo.private ? 'private' : 'public'} / ${repo.defaultBranch}',
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
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => setState(_selected.clear),
          child: const Text('Clear'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: Text('Save ${_selected.length} repos'),
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
    this.initialColumnId,
    this.isEstimatingWeight = false,
    this.onEstimateIssueWeight,
    this.isStartingCursorAgent = false,
    this.onStartCursorAgent,
    this.isBottomSheet = false,
    this.workspaceId,
  });

  final List<BoardColumn> columns;
  final List<String> repositoryOptions;
  final Issue? initialIssue;
  final String? initialColumnId;
  final bool isEstimatingWeight;
  final Future<void> Function(String issueId)? onEstimateIssueWeight;
  final bool isStartingCursorAgent;
  final Future<void> Function(String issueId)? onStartCursorAgent;
  final bool isBottomSheet;
  final String? workspaceId;

  @override
  State<AddIssueDialog> createState() => _AddIssueDialogState();
}

class _AddIssueDialogState extends State<AddIssueDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _githubUrlController = TextEditingController();
  final _assigneeController = TextEditingController(text: 'MF');
  final _labelsController = TextEditingController(text: 'feature, mobile');
  String? _selectedRepo;
  late String _selectedColumnId;
  Priority _priority = Priority.medium;
  DateTime? _dueDate;
  var _isEstimatingWeight = false;
  var _isStartingCursorAgent = false;
  Issue? _liveIssue;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _issueSubscription;

  @override
  void initState() {
    super.initState();
    final issue = widget.initialIssue;

    _selectedColumnId = widget.initialColumnId ?? widget.columns.first.id;
    _selectedRepo = widget.repositoryOptions.isEmpty
        ? null
        : widget.repositoryOptions.first;

    if (issue != null) {
      _liveIssue = issue;
      _listenToIssue(issue.id);
      _titleController.text = issue.title;
      _bodyController.text = issue.body;
      _githubUrlController.text = issue.githubUrl ?? '';
      _selectedRepo = widget.repositoryOptions.contains(issue.repo)
          ? issue.repo
          : null;
      _assigneeController.text = issue.assignee;
      _labelsController.text = issue.labels.join(', ');
      _priority = issue.priority;
      _dueDate = issue.dueDate;
    }
  }

  void _listenToIssue(String issueId) {
    final workspaceId = widget.workspaceId;
    if (workspaceId == null || workspaceId.isEmpty) {
      return;
    }
    _issueSubscription = FirebaseFirestore.instance
        .doc('workspaces/$workspaceId/issues/$issueId')
        .snapshots()
        .listen((snapshot) {
          if (!mounted || !snapshot.exists) return;
          setState(() {
            _liveIssue = Issue.fromDocument(snapshot);
          });
        });
  }

  @override
  void dispose() {
    _issueSubscription?.cancel();
    _titleController.dispose();
    _bodyController.dispose();
    _githubUrlController.dispose();
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
        repo: _selectedRepo ?? '',
        githubUrl: _normalizedOptionalUrl(_githubUrlController.text),
        assignee: _assigneeController.text.trim(),
        labels: labels,
        columnId: _selectedColumnId,
        priority: _priority,
        dueDate: _dueDate,
      ),
    );
  }

  void _closeIssue() {
    Navigator.of(context).pop(const CloseIssueDialogResult());
  }

  Future<void> _estimateIssueWeight() async {
    final issue = widget.initialIssue;
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

  Future<void> _startCursorAgent() async {
    final issue = widget.initialIssue;
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

  void _copyGitHubUrl() {
    unawaited(
      _copyTextToClipboard(
        context,
        text: _githubUrlController.text,
        successMessage: 'GitHub link copied',
      ),
    );
  }

  void _openGitHubUrl() {
    final url = _githubUrlController.text.trim();
    if (url.isNotEmpty) {
      unawaited(_launchUrlExternal(url));
    }
  }

  Future<void> _pasteGitHubUrl() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      if (!mounted) {
        return;
      }
      _showFloatingSnackBar(context, 'Clipboard is empty');
      return;
    }

    _githubUrlController.text = text;
    _githubUrlController.selection = TextSelection.collapsed(
      offset: text.length,
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
    final isEditing = widget.initialIssue != null;
    final canCloseIssue =
        isEditing && widget.initialIssue!.statusId != _closedStatusId;
    final title = isEditing ? 'Edit GitHub issue' : 'New GitHub issue';
    final description = isEditing
        ? '${widget.initialIssue!.displayId}を編集します。⌘Enterで保存できます。'
        : 'GitHub issueを作成してボードへ追加します。⌘Tで開いて、⌘Enterで保存できます。';
    final formContent = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.isBottomSheet) ...[
            _DialogHeader(title: title, description: description),
            const SizedBox(height: 20),
          ],
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
            repositories: widget.repositoryOptions,
            selectedRepository: _selectedRepo,
            onRepositoryChanged: (value) {
              setState(() => _selectedRepo = value);
            },
            assigneeController: _assigneeController,
            decorationBuilder: _inputDecoration,
          ),
          if (isEditing) ...[
            const SizedBox(height: 14),
            _GitHubLinkField(
              controller: _githubUrlController,
              decoration: _inputDecoration(
                label: 'GitHub link',
                hint: 'https://github.com/openci/ima/issues/123',
              ),
              onOpen: _openGitHubUrl,
              onCopy: _copyGitHubUrl,
              onPaste: _pasteGitHubUrl,
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
              label: 'Labels',
              hint: 'feature, github, mobile',
            ),
            onFieldSubmitted: (_) => _saveIssue(),
          ),
          if (isEditing) ...[
            const SizedBox(height: 14),
            IssueWeightPanel(
              issue: _liveIssue ?? widget.initialIssue!,
              isEstimating: widget.isEstimatingWeight || _isEstimatingWeight,
              onEstimate: widget.onEstimateIssueWeight == null
                  ? null
                  : _estimateIssueWeight,
            ),
            const SizedBox(height: 14),
            CursorAgentPanel(
              issue: _liveIssue ?? widget.initialIssue!,
              isStarting:
                  widget.isStartingCursorAgent || _isStartingCursorAgent,
              onStart: widget.onStartCursorAgent == null
                  ? null
                  : _startCursorAgent,
            ),
          ],
          if (!widget.isBottomSheet) ...[
            const SizedBox(height: 24),
            _DialogActions(
              isEditing: isEditing,
              canCloseIssue: canCloseIssue,
              onCancel: () => Navigator.of(context).pop(),
              onCloseIssue: _closeIssue,
              onSaveIssue: _saveIssue,
            ),
          ],
        ],
      ),
    );
    final content = ClipRRect(
      borderRadius: widget.isBottomSheet
          ? const BorderRadius.vertical(top: Radius.circular(28))
          : BorderRadius.circular(isCompactDialog ? 22 : 28),
      child: Material(
        color: Colors.white,
        child: widget.isBottomSheet
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BottomSheetHeader(title: title),
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
            : SingleChildScrollView(
                padding: EdgeInsets.all(isCompactDialog ? 18 : 24),
                child: formContent,
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
                backgroundColor: Colors.transparent,
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
      child: const Text('Cancel'),
    );
    final closeButton = OutlinedButton.icon(
      onPressed: onCloseIssue,
      icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
      label: const Text('Close issue'),
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
      label: Text(isEditing ? 'Save changes' : 'Add issue'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );

    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: LayoutBuilder(
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
      ),
    );
  }
}

class _BottomSheetHeader extends StatelessWidget {
  const _BottomSheetHeader({required this.title});

  final String title;

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
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
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
      label: const Text('Close issue'),
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
      label: Text(isEditing ? 'Save changes' : 'Add issue'),
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

class _GitHubLinkField extends StatelessWidget {
  const _GitHubLinkField({
    required this.controller,
    required this.decoration,
    required this.onOpen,
    required this.onCopy,
    required this.onPaste,
  });

  final TextEditingController controller;
  final InputDecoration decoration;
  final VoidCallback onOpen;
  final VoidCallback onCopy;
  final Future<void> Function() onPaste;

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
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: hasUrl ? onOpen : null,
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Open'),
                ),
                OutlinedButton.icon(
                  onPressed: hasUrl ? onCopy : null,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy'),
                ),
                OutlinedButton.icon(
                  onPressed: () => unawaited(onPaste()),
                  icon: const Icon(Icons.content_paste_rounded, size: 18),
                  label: const Text('Paste'),
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
            Padding(padding: const EdgeInsets.only(top: 4), child: actions),
          ],
        );
      },
    );
  }
}

class _RepoAndAssigneeFields extends StatelessWidget {
  const _RepoAndAssigneeFields({
    required this.repositories,
    required this.selectedRepository,
    required this.onRepositoryChanged,
    required this.assigneeController,
    required this.decorationBuilder,
  });

  final List<String> repositories;
  final String? selectedRepository;
  final ValueChanged<String> onRepositoryChanged;
  final TextEditingController assigneeController;
  final InputDecoration Function({required String label, String? hint})
  decorationBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final repositoryField = DropdownButtonFormField<String>(
          initialValue: selectedRepository,
          decoration: decorationBuilder(
            label: 'Repository',
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
        final assigneeField = TextFormField(
          controller: assigneeController,
          textInputAction: TextInputAction.next,
          decoration: decorationBuilder(label: 'Assignee', hint: 'MF'),
          validator: (value) =>
              value == null || value.trim().isEmpty ? '担当者を入力してください' : null,
        );

        if (constraints.maxWidth < 560) {
          return Column(
            children: [
              repositoryField,
              const SizedBox(height: 12),
              assigneeField,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: repositoryField),
            const SizedBox(width: 12),
            SizedBox(width: 170, child: assigneeField),
          ],
        );
      },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final statusField = DropdownButtonFormField<String>(
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
        );
        final priorityField = DropdownButtonFormField<Priority>(
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
    this.startingCursorAgentIssueIds = const {},
    required this.onIssueDropped,
    required this.onAddIssue,
    required this.onIssueTapped,
    this.onStartCursorAgent,
  });

  final BoardColumn column;
  final Set<String> startingCursorAgentIssueIds;
  final IssueDropCallback onIssueDropped;
  final ValueChanged<String> onAddIssue;
  final ValueChanged<String> onIssueTapped;
  final ValueChanged<String>? onStartCursorAgent;

  @override
  Widget build(BuildContext context) {
    final visibleIssues = _visibleIssuesForColumn(column);

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
                            sourceColumnId: column.id,
                            index: rankIndex < 0 ? index : rankIndex,
                            isStartingCursorAgent: startingCursorAgentIssueIds
                                .contains(issue.id),
                            onTap: () => onIssueTapped(issue.id),
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
    this.startingCursorAgentIssueIds = const {},
    required this.onIssueDropped,
    required this.onAddIssue,
    required this.onIssueTapped,
    this.onStartCursorAgent,
  });

  final BoardColumn column;
  final Set<String> startingCursorAgentIssueIds;
  final IssueDropCallback onIssueDropped;
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
              for (var index = 0; index < displayedIssues.length; index++) ...[
                Builder(
                  builder: (context) {
                    final issue = displayedIssues[index];
                    final rankIndex = widget.column.issues.indexWhere(
                      (candidate) => candidate.id == issue.id,
                    );

                    return IssueCardDropTarget(
                      issue: issue,
                      sourceColumnId: widget.column.id,
                      index: rankIndex < 0 ? index : rankIndex,
                      isStartingCursorAgent: widget.startingCursorAgentIssueIds
                          .contains(issue.id),
                      onTap: () => widget.onIssueTapped(issue.id),
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

List<Issue> _visibleIssuesForColumn(BoardColumn column) {
  if (column.id != _closedStatusId) {
    return column.issues;
  }

  return [...column.issues]..sort(_compareDoneIssues);
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
    required this.onAddIssue,
  });

  final BoardColumn column;
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
    required this.onPressed,
  });

  final String columnTitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 26,
      child: IconButton(
        tooltip: 'New issue in $columnTitle',
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
        icon: const Icon(Icons.add_rounded, size: 16),
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
    required this.sourceColumnId,
    required this.index,
    required this.isStartingCursorAgent,
    required this.onTap,
    this.onStartCursorAgent,
    required this.onIssueDropped,
  });

  final Issue issue;
  final String sourceColumnId;
  final int index;
  final bool isStartingCursorAgent;
  final VoidCallback onTap;
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
                sourceColumnId: widget.sourceColumnId,
                isStartingCursorAgent: widget.isStartingCursorAgent,
                onTap: widget.onTap,
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
    required this.sourceColumnId,
    required this.isStartingCursorAgent,
    required this.onTap,
    this.onStartCursorAgent,
  });

  final Issue issue;
  final String sourceColumnId;
  final bool isStartingCursorAgent;
  final VoidCallback onTap;
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
    return Listener(
      onPointerDown: _startLiftPreviewTimer,
      onPointerMove: _handlePointerMove,
      onPointerUp: (_) => _handlePointerUp(),
      onPointerCancel: (_) => _finishDragInteraction(),
      child: Draggable<IssueDragData>(
        data: IssueDragData(
          issueId: widget.issue.id,
          sourceColumnId: widget.sourceColumnId,
        ),
        hitTestBehavior: HitTestBehavior.opaque,
        onDragStarted: _finishDragInteraction,
        onDragCompleted: _finishDragInteraction,
        onDraggableCanceled: (_, _) => _finishDragInteraction(),
        onDragEnd: (_) => _finishDragInteraction(),
        feedback: Material(
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
                    child: IssueCard(issue: widget.issue, isDragging: true),
                  ),
                ),
              ),
            ),
          ),
        ),
        childWhenDragging: Transform.scale(
          scale: 0.98,
          child: Opacity(
            opacity: 0.28,
            child: IssueCard(issue: widget.issue, isDragPlaceholder: true),
          ),
        ),
        child: GestureDetector(
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
              child: IssueCard(
                issue: widget.issue,
                isDragging: _isLiftPreviewVisible,
                isStartingCursorAgent: widget.isStartingCursorAgent,
                onStartCursorAgent: widget.onStartCursorAgent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class IssueCard extends StatelessWidget {
  const IssueCard({
    super.key,
    required this.issue,
    this.isDragging = false,
    this.isDragPlaceholder = false,
    this.isStartingCursorAgent = false,
    this.onStartCursorAgent,
  });

  final Issue issue;
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
        ? 'Actual weight $cardWeight'
        : 'Weight $cardWeight / confidence ${((weightEstimate?.confidence ?? 0) * 100).round()}%';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDragPlaceholder ? const Color(0xFFF8FAFC) : Colors.white,
        border: Border.all(
          color: isDragging || isDragPlaceholder
              ? const Color(0xFF38BDF8).withValues(alpha: 0.48)
              : const Color(0xFFE2E8F0),
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDragging
                  ? 0.22
                  : isDragPlaceholder
                  ? 0
                  : 0.04,
            ),
            blurRadius: isDragging ? 30 : 10,
            offset: Offset(0, isDragging ? 18 : 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RepoBadge(repo: issue.repo),
              if (cardWeight != null) ...[
                const SizedBox(width: 6),
                WeightBadge(
                  value: cardWeight,
                  tooltip: cardWeightTooltip,
                  isActual: issue.statusId == _closedStatusId,
                ),
              ],
              const Spacer(),
              PriorityDot(priority: issue.priority),
              if (githubUrl != null) ...[
                const SizedBox(width: 6),
                GitHubLinkOpenButton(url: githubUrl),
                const SizedBox(width: 6),
                CursorAgentCardButton(
                  issue: issue,
                  isStarting: isStartingCursorAgent,
                  onStart: onStartCursorAgent,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            issue.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          if (issue.body.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
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
          const SizedBox(height: 10),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              for (final label in issue.labels) LabelPill(label: label),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              CircleAvatar(
                radius: 12,
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
              const SizedBox(width: 6),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        issue.displayId,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    IssueIdCopyButton(issueId: issue.displayId),
                  ],
                ),
              ),
              if (issue.dueDate != null) ...[
                const SizedBox(width: 6),
                DueDatePill(dueDate: issue.dueDate!),
              ],
              const Spacer(),
              if (issue.pullRequests.isNotEmpty) ...[
                PullRequestBadge(pullRequests: issue.pullRequests),
                const SizedBox(width: 8),
              ],
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 15,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(width: 3),
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

class IssueIdCopyButton extends StatelessWidget {
  const IssueIdCopyButton({super.key, required this.issueId});

  final String issueId;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 22,
      child: IconButton(
        tooltip: 'Copy issue ID',
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        onPressed: () => unawaited(
          _copyTextToClipboard(
            context,
            text: issueId,
            successMessage: 'Issue ID copied',
          ),
        ),
        icon: const Icon(
          Icons.copy_rounded,
          size: 13,
          color: Color(0xFF94A3B8),
        ),
      ),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.alt_route_rounded,
              size: 15,
              color: Color(0xFF0EA5E9),
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF0369A1),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GitHubLinkOpenButton extends StatelessWidget {
  const GitHubLinkOpenButton({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 26,
      child: IconButton(
        tooltip: 'Open in GitHub',
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        onPressed: () => unawaited(_launchUrlExternal(url)),
        icon: const Icon(Icons.open_in_new_rounded, size: 16),
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
        tooltip: isRunning ? 'Cursor agent is running' : 'Start Cursor agent',
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
    return Flexible(
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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

class IssueWeightPanel extends StatelessWidget {
  const IssueWeightPanel({
    super.key,
    required this.issue,
    required this.isEstimating,
    this.onEstimate,
  });

  final Issue issue;
  final bool isEstimating;
  final Future<void> Function()? onEstimate;

  @override
  Widget build(BuildContext context) {
    final estimate = issue.weightEstimate;
    final value = estimate?.value;
    final resolution = issue.resolution;
    final actualWeight = resolution?.actualWeight;
    final isClosed = issue.statusId == 'done';
    final subtitle = switch (estimate?.status) {
      'done' when value != null =>
        '${(estimate!.confidence * 100).round()}% confidence'
            '${estimate.estimatedAt == null ? '' : ' / ${_formatDate(estimate.estimatedAt!)}'}',
      'failed' => estimate?.error ?? 'Weight estimation failed',
      'estimating' => 'Estimating weight...',
      _ => 'Not estimated yet',
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
              OutlinedButton.icon(
                onPressed: isEstimating ? null : onEstimate,
                icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                label: Text(value == null ? 'Estimate' : 'Re-estimate'),
              ),
            ],
          ),
          if (isClosed && actualWeight != null) ...[
            const SizedBox(height: 12),
            _ActualWeightRow(
              predictedWeight: value,
              actualWeight: actualWeight,
              delta: resolution?.weightDelta,
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
        'Cursor agent is running. Run ID: ${agent!.shortRunId}',
      'starting' when !hasPullRequest => 'Starting Cursor agent...',
      'done' ||
      'running' ||
      'starting' => 'Cursor agent opened a pull request.',
      'failed' => agent?.errorMessage ?? 'Cursor agent failed to start.',
      _ when hasGitHubIssue =>
        'Start a Cursor Cloud Agent to work on this issue and create a PR.',
      _ => 'Connect this issue to GitHub before starting an agent.',
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
            label: Text(isRunning ? 'Running' : 'Start'),
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
        width: 10,
        height: 10,
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

class CloseIssueDialogResult {
  const CloseIssueDialogResult();
}

class NewIssueDraft {
  const NewIssueDraft({
    required this.title,
    required this.body,
    required this.repo,
    required this.githubUrl,
    required this.assignee,
    required this.labels,
    required this.columnId,
    required this.priority,
    required this.dueDate,
  });

  final String title;
  final String body;
  final String repo;
  final String? githubUrl;
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

class IssueResolution {
  const IssueResolution({
    this.actualWeight,
    this.weightDelta,
    this.cycleTimeMs,
    this.leadTimeMs,
    this.workStartSource = '',
  });

  static IssueResolution? fromMap(Map<String, dynamic> data) {
    if (data.isEmpty) {
      return null;
    }
    final actualWeight = _asInt(data['actualWeight']);
    return IssueResolution(
      actualWeight: actualWeight > 0 ? actualWeight : null,
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
    );
  }

  final int? actualWeight;
  final int? weightDelta;
  final int? cycleTimeMs;
  final int? leadTimeMs;
  final String workStartSource;
}

class Issue {
  const Issue({
    required this.id,
    String? displayId,
    this.issueKey,
    required this.repo,
    required this.title,
    this.body = '',
    this.githubUrl,
    required this.assignee,
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
      displayId: issueKey.isNotEmpty
          ? issueKey
          : number > 0
          ? '#$number'
          : doc.id,
      repo: repo,
      title: _asString(data['title'], '#$number'),
      body: _asString(data['body']),
      githubUrl: _normalizedOptionalUrl(_asString(githubIssue['url'])),
      assignee: _asString(data['assignee'], '-'),
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
      cursorAgent: CursorAgentState.fromMap(_asMap(data['cursorAgent'])),
    );
  }

  Issue copyWith({String? statusId, double? rank, DateTime? closedAt}) {
    return Issue(
      id: id,
      displayId: displayId,
      issueKey: issueKey,
      repo: repo,
      title: title,
      body: body,
      githubUrl: githubUrl,
      assignee: assignee,
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
      cursorAgent: cursorAgent,
    );
  }

  final String id;
  final String displayId;
  final String? issueKey;
  final String repo;
  final String title;
  final String body;
  final String? githubUrl;
  final String assignee;
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
  });

  factory IssuePullRequest.fromMap(Map<String, dynamic> data) {
    return IssuePullRequest(
      number: _asInt(data['number']),
      title: _asString(data['title'], 'Pull request'),
      url: _normalizedOptionalUrl(_asString(data['url'])),
      state: _asString(data['state'], 'open'),
      merged: data['merged'] == true,
      branch: _asString(data['branch']),
    );
  }

  final int number;
  final String title;
  final String? url;
  final String state;
  final bool merged;
  final String branch;
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
    this.estimatedAt,
    this.error,
  });

  static IssueWeightEstimate? fromMap(Map<String, dynamic> data) {
    if (data.isEmpty) {
      return null;
    }
    final value = _asInt(data['value']);
    return IssueWeightEstimate(
      status: _asString(data['status'], value > 0 ? 'done' : 'unknown'),
      value: value > 0 ? value : null,
      confidence: _asDouble(data['confidence']),
      reason: _asString(data['reason']),
      model: _asString(data['model']),
      promptVersion: _asString(data['promptVersion']),
      inputHash: _asString(data['inputHash']),
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

  Map<String, Object?> toFirestore() {
    return {
      'fullName': fullName,
      'name': name,
      'owner': owner,
      'private': private,
      'defaultBranch': defaultBranch,
    };
  }
}

class GitHubDeviceFlow {
  const GitHubDeviceFlow({
    required this.deviceCode,
    required this.userCode,
    required this.verificationUri,
    required this.expiresIn,
    required this.interval,
  });

  factory GitHubDeviceFlow.fromMap(Map<String, dynamic> data) {
    return GitHubDeviceFlow(
      deviceCode: _asString(data['deviceCode']),
      userCode: _asString(data['userCode']),
      verificationUri: _asString(data['verificationUri']),
      expiresIn: _asInt(data['expiresIn'], 900),
      interval: _asInt(data['interval'], 5),
    );
  }

  final String deviceCode;
  final String userCode;
  final String verificationUri;
  final int expiresIn;
  final int interval;
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

String _repoDocId(String fullName) {
  return fullName.replaceAll('/', '__');
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
