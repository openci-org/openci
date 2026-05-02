import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';

const _functionsRegion = 'asia-northeast1';
const _githubOAuthClientId = String.fromEnvironment('GITHUB_OAUTH_CLIENT_ID');
const _closedStatusId = 'done';
const _compactTextScale = 0.94;
const _boardHorizontalPadding = 16.0;
const _boardBottomPadding = 18.0;
const _boardColumnWidth = 280.0;
const _boardColumnGap = 12.0;

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
      title: 'IssuePilot',
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
  Timestamp? _lastImportedAt;
  Set<String> _enabledRepoFullNames = {};
  final Set<String> _closingIssueIds = {};
  final Set<String> _estimatingIssueIds = {};
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
    final lastImportedAt = enabledDocs
        .map((doc) => doc.data()['lastImportedAt'])
        .whereType<Timestamp>()
        .fold<Timestamp?>(null, (latest, current) {
          if (latest == null || current.compareTo(latest) > 0) {
            return current;
          }
          return latest;
        });

    if (!mounted) {
      return;
    }

    setState(() {
      _enabledRepoCount = enabledDocs.length;
      _enabledRepoFullNames = {
        for (final doc in enabledDocs) _asString(doc.data()['fullName']),
      }..remove('');
      _lastImportedAt = lastImportedAt;
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

    await _firestore
        .doc('workspaces/$_workspaceId/issues/${movingIssue.id}')
        .update({
          'statusId': targetColumnId,
          'rank': _rankBetween(previousRank, nextRank),
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

    final doneColumn = _columns.firstWhere(
      (column) => column.id == _closedStatusId,
    );

    setState(() => _closingIssueIds.add(issueId));
    try {
      await _moveIssue(
        issueId: issueId,
        targetColumnId: _closedStatusId,
        targetIndex: doneColumn.issues.length,
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
    final draft = await showDialog<NewIssueDraft>(
      context: context,
      builder: (context) => AddIssueDialog(
        columns: _columns,
        repositoryOptions: _enabledRepositoryOptions,
        initialColumnId: initialColumnId,
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

    final result = await showDialog<Object?>(
      context: context,
      builder: (context) => AddIssueDialog(
        columns: _columns,
        repositoryOptions: _enabledRepositoryOptions,
        initialIssue: issue,
        initialColumnId: sourceColumn.id,
        isEstimatingWeight: _estimatingIssueIds.contains(issueId),
        onEstimateIssueWeight: _estimateIssueWeight,
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

  Future<void> _addIssue(NewIssueDraft draft) async {
    final targetColumn = _columns.firstWhere(
      (column) => column.id == draft.columnId,
    );
    final rank = targetColumn.issues.isEmpty
        ? DateTime.now().millisecondsSinceEpoch.toDouble()
        : targetColumn.issues.first.rank - 1000;

    await _callFunction(
      'createGitHubIssue',
      _issueDraftToFunctionData(draft, rank: rank),
    );
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

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyT, meta: true): () =>
            unawaited(_openAddIssueDialog()),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SafeArea(
            child: Column(
              children: [
                BoardHeader(
                  openIssues: openIssues,
                  userEmail: FirebaseAuth.instance.currentUser?.email,
                  onSignOut: FirebaseAuth.instance.signOut,
                ),
                if (_isBootstrapping) const LinearProgressIndicator(),
                BoardToolbar(
                  onAddIssue: () => unawaited(_openAddIssueDialog()),
                  onConnectGitHub: _connectGitHub,
                  onSelectRepositories: _selectRepositories,
                  onImportIssues: _importGitHubIssues,
                  onSyncIssues: _syncGitHubIssues,
                  githubLogin: _githubLogin,
                  repoCount: _enabledRepoCount,
                  lastImportedAt: _lastImportedAt?.toDate(),
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
                                    closingIssueIds: _closingIssueIds,
                                    onIssueDropped: _moveIssue,
                                    onAddIssue: (columnId) => unawaited(
                                      _openAddIssueDialog(
                                        initialColumnId: columnId,
                                      ),
                                    ),
                                    onIssueTapped: _openEditIssueDialog,
                                    onIssueClosed: _closeIssue,
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
      ),
    );
  }
}

class BoardHeader extends StatelessWidget {
  const BoardHeader({
    super.key,
    required this.openIssues,
    required this.userEmail,
    required this.onSignOut,
  });

  final int openIssues;
  final String? userEmail;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
                const SizedBox(height: 6),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IssueCountBadge(openIssues: openIssues),
              const SizedBox(height: 6),
              Text(
                userEmail ?? 'ログイン中',
                style: textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF64748B),
                ),
              ),
              TextButton(
                onPressed: () => unawaited(onSignOut()),
                child: const Text('サインアウト'),
              ),
            ],
          ),
        ],
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
            'open issues',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class BoardToolbar extends StatelessWidget {
  const BoardToolbar({
    super.key,
    required this.onAddIssue,
    required this.onConnectGitHub,
    required this.onSelectRepositories,
    required this.onImportIssues,
    required this.onSyncIssues,
    required this.githubLogin,
    required this.repoCount,
    required this.lastImportedAt,
    required this.isBusy,
  });

  final VoidCallback onAddIssue;
  final VoidCallback onConnectGitHub;
  final VoidCallback onSelectRepositories;
  final VoidCallback onImportIssues;
  final VoidCallback onSyncIssues;
  final String? githubLogin;
  final int repoCount;
  final DateTime? lastImportedAt;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final isConnected = githubLogin != null && githubLogin!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          AddIssueButton(onPressed: onAddIssue),
          FilledButton.icon(
            onPressed: isBusy ? null : onConnectGitHub,
            icon: Icon(
              isConnected
                  ? Icons.check_circle_outline_rounded
                  : Icons.link_rounded,
              size: 16,
            ),
            label: Text(isConnected ? '@$githubLogin' : 'Connect GitHub'),
          ),
          OutlinedButton.icon(
            onPressed: isBusy || !isConnected ? null : onSelectRepositories,
            icon: const Icon(Icons.account_tree_outlined, size: 16),
            label: Text('$repoCount repos'),
          ),
          OutlinedButton.icon(
            onPressed: isBusy || !isConnected ? null : onImportIssues,
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('Import issues'),
          ),
          OutlinedButton.icon(
            onPressed: isBusy || !isConnected ? null : onSyncIssues,
            icon: const Icon(Icons.sync_outlined, size: 16),
            label: const Text('Sync pending'),
          ),
          ToolbarChip(
            icon: Icons.history_rounded,
            label: lastImportedAt == null
                ? 'Not imported'
                : 'Imported ${_formatDate(lastImportedAt!)}',
          ),
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
      icon: const Icon(Icons.add_rounded, size: 16),
      label: const Text('New issue  ⌘T'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(999),
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
  });

  final List<BoardColumn> columns;
  final List<String> repositoryOptions;
  final Issue? initialIssue;
  final String? initialColumnId;
  final bool isEstimatingWeight;
  final Future<void> Function(String issueId)? onEstimateIssueWeight;

  @override
  State<AddIssueDialog> createState() => _AddIssueDialogState();
}

class _AddIssueDialogState extends State<AddIssueDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _assigneeController = TextEditingController(text: 'MF');
  final _labelsController = TextEditingController(text: 'feature, mobile');
  String? _selectedRepo;
  late String _selectedColumnId;
  Priority _priority = Priority.medium;
  DateTime? _dueDate;
  var _isEstimatingWeight = false;

  @override
  void initState() {
    super.initState();
    final issue = widget.initialIssue;

    _selectedColumnId = widget.initialColumnId ?? widget.columns.first.id;
    _selectedRepo = widget.repositoryOptions.isEmpty
        ? null
        : widget.repositoryOptions.first;

    if (issue != null) {
      _titleController.text = issue.title;
      _bodyController.text = issue.body;
      _selectedRepo = widget.repositoryOptions.contains(issue.repo)
          ? issue.repo
          : null;
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
    final canCloseIssue =
        isEditing && widget.initialIssue!.statusId != _closedStatusId;

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
                          repositories: widget.repositoryOptions,
                          selectedRepository: _selectedRepo,
                          onRepositoryChanged: (value) {
                            setState(() => _selectedRepo = value);
                          },
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
                        if (isEditing) ...[
                          const SizedBox(height: 14),
                          IssueWeightPanel(
                            issue: widget.initialIssue!,
                            isEstimating:
                                widget.isEstimatingWeight || _isEstimatingWeight,
                            onEstimate: widget.onEstimateIssueWeight == null
                                ? null
                                : _estimateIssueWeight,
                          ),
                        ],
                        const SizedBox(height: 24),
                        _DialogActions(
                          isEditing: isEditing,
                          canCloseIssue: canCloseIssue,
                          onCancel: () => Navigator.of(context).pop(),
                          onCloseIssue: _closeIssue,
                          onSaveIssue: _saveIssue,
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
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
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
            validator: (value) => value == null || value.trim().isEmpty
                ? '先にrepoを選択してください'
                : null,
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
    required this.closingIssueIds,
    required this.onIssueDropped,
    required this.onAddIssue,
    required this.onIssueTapped,
    required this.onIssueClosed,
  });

  final BoardColumn column;
  final Set<String> closingIssueIds;
  final IssueDropCallback onIssueDropped;
  final ValueChanged<String> onAddIssue;
  final ValueChanged<String> onIssueTapped;
  final ValueChanged<String> onIssueClosed;

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
                    if (column.issues.isEmpty) ...[
                      EmptyColumnIssueCreator(
                        columnTitle: column.title,
                        onPressed: () => onAddIssue(column.id),
                      ),
                      const SizedBox(height: 8),
                    ],
                    for (
                      var index = 0;
                      index < column.issues.length;
                      index++
                    ) ...[
                      IssueCardDropTarget(
                        issue: column.issues[index],
                        sourceColumnId: column.id,
                        index: index,
                        isClosing: closingIssueIds.contains(
                          column.issues[index].id,
                        ),
                        onTap: () => onIssueTapped(column.issues[index].id),
                        onCloseIssue: () =>
                            onIssueClosed(column.issues[index].id),
                        onIssueDropped: onIssueDropped,
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
    required this.isClosing,
    required this.onTap,
    required this.onCloseIssue,
    required this.onIssueDropped,
  });

  final Issue issue;
  final String sourceColumnId;
  final int index;
  final bool isClosing;
  final VoidCallback onTap;
  final VoidCallback onCloseIssue;
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
                isClosing: widget.isClosing,
                onTap: widget.onTap,
                onCloseIssue: widget.onCloseIssue,
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
    required this.isClosing,
    required this.onTap,
    required this.onCloseIssue,
  });

  final Issue issue;
  final String sourceColumnId;
  final bool isClosing;
  final VoidCallback onTap;
  final VoidCallback onCloseIssue;

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
                isClosing: widget.isClosing,
                onCloseIssue: widget.onCloseIssue,
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
    this.isClosing = false,
    this.onCloseIssue,
  });

  final Issue issue;
  final bool isDragging;
  final bool isDragPlaceholder;
  final bool isClosing;
  final VoidCallback? onCloseIssue;

  @override
  Widget build(BuildContext context) {
    final showCloseAction =
        onCloseIssue != null && issue.statusId != _closedStatusId;

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
              if (issue.weightEstimate?.value != null) ...[
                const SizedBox(width: 6),
                WeightBadge(estimate: issue.weightEstimate!),
              ],
              const Spacer(),
              PriorityDot(priority: issue.priority),
              if (showCloseAction) ...[
                const SizedBox(width: 6),
                CloseIssueButton(
                  isClosing: isClosing,
                  onPressed: isClosing ? null : onCloseIssue,
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
                child: Text(
                  issue.displayId,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (issue.dueDate != null) ...[
                const SizedBox(width: 6),
                DueDatePill(dueDate: issue.dueDate!),
              ],
              const Spacer(),
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

class CloseIssueButton extends StatelessWidget {
  const CloseIssueButton({
    super.key,
    required this.isClosing,
    required this.onPressed,
  });

  final bool isClosing;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 26,
      child: IconButton(
        tooltip: isClosing ? 'Closing issue' : 'Close issue',
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
        icon: isClosing
            ? const SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check_circle_outline_rounded, size: 16),
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
  const WeightBadge({super.key, required this.estimate});

  final IssueWeightEstimate estimate;

  @override
  Widget build(BuildContext context) {
    final value = estimate.value;
    return Tooltip(
      message: value == null
          ? 'Weight estimate ${estimate.status}'
          : 'Weight $value / confidence ${(estimate.confidence * 100).round()}%',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          border: Border.all(color: const Color(0xFFC7D2FE)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          value == null ? 'W?' : 'W$value',
          style: const TextStyle(
            color: Color(0xFF4338CA),
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
      child: Row(
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
    String? displayId,
    required this.repo,
    required this.title,
    this.body = '',
    required this.assignee,
    required this.labels,
    required this.comments,
    required this.priority,
    this.dueDate,
    this.statusId = 'triage',
    this.rank = 0,
    this.weightEstimate,
  }) : displayId = displayId ?? id;

  factory Issue.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final githubIssue = _asMap(data['githubIssue']);
    final number = _asInt(githubIssue['number']);
    final repo = _asString(data['repo']);

    return Issue(
      id: doc.id,
      displayId: number > 0 ? '#$number' : doc.id,
      repo: repo,
      title: _asString(data['title'], '#$number'),
      body: _asString(data['body']),
      assignee: _asString(data['assignee'], '-'),
      labels: _asStringList(data['labels']),
      comments: _asInt(data['comments']),
      priority: _priorityFromString(_asString(data['priority'], 'medium')),
      dueDate: _asDate(data['dueDate']),
      statusId: _asString(data['statusId'], 'triage'),
      rank: _asDouble(data['rank']),
      weightEstimate: IssueWeightEstimate.fromMap(
        _asMap(data['weightEstimate']),
      ),
    );
  }

  final String id;
  final String displayId;
  final String repo;
  final String title;
  final String body;
  final String assignee;
  final List<String> labels;
  final int comments;
  final Priority priority;
  final DateTime? dueDate;
  final String statusId;
  final double rank;
  final IssueWeightEstimate? weightEstimate;
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
