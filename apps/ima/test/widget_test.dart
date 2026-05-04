import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ima/main.dart';

void main() {
  testWidgets('Email auth page renders login form', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: EmailAuthPage()));

    expect(find.text('IssuePilot'), findsOneWidget);
    expect(find.text('メールアドレス'), findsOneWidget);
    expect(find.text('パスワード'), findsOneWidget);
    expect(find.text('ログイン'), findsOneWidget);
  });

  testWidgets('Email auth page toggles to account creation', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: EmailAuthPage()));

    await tester.tap(find.text('新しいアカウントを作成'));
    await tester.pump();

    expect(find.text('登録する'), findsOneWidget);
    expect(find.text('既存アカウントでログイン'), findsOneWidget);
  });

  testWidgets('Issue card does not show close button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: IssueCard(
            issue: Issue(
              id: 'IMA-1',
              repo: 'openci/ima',
              title: 'Close issue from the board',
              assignee: 'MF',
              labels: ['feature'],
              comments: 0,
              priority: Priority.medium,
            ),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Close issue'), findsNothing);
  });

  testWidgets('Issue card renders LLM weight badge', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: IssueCard(
            issue: Issue(
              id: 'IMA-4',
              repo: 'openci/ima',
              title: 'Show estimated weight',
              assignee: 'MF',
              labels: ['ai'],
              comments: 0,
              priority: Priority.medium,
              weightEstimate: IssueWeightEstimate(
                status: 'done',
                value: 3,
                confidence: 0.8,
                reason: 'UIの小変更',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('W3'), findsOneWidget);
  });

  testWidgets('Done issue card renders actual weight badge only', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: IssueCard(
            issue: Issue(
              id: 'IMA-7',
              repo: 'openci/ima',
              title: 'Show actual weight after closing',
              assignee: 'MF',
              labels: ['done'],
              comments: 0,
              priority: Priority.medium,
              statusId: 'done',
              weightEstimate: IssueWeightEstimate(
                status: 'done',
                value: 3,
                confidence: 0.8,
              ),
              resolution: IssueResolution(actualWeight: 5, weightDelta: -2),
            ),
          ),
        ),
      ),
    );

    expect(find.text('W5'), findsOneWidget);
    expect(find.text('W3'), findsNothing);
  });

  testWidgets('Issue card exposes GitHub link open action', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: IssueCard(
            issue: Issue(
              id: 'IMA-5',
              repo: 'openci/ima',
              title: 'Open GitHub link from card',
              githubUrl: 'https://github.com/openci/ima/issues/5',
              assignee: 'MF',
              labels: ['github'],
              comments: 0,
              priority: Priority.medium,
            ),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Open in GitHub'), findsOneWidget);
  });

  testWidgets('Issue card renders Ima issue key and linked PR badge', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: IssueCard(
            issue: Issue(
              id: 'gh_openci_ima_57',
              issueKey: 'IMA-1423',
              repo: 'openci/ima',
              title: 'Link pull request from branch',
              assignee: 'MF',
              labels: ['github'],
              comments: 0,
              priority: Priority.medium,
              pullRequests: [
                IssuePullRequest(
                  number: 12,
                  title: 'Implement PR linking',
                  url: 'https://github.com/openci/ima/pull/12',
                  state: 'open',
                  merged: false,
                  branch: 'feature/ima-1423-link-pr',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('IMA-1423'), findsOneWidget);
    expect(find.byTooltip('Copy issue ID'), findsOneWidget);
    expect(find.text('PR #12'), findsOneWidget);
  });

  testWidgets('Issue board shortcuts trigger search with Cmd+K', (
    tester,
  ) async {
    var searchCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: IssueBoardShortcuts(
          onAddIssue: () {},
          onSearchIssues: () => searchCount++,
          child: const SizedBox.expand(),
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);

    expect(searchCount, 1);
  });

  testWidgets('Issue search dialog filters issues and returns selection', (
    tester,
  ) async {
    String? selectedIssueId;
    final columns = [
      BoardColumn(
        id: 'triage',
        title: 'Triage',
        description: '新着と要件確認',
        color: Colors.indigo,
        issues: const [
          Issue(
            id: 'IMA-10',
            repo: 'openci/ima',
            title: 'Add command palette search',
            assignee: 'MF',
            labels: ['mobile', 'feature'],
            comments: 0,
            priority: Priority.medium,
          ),
          Issue(
            id: 'IMA-11',
            repo: 'openci/dashboard',
            title: 'Export billing report',
            assignee: 'MF',
            labels: ['finance'],
            comments: 0,
            priority: Priority.low,
          ),
        ],
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                selectedIssueId = await showDialog<String>(
                  context: context,
                  builder: (context) => IssueSearchDialog(columns: columns),
                );
              },
              child: const Text('Open search'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open search'));
    await tester.pumpAndSettle();

    expect(find.text('Add command palette search'), findsOneWidget);
    expect(find.text('Export billing report'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'palette');
    await tester.pumpAndSettle();

    expect(find.text('Add command palette search'), findsOneWidget);
    expect(find.text('Export billing report'), findsNothing);

    await tester.tap(find.text('Add command palette search'));
    await tester.pumpAndSettle();

    expect(selectedIssueId, 'IMA-10');
  });

  testWidgets('Board column header creates issue in that column', (
    tester,
  ) async {
    String? targetColumnId;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BoardColumnView(
            column: BoardColumn(
              id: 'backlog',
              title: 'Backlog',
              description: '着手待ち',
              color: Colors.blue,
              issues: const [],
            ),
            onIssueDropped:
                ({
                  required issueId,
                  required targetColumnId,
                  required targetIndex,
                }) {},
            onAddIssue: (columnId) => targetColumnId = columnId,
            onIssueTapped: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('New issue in Backlog'));

    expect(targetColumnId, 'backlog');
  });

  testWidgets('Empty board column shows ticket creator', (tester) async {
    String? targetColumnId;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BoardColumnView(
            column: BoardColumn(
              id: 'review',
              title: 'Review',
              description: 'レビューと検証',
              color: Colors.purple,
              issues: const [],
            ),
            onIssueDropped:
                ({
                  required issueId,
                  required targetColumnId,
                  required targetIndex,
                }) {},
            onAddIssue: (columnId) => targetColumnId = columnId,
            onIssueTapped: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('まだチケットがありません'), findsOneWidget);

    await tester.tap(find.text('+ チケット作成'));

    expect(targetColumnId, 'review');
  });

  testWidgets('Done board column shows latest closed issue first', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BoardColumnView(
            column: BoardColumn(
              id: 'done',
              title: 'Done',
              description: '今週完了',
              color: Colors.green,
              issues: [
                Issue(
                  id: 'old',
                  repo: 'openci/ima',
                  title: 'Old closed issue',
                  assignee: 'MF',
                  labels: const ['done'],
                  comments: 0,
                  priority: Priority.low,
                  statusId: 'done',
                  rank: 1000,
                  closedAt: DateTime(2026, 5, 1),
                ),
                Issue(
                  id: 'new',
                  repo: 'openci/ima',
                  title: 'New closed issue',
                  assignee: 'MF',
                  labels: const ['done'],
                  comments: 0,
                  priority: Priority.low,
                  statusId: 'done',
                  rank: 2000,
                  closedAt: DateTime(2026, 5, 2),
                ),
              ],
            ),
            onIssueDropped:
                ({
                  required issueId,
                  required targetColumnId,
                  required targetIndex,
                }) {},
            onAddIssue: (_) {},
            onIssueTapped: (_) {},
          ),
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.text('New closed issue')).dy,
      lessThan(tester.getTopLeft(find.text('Old closed issue')).dy),
    );
  });

  testWidgets('Edit issue dialog can return close action', (tester) async {
    Object? dialogResult;
    final columns = [
      BoardColumn(
        id: 'triage',
        title: 'Triage',
        description: '新着と要件確認',
        color: Colors.indigo,
        issues: const [],
      ),
      BoardColumn(
        id: 'done',
        title: 'Done',
        description: '今週完了',
        color: Colors.green,
        issues: const [],
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                dialogResult = await showDialog<Object?>(
                  context: context,
                  builder: (context) => AddIssueDialog(
                    columns: columns,
                    repositoryOptions: const ['openci/ima'],
                    initialIssue: const Issue(
                      id: 'IMA-3',
                      repo: 'openci/ima',
                      title: 'Close from edit dialog',
                      assignee: 'MF',
                      labels: ['feature'],
                      comments: 0,
                      priority: Priority.medium,
                      statusId: 'triage',
                    ),
                    initialColumnId: 'triage',
                  ),
                );
              },
              child: const Text('Open edit dialog'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open edit dialog'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Close issue'));
    await tester.tap(find.text('Close issue'));
    await tester.pumpAndSettle();

    expect(dialogResult, isA<CloseIssueDialogResult>());
  });

  testWidgets('Edit issue dialog exposes GitHub link controls', (tester) async {
    const githubUrl = 'https://github.com/openci/ima/issues/6';
    final columns = [
      BoardColumn(
        id: 'triage',
        title: 'Triage',
        description: '新着と要件確認',
        color: Colors.indigo,
        issues: const [],
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                showDialog<Object?>(
                  context: context,
                  builder: (context) => AddIssueDialog(
                    columns: columns,
                    repositoryOptions: const ['openci/ima'],
                    initialIssue: const Issue(
                      id: 'IMA-6',
                      repo: 'openci/ima',
                      title: 'Expose GitHub link controls',
                      githubUrl: githubUrl,
                      assignee: 'MF',
                      labels: ['github'],
                      comments: 0,
                      priority: Priority.medium,
                      statusId: 'triage',
                    ),
                    initialColumnId: 'triage',
                  ),
                );
              },
              child: const Text('Open edit dialog'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open edit dialog'));
    await tester.pumpAndSettle();

    expect(find.text('GitHub link'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextFormField && widget.controller?.text == githubUrl,
      ),
      findsOneWidget,
    );
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Paste'), findsOneWidget);
  });

  testWidgets('Issue card does not show close button for closed issues', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: IssueCard(
            issue: Issue(
              id: 'IMA-2',
              repo: 'openci/ima',
              title: 'Already closed',
              assignee: 'MF',
              labels: ['done'],
              comments: 0,
              priority: Priority.low,
              statusId: 'done',
            ),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Close issue'), findsNothing);
  });
}
