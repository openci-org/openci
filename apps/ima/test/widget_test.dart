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
}
