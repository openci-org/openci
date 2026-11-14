import 'dart:async';

import 'package:dashboard/app_strings.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/generated/teams/teams.dart';
import 'package:dashboard/team/selected_team_provider.dart';
import 'package:dashboard/team/switch_team_bottom_sheet.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/team/teams_connector_provider.dart';
import 'package:dashboard/utilities/shared_preferences_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late _TeamsConnector connector;
  late ProviderContainer container;
  late SharedPreferences prefs;
  final field = find.byType(TextFormField);
  final create = find.widgetWithText(FilledButton, t.team.createTeam);

  Future<void> pumpDashboard(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'selected_team_id:cloud': 'user-1',
    });
    prefs = await SharedPreferences.getInstance();
    connector = _TeamsConnector();
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        authStateChangesProvider.overrideWith((_) => Stream.value(_User())),
        sharedPreferencesProvider.overrideWithValue(prefs),
        teamsConnectorProvider.overrideWith((_) => connector),
      ],
    );
    container.listen(selectedTeamProvider, (_, _) {});
    await container.read(selectedTeamProvider.future);
    await tester.pumpWidget(
      TranslationProvider(
        child: UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showTeamFlowModal(context),
                  child: Text(t.team.selectTeamLabel),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openForm(WidgetTester tester) async {
    await tester.tap(find.text(t.team.selectTeamLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, t.team.createTeam));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'creates additional teams from the switcher and selects each one',
    (tester) async {
      await pumpDashboard(tester);
      for (final name in ['Release team', 'Mobile team']) {
        await openForm(tester);
        await tester.enterText(field, '  $name  ');
        await tester.tap(create);
        await tester.pumpAndSettle();

        final request = connector.requests.last;
        expect(request.name, name);
        expect(prefs.getString('selected_team_id:cloud'), request.id);
        expect((await container.read(selectedTeamProvider.future)).name, name);
        expect(find.text(t.team.createdSuccess), findsOneWidget);
        expect(field, findsNothing);
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
      }
      final teams = await container.read(teamListProvider.future);
      expect(teams.map((team) => team.name), [
        'First team',
        'Release team',
        'Mobile team',
      ]);
      expect(teams.map((team) => team.id).toSet(), hasLength(3));
    },
  );

  testWidgets('keeps the form and selection on failure and allows a retry', (
    tester,
  ) async {
    await pumpDashboard(tester);
    await openForm(tester);
    await tester.enterText(field, '   ');
    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(find.text(t.team.enterTeamName), findsOneWidget);
    expect(connector.requests, isEmpty);

    final pending = Completer<void>();
    connector.beforeInsert = () => pending.future;
    await tester.enterText(field, 'Release team');
    final submit = tester.widget<FilledButton>(create).onPressed!;
    submit();
    submit();
    await tester.pump();
    expect(connector.requests, hasLength(1));
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    pending.completeError(StateError('Creation failed'));
    await tester.pumpAndSettle();

    expect(find.text(t.team.operationFailed), findsOneWidget);
    expect(
      tester.widget<TextFormField>(field).controller!.text,
      'Release team',
    );
    expect(await container.read(selectedTeamIdProvider.future), 'user-1');
    expect(prefs.getString('selected_team_id:cloud'), 'user-1');

    connector.beforeInsert = null;
    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(connector.requests, hasLength(2));
    expect(connector.requests.last, connector.requests.first);
    expect(
      (await container.read(selectedTeamProvider.future)).name,
      'Release team',
    );
  });

  testWidgets('recovers a committed team when the create response is lost', (
    tester,
  ) async {
    await pumpDashboard(tester);
    connector.loseResponse = true;
    await openForm(tester);
    await tester.enterText(field, 'Release team');
    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(find.text(t.team.operationFailed), findsOneWidget);
    expect(prefs.getString('selected_team_id:cloud'), 'user-1');

    await tester.enterText(field, 'Release engineering');
    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(connector.requests, hasLength(1));
    expect(
      await container.read(selectedTeamIdProvider.future),
      connector.requests.single.id,
    );
    expect((await container.read(teamListProvider.future)).length, 2);
    expect(
      (await container.read(selectedTeamProvider.future)).name,
      'Release engineering',
    );
    expect(field, findsNothing);
  });
}

class _User extends Fake implements User {
  @override
  String get uid => 'user-1';
}

class _TeamsConnector extends Fake implements TeamsConnector {
  final teams = {'user-1': 'First team'};
  final requests = <CreateTeamVariables>[];
  Future<void> Function()? beforeInsert;
  bool loseResponse = false;

  @override
  CreateTeamVariablesBuilder createTeam({
    required String id,
    required String name,
  }) => _CreateTeam(() async {
    requests.add(CreateTeamVariables(id: id, name: name));
    await beforeInsert?.call();
    teams[id] = name;
    if (loseResponse) throw StateError('Response lost');
  });

  @override
  GetMyTeamsVariablesBuilder getMyTeams() => _GetMyTeams(teams);

  @override
  RenameTeamVariablesBuilder renameTeam({
    required String teamId,
    required String name,
  }) => _RenameTeam(() => teams[teamId] = name);
}

class _CreateTeam extends Fake implements CreateTeamVariablesBuilder {
  _CreateTeam(this.create);
  final Future<void> Function() create;

  @override
  Future<OperationResult<CreateTeamData, CreateTeamVariables>> execute() async {
    await create();
    return _CreateResult();
  }
}

class _CreateResult extends Fake
    implements OperationResult<CreateTeamData, CreateTeamVariables> {}

class _RenameTeam extends Fake implements RenameTeamVariablesBuilder {
  _RenameTeam(this.rename);
  final void Function() rename;

  @override
  Future<OperationResult<RenameTeamData, RenameTeamVariables>> execute() async {
    rename();
    return _RenameResult();
  }
}

class _RenameResult extends Fake
    implements OperationResult<RenameTeamData, RenameTeamVariables> {}

class _GetMyTeams extends Fake implements GetMyTeamsVariablesBuilder {
  _GetMyTeams(this.teams);
  final Map<String, String> teams;

  @override
  Future<QueryResult<GetMyTeamsData, void>> execute() async => _QueryResult(
    GetMyTeamsData(
      teams: [
        for (final entry in teams.entries)
          GetMyTeamsTeams(
            id: entry.key,
            name: entry.value,
            members: [GetMyTeamsTeamsMembers(userId: 'user-1')],
            runNumber: BigInt.zero,
            createdAt: BigInt.one,
            updatedAt: BigInt.one,
          ),
      ],
    ),
  );
}

class _QueryResult extends Fake implements QueryResult<GetMyTeamsData, void> {
  _QueryResult(this.data);
  @override
  final GetMyTeamsData data;
}
