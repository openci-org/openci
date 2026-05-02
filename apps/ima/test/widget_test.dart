import 'package:flutter/material.dart';
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

  testWidgets('Issue card exposes close action for open issues', (
    tester,
  ) async {
    var closeTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IssueCard(
            issue: const Issue(
              id: 'IMA-1',
              repo: 'openci/ima',
              title: 'Close issue from the board',
              assignee: 'MF',
              labels: ['feature'],
              comments: 0,
              priority: Priority.medium,
            ),
            onCloseIssue: () => closeTapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Close issue'));

    expect(closeTapped, isTrue);
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
            closingIssueIds: const <String>{},
            onIssueDropped:
                ({
                  required issueId,
                  required targetColumnId,
                  required targetIndex,
                }) {},
            onAddIssue: (columnId) => targetColumnId = columnId,
            onIssueTapped: (_) {},
            onIssueClosed: (_) {},
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
            closingIssueIds: const <String>{},
            onIssueDropped:
                ({
                  required issueId,
                  required targetColumnId,
                  required targetIndex,
                }) {},
            onAddIssue: (columnId) => targetColumnId = columnId,
            onIssueTapped: (_) {},
            onIssueClosed: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('まだチケットがありません'), findsOneWidget);

    await tester.tap(find.text('+ チケット作成'));

    expect(targetColumnId, 'review');
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

  testWidgets('Issue card hides close action for closed issues', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IssueCard(
            issue: const Issue(
              id: 'IMA-2',
              repo: 'openci/ima',
              title: 'Already closed',
              assignee: 'MF',
              labels: ['done'],
              comments: 0,
              priority: Priority.low,
              statusId: 'done',
            ),
            onCloseIssue: () {},
          ),
        ),
      ),
    );

    expect(find.byTooltip('Close issue'), findsNothing);
  });
}
