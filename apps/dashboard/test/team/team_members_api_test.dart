import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/app_strings.dart';
import 'package:dashboard/generated/teams/teams.dart';
import 'package:dashboard/team/team_members_api.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter_test/flutter_test.dart';

class _Callable extends Fake implements HttpsCallable {
  final calls = <dynamic>[];
  Future<Map<String, dynamic>> Function() respond = () async => {
    'success': true,
  };
  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async {
    calls.add(parameters);
    return _Result<T>((await respond()) as T);
  }
}

class _Result<T> extends Fake implements HttpsCallableResult<T> {
  _Result(this.data);
  @override
  final T data;
}

class _Connector extends Fake implements TeamsConnector {
  final removals = <RemoveTeamMemberVariables>[];
  @override
  RemoveTeamMemberVariablesBuilder removeTeamMember({
    required String teamId,
    required String userId,
  }) => _Remove(
    () =>
        removals.add(RemoveTeamMemberVariables(teamId: teamId, userId: userId)),
  );
}

class _Remove extends Fake implements RemoveTeamMemberVariablesBuilder {
  _Remove(this.commit);
  final void Function() commit;
  @override
  Future<OperationResult<RemoveTeamMemberData, RemoveTeamMemberVariables>>
  execute() async {
    commit();
    return _MutationResult();
  }
}

class _MutationResult extends Fake
    implements
        OperationResult<RemoveTeamMemberData, RemoveTeamMemberVariables> {}

void main() {
  late _Callable callable;
  late _Connector connector;
  late TeamMembersApi api;
  var current = true;
  setUp(() {
    current = true;
    callable = _Callable();
    connector = _Connector();
    api = TeamMembersApi(
      callable: callable,
      connector: connector,
      isCurrent: () => current,
    );
  });

  test(
    'adds by email through the callable and removes by UID through FSC',
    () async {
      await api.add('team', ' member@example.test ');
      expect(callable.calls, [
        {'action': 'add', 'teamId': 'team', 'email': 'member@example.test'},
      ]);
      await api.remove('team', 'member');
      expect(connector.removals, [
        RemoveTeamMemberVariables(teamId: 'team', userId: 'member'),
      ]);
    },
  );

  test(
    'rejects stale actions and ignores an in-flight result after a connection change',
    () async {
      current = false;
      await expectLater(
        api.add('team', 'member@example.test'),
        throwsStateError,
      );
      await expectLater(api.remove('team', 'member'), throwsStateError);
      expect(callable.calls, isEmpty);
      expect(connector.removals, isEmpty);
      current = true;
      final pending = Completer<Map<String, dynamic>>();
      callable.respond = () => pending.future;
      final result = api.members('team');
      current = false;
      pending.complete({
        'success': true,
        'members': [
          {'uid': 'old-private-member'},
        ],
      });
      await expectLater(result, throwsStateError);
    },
  );

  test('maps account errors without displaying SDK details', () async {
    callable.respond = () => throw FirebaseFunctionsException(
      code: 'not-found',
      message: 'private email',
    );
    await expectLater(
      api.add('team', 'member@example.test'),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          t.team.memberNotRegistered,
        ),
      ),
    );
  });

  test(
    'rejects malformed member data instead of reporting no members',
    () async {
      callable.respond = () async => {'success': true};
      await expectLater(api.members('team'), throwsStateError);
    },
  );
}
