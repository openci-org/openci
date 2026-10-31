import 'dart:async';

import 'package:dashboard/app_strings.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/settings/email_verification_settings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Auth extends Fake implements FirebaseAuth {
  @override
  User? currentUser;
  final changes = StreamController<User?>.broadcast();

  @override
  Stream<User?> userChanges() async* {
    yield currentUser;
    yield* changes.stream;
  }
}

class _User extends Fake implements User {
  _User(this.auth);
  final _Auth auth;
  @override
  String get uid => 'member';
  @override
  String get email => '$uid@example.test';
  @override
  bool get isAnonymous => false;
  @override
  bool emailVerified = false;
  bool verifiedOnServer = false;
  var sends = 0;
  Future<void> Function() send = () async {};

  @override
  Future<void> sendEmailVerification([ActionCodeSettings? settings]) async {
    sends++;
    await send();
  }

  @override
  Future<void> reload() async {
    emailVerified = verifiedOnServer;
    auth.changes.add(this);
  }
}

Future<ProviderContainer> _pumpSettings(
  WidgetTester tester,
  _Auth Function() auth,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [firebaseAuthProvider.overrideWith((ref) async => auth())],
      child: const MaterialApp(
        home: Scaffold(body: EmailVerificationSettings()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(
    tester.element(find.byType(EmailVerificationSettings)),
  );
}

void main() {
  testWidgets(
    'sends on request and refreshes verification after opening the email link',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final auth = _Auth();
      addTearDown(auth.changes.close);
      final user = _User(auth);
      auth.currentUser = user;
      await _pumpSettings(tester, () => auth);
      expect(user.sends, 0);

      await tester.tap(find.text(t.settings.sendVerificationEmail));
      await tester.pumpAndSettle();
      expect(user.sends, 1);
      expect(find.text(t.settings.verificationEmailSent), findsOneWidget);
      expect(find.text(t.settings.emailVerified), findsNothing);

      await tester.tap(find.text(t.settings.refreshEmailVerification));
      await tester.pumpAndSettle();
      expect(find.text(t.settings.emailStillUnverified), findsOneWidget);
      user.verifiedOnServer = true;
      await tester.tap(find.text(t.settings.refreshEmailVerification));
      await tester.pumpAndSettle();
      expect(find.text(t.settings.emailVerified), findsOneWidget);
      expect(find.text(t.settings.sendVerificationEmail), findsNothing);
      expect(user.sends, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'handles rate limits and allows retry without exposing SDK errors',
    (tester) async {
      final auth = _Auth();
      addTearDown(auth.changes.close);
      final user = _User(auth);
      auth.currentUser = user;
      user.send = () async => throw FirebaseAuthException(
        code: 'too-many-requests',
        message: 'private error',
      );
      await _pumpSettings(tester, () => auth);
      await tester.tap(find.text(t.settings.sendVerificationEmail));
      await tester.pumpAndSettle();
      expect(
        find.text(t.settings.emailVerificationRateLimited),
        findsOneWidget,
      );
      expect(find.textContaining('private error'), findsNothing);
      user.send = () async {};
      await tester.tap(find.text(t.settings.sendVerificationEmail));
      await tester.pumpAndSettle();
      expect(find.text(t.settings.verificationEmailSent), findsOneWidget);
      expect(user.sends, 2);
    },
  );

  testWidgets(
    'ignores old results after a connection change and uses the new Auth instance',
    (tester) async {
      final oldAuth = _Auth();
      final newAuth = _Auth();
      addTearDown(oldAuth.changes.close);
      addTearDown(newAuth.changes.close);
      // Identical UIDs in different Firebase projects still represent different accounts.
      final oldUser = _User(oldAuth);
      final newUser = _User(newAuth);
      oldAuth.currentUser = oldUser;
      newAuth.currentUser = newUser;
      final pending = Completer<void>();
      oldUser.send = () => pending.future;
      var activeAuth = oldAuth;
      final container = await _pumpSettings(tester, () => activeAuth);
      await tester.tap(find.text(t.settings.sendVerificationEmail));
      await tester.pumpAndSettle();
      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNull,
      );

      activeAuth = newAuth;
      container.invalidate(firebaseAuthProvider);
      await tester.pumpAndSettle();
      expect(await container.read(firebaseAuthProvider.future), same(newAuth));
      pending.complete();
      await tester.pumpAndSettle();
      expect(find.text(t.settings.verificationEmailSent), findsNothing);
      await tester.tap(find.text(t.settings.sendVerificationEmail));
      await tester.pumpAndSettle();
      expect(oldUser.sends, 1);
      expect(newUser.sends, 1);
      expect(find.text(t.settings.verificationEmailSent), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
