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
