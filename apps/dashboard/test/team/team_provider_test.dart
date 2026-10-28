import 'dart:async';

import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/generated/teams/teams.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/team/teams_connector_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _User extends Fake implements User {}

class _Result extends Fake implements QueryResult<GetMyTeamsData, void> {
  _Result(this.data);

  @override
  final GetMyTeamsData data;
}

class _GetMyTeams extends Fake implements GetMyTeamsVariablesBuilder {
  Future<GetMyTeamsData> Function() load = () async =>
      GetMyTeamsData(teams: []);
  var calls = 0;

  @override
  Future<QueryResult<GetMyTeamsData, void>> execute() async {
    calls++;
    return _Result(await load());
  }
}

class _Connector extends Fake implements TeamsConnector {
  final query = _GetMyTeams();

  @override
  GetMyTeamsVariablesBuilder getMyTeams() => query;
}

GetMyTeamsData teamData(String id) => GetMyTeamsData.fromJson({
  'teams': [
    {
      'id': id,
      'name': 'Example team',
      'members': [
        {'userId': 'user-1'},
        {'userId': 'user-2'},
      ],
      'runNumber': '42',
      'createdAt': '1704067200',
      'updatedAt': '1704153600',
    },
  ],
});

void main() {
  late ProviderContainer container;
  late StreamController<User?> authChanges;
  late _Connector connector;

  setUp(() {
    authChanges = StreamController<User?>();
    addTearDown(authChanges.close);
    connector = _Connector();
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        authStateChangesProvider.overrideWith((ref) => authChanges.stream),
        teamsConnectorProvider.overrideWith((ref) => connector),
      ],
    );
    container.listen(teamListProvider, (_, _) {});
  });

  test(
    'converts SDK members and Unix seconds to the existing Team model',
    () async {
      connector.query.load = () async => teamData('team-1');
      authChanges.add(_User());

      final teams = await container.read(teamListProvider.future);

      expect(teams, [
        Team(
          id: 'team-1',
          name: 'Example team',
          members: ['user-1', 'user-2'],
          runNumber: 42,
          createdAt: DateTime.utc(2024),
          updatedAt: DateTime.utc(2024, 1, 2),
        ),
      ]);
      expect(connector.query.calls, 1);
    },
  );

  test('returns an empty list when the user has no teams', () async {
    authChanges.add(_User());

    expect(await container.read(teamListProvider.future), isEmpty);
    expect(connector.query.calls, 1);
  });

  test(
    'propagates SDK errors instead of treating them as an empty list',
    () async {
      final error = StateError('Query failed');
      connector.query.load = () => Future.error(error);
      authChanges.add(_User());

      await expectLater(
        container.read(teamListProvider.future),
        throwsA(same(error)),
      );
    },
  );

  test('clears teams on sign-out and reloads for the next user', () async {
    connector.query.load = () async => teamData('first-user-team');
    authChanges.add(_User());
    expect(
      (await container.read(teamListProvider.future)).single.id,
      'first-user-team',
    );

    authChanges.add(null);
    await container.pump();
    expect(await container.read(teamListProvider.future), isEmpty);
    expect(connector.query.calls, 1);

    connector.query.load = () async => teamData('second-user-team');
    authChanges.add(_User());
    await container.pump();
    expect(
      (await container.read(teamListProvider.future)).single.id,
      'second-user-team',
    );
    expect(connector.query.calls, 2);
  });

  test('ignores a previous connection response after switching', () async {
    final started = Completer<void>();
    final previous = Completer<GetMyTeamsData>();
    connector.query.load = () {
      started.complete();
      return previous.future;
    };
    authChanges.add(_User());
    await started.future;
    expect(connector.query.calls, 1);

    connector = _Connector();
    connector.query.load = () async => teamData('current-connection-team');
    container.invalidate(teamsConnectorProvider);
    expect(
      (await container.read(teamListProvider.future)).single.id,
      'current-connection-team',
    );

    previous.complete(teamData('previous-connection-team'));
    await container.pump();
    expect(
      (await container.read(teamListProvider.future)).single.id,
      'current-connection-team',
    );
  });
}
