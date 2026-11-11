import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/app_strings.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/secret_manager/secret_manager_page.dart';
import 'package:dashboard/secret_manager/secret_manager_provider.dart';
import 'package:dashboard/secret_manager/secrets_backend.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/utilities/error_message.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _User extends Fake implements User {
  _User(this.uid);
  @override
  final String uid;
}

class _Result<T> implements HttpsCallableResult<T> {
  _Result(this.data);
  @override
  final T data;
}

class _Callable extends Fake implements HttpsCallable {
  final calls = <Map<String, dynamic>>[];
  Future<void>? responseDelay;

  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic data]) async {
    calls.add(Map<String, dynamic>.from(data as Map));
    if (responseDelay case final delay?) await delay;
    return _Result<T>(
      <String, dynamic>{'success': true, 'value': 'value'} as T,
    );
  }
}

class _Manager extends SecretManager {
  @override
  Stream<List<Secret>> build() {
    ref.watch(authStateChangesProvider);
    ref.watch(selectedTeamProvider);
    return Stream.value([]);
  }
}

void main() {
  late _Callable callable;
  late Completer<HttpsCallable> initialized;
  late Team team;
  final overrides = [
    authStateChangesProvider.overrideWith(
      (ref) => Stream.value(_User('member')),
    ),
    selectedTeamProvider.overrideWith((ref) => team),
    teamSecretsCallableProvider.overrideWith((ref) => initialized.future),
    secretManagerProvider.overrideWith(_Manager.new),
  ];
  final contextChanged = throwsA(
    isA<DashboardException>().having(
      (error) => error.code,
      'code',
      'secrets_context_changed',
    ),
  );
  setUp(() {
    callable = _Callable();
    team = Team(
      id: 'team',
      name: 'Team',
      members: ['member'],
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
  });

  Future<ProviderContainer> makeContainer() async {
    initialized = Completer<HttpsCallable>();
    final container = ProviderContainer.test(overrides: overrides);
    container.listen(secretManagerProvider, (_, _) {});
    await container.read(authStateChangesProvider.future);
    await container.read(selectedTeamProvider.future);
    return container;
  }

  testWidgets('Add Secret sends one save after callable initialization', (
    tester,
  ) async {
    initialized = Completer<HttpsCallable>();
    final strings = AppLocale.ja.translations;
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: TranslationProvider(
          child: MaterialApp(
            locale: AppLocale.ja.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const SecretManagerPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'TOKEN');
    await tester.enterText(find.byType(TextFormField).last, 'value');
    final submit = find.widgetWithText(FilledButton, strings.secrets.addSecret);
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    initialized.complete(callable);
    await tester.pumpAndSettle();

    expect(callable.calls, [
      {'action': 'save', 'teamId': 'team', 'name': 'TOKEN', 'value': 'value'},
    ]);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text(strings.secrets.addedSuccess), findsOneWidget);
  });
  test(
    'saves exact multiline values and sends rename with its value atomically',
    () async {
      final container = await makeContainer();
      initialized.complete(callable);
      final manager = container.read(secretManagerProvider.notifier);
      await manager.addSecret('TOKEN', '  secret\r\n');
      await container.pump();
      await container
          .read(secretManagerProvider.notifier)
          .updateSecret(documentId: 'TOKEN', name: 'RENAMED', value: ' new\n');
      expect(callable.calls, [
        {
          'action': 'save',
          'teamId': 'team',
          'name': 'TOKEN',
          'value': '  secret\r\n',
        },
        {
          'action': 'rename',
          'teamId': 'team',
          'name': 'TOKEN',
          'newName': 'RENAMED',
          'value': ' new\n',
        },
      ]);
    },
  );
  test(
    'team change during initialization prevents sending a stale secret',
    () async {
      final container = await makeContainer();
      final request = container
          .read(secretManagerProvider.notifier)
          .addSecret('TOKEN', 'value');
      final failed = expectLater(request, contextChanged);
      team = team.copyWith(id: 'other-team');
      container.invalidate(selectedTeamProvider);
      await container.read(selectedTeamProvider.future);
      initialized.complete(callable);
      await failed;
      expect(callable.calls, isEmpty);
    },
  );

  test('discards a read response when the connection changes', () async {
    final container = await makeContainer();
    final reply = Completer<void>();
    callable.responseDelay = reply.future;
    initialized.complete(callable);
    final manager = container.read(secretManagerProvider.notifier);
    final pending = manager.readSecret(documentId: 'TOKEN');
    await container.pump();
    expect(callable.calls.single['action'], 'read');

    final nextCallable = _Callable();
    initialized = Completer<HttpsCallable>()..complete(nextCallable);
    container.invalidate(teamSecretsCallableProvider);
    await container.read(teamSecretsCallableProvider.future);
    final rejected = expectLater(pending, contextChanged);
    reply.complete();
    await rejected;

    await manager.readSecret(documentId: 'TOKEN');
    expect(nextCallable.calls.single['action'], 'read');
  });
}
