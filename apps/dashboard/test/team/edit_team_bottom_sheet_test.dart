import 'package:dashboard/app_strings.dart';
import 'package:dashboard/generated/teams/teams.dart';
import 'package:dashboard/team/edit_team_bottom_sheet.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/team/teams_connector_provider.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'renames the selected team through the SDK and refreshes the team list',
    (tester) async {
      final setup = await _pumpEditor(tester);
      final nameField = find.byType(TextFormField);
      expect(
        tester.widget<TextFormField>(nameField).controller!.text,
        'Original team',
      );
      await tester.enterText(nameField, 'Renamed team');
      await tester.tap(find.widgetWithText(TextButton, t.team.editTeam));
      await tester.pumpAndSettle();

      expect(setup.connector.requests, [
        RenameTeamVariables(teamId: 'team-123', name: 'Renamed team'),
      ]);
      final teams = await setup.container.read(teamListProvider.future);
      expect(
        teams.map((team) => team.name),
        ['Other team', 'Renamed team'],
      );
      expect(find.text(t.team.updatedSuccess), findsOneWidget);
      expect(find.byType(EditTeamBottomSheet), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('keeps the editor open when the SDK rejects the rename', (
    tester,
  ) async {
    final setup = await _pumpEditor(
      tester,
      error: StateError('Team access denied'),
    );
    final nameField = find.byType(TextFormField);
    final saveButton = find.widgetWithText(TextButton, t.team.editTeam);
    await tester.enterText(nameField, 'Renamed team');
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(setup.connector.requests, [
      RenameTeamVariables(teamId: 'team-123', name: 'Renamed team'),
    ]);
    final teams = await setup.container.read(teamListProvider.future);
    expect(teams.map((team) => team.name), ['Other team', 'Original team']);
    expect(find.textContaining('Team access denied'), findsOneWidget);
    expect(find.byType(EditTeamBottomSheet), findsOneWidget);
    expect(
      tester.widget<TextFormField>(nameField).controller!.text,
      'Renamed team',
    );
    expect(tester.widget<TextButton>(saveButton).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });
}

Future<({ProviderContainer container, _Connector connector})> _pumpEditor(
  WidgetTester tester, {
  Object? error,
}) async {
  final team = Team(
    id: 'team-123',
    name: 'Original team',
    members: const ['user-123'],
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
  final connector = _Connector(error);
  final container = ProviderContainer.test(
    overrides: [
      teamListProvider.overrideWith(
        (ref) async => [
          team.copyWith(id: 'other-team', name: 'Other team'),
          team.copyWith(name: connector.teamName),
        ],
      ),
      teamsConnectorProvider.overrideWith((ref) async => connector),
    ],
  );
  container.listen(teamListProvider, (_, _) {});
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                await showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => const EditTeamBottomSheet(),
                );
              },
              child: const Text('Open team editor'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open team editor'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(team.name));
  await tester.pumpAndSettle();
  return (container: container, connector: connector);
}

class _Connector extends Fake implements TeamsConnector {
  _Connector(this.error);

  final Object? error;
  final requests = <RenameTeamVariables>[];
  String teamName = 'Original team';

  @override
  RenameTeamVariablesBuilder renameTeam({
    required String teamId,
    required String name,
  }) => _RenameTeam(() async {
    requests.add(RenameTeamVariables(teamId: teamId, name: name));
    if (error != null) throw error!;
    teamName = name;
  });
}

class _RenameTeam extends Fake implements RenameTeamVariablesBuilder {
  _RenameTeam(this.rename);

  final Future<void> Function() rename;

  @override
  Future<OperationResult<RenameTeamData, RenameTeamVariables>> execute() async {
    await rename();
    return _RenameTeamResult();
  }
}

class _RenameTeamResult extends Fake
    implements OperationResult<RenameTeamData, RenameTeamVariables> {}
