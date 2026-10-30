import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/secret_manager/secret_manager_provider.dart';
import 'package:dashboard/secret_manager/secrets_backend.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic data]) async {
    calls.add(Map<String, dynamic>.from(data as Map));
    return _Result<T>(
      <String, dynamic>{'success': true, 'value': 'value'} as T,
    );
  }
}

class _Manager extends SecretManager {
  @override
  Stream<List<Secret>> build() => Stream.value([]);
}

void main() {
  late ProviderContainer container;
  late _Callable callable;
  late Completer<HttpsCallable> initialized;
  late Team team;
  setUp(() async {
    callable = _Callable();
    initialized = Completer<HttpsCallable>();
    team = Team(
      id: 'team',
      name: 'Team',
      members: ['member'],
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    container = ProviderContainer.test(
      overrides: [
        authStateChangesProvider.overrideWith(
          (ref) => Stream.value(_User('member')),
        ),
        selectedTeamProvider.overrideWith((ref) => team),
        teamSecretsCallableProvider.overrideWith((ref) => initialized.future),
        secretManagerProvider.overrideWith(_Manager.new),
      ],
    );
    container.listen(secretManagerProvider, (_, _) {});
    container.listen(authStateChangesProvider, (_, _) {});
    container.listen(selectedTeamProvider, (_, _) {});
    container.listen(teamSecretsCallableProvider, (_, _) {});
    await container.read(authStateChangesProvider.future);
    await container.read(selectedTeamProvider.future);
  });
  test(
    'saves exact multiline values and sends rename with its value atomically',
    () async {
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
      final request = container
          .read(secretManagerProvider.notifier)
          .addSecret('TOKEN', 'value');
      final failed = expectLater(request, throwsStateError);
      team = team.copyWith(id: 'other-team');
      container.invalidate(selectedTeamProvider);
      await container.read(selectedTeamProvider.future);
      initialized.complete(callable);
      await failed;
      expect(callable.calls, isEmpty);
    },
  );
}
