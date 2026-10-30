import 'dart:async';
import 'dart:convert';

import 'package:dashboard/app_strings.dart';
import 'package:dashboard/auth/auth_page.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/connections/connection_profile.dart';
import 'package:dashboard/connections/connection_snapshot.dart';
import 'package:dashboard/connections/connection_store.dart';
import 'package:dashboard/connections/connection_store_provider.dart';
import 'package:dashboard/connections/local_development_connection.dart';
import 'package:dashboard/generated/teams/teams.dart';
import 'package:dashboard/team/selected_team_provider.dart';
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
  for (final localMode in [false, true]) {
    testWidgets('shows the active connection indicator: local=$localMode', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final saved = jsonEncode({
        'apiKey': 'saved-key',
        'appId': '1:123:web:saved',
        'projectId': 'saved-production-project',
      });
      SharedPreferences.setMockInitialValues({'sh_firebase_config': saved});
      final prefs = await SharedPreferences.getInstance();
      const cloud = ConnectionProfile(
        id: 'cloud',
        name: 'Cloud',
        apiUrl: 'https://cloud.example.com',
        firebase: {},
      );
      const company = ConnectionProfile(
        id: 'company',
        name: 'Company',
        apiUrl: 'https://company.example.com',
        firebase: {},
      );
      final store = ConnectionStore(prefs, cloud);
      await store.save(
        const ConnectionSnapshot(
          profiles: [cloud, company],
          activeId: 'company',
        ),
      );
      final local = LocalDevelopmentConnection.parse(
        mode: 'true',
        apiUrl: 'http://127.0.0.1:8080',
        emulatorHost: '127.0.0.1',
        emulatorPort: '9099',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            connectionStoreProvider.overrideWithValue(store),
            localDevelopmentConnectionProvider.overrideWithValue(
              localMode ? local : null,
            ),
          ],
          child: const MaterialApp(home: AuthPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Local Auth Emulator · demo-openci'),
        localMode ? findsOneWidget : findsNothing,
      );
      expect(
        find.text('Company'),
        localMode ? findsNothing : findsOneWidget,
      );
      expect(prefs.getString('sh_firebase_config'), saved);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('creates and selects the signup team through the SDK', (
    tester,
  ) async {
    final setup = await _pumpSignup(tester);
    final button = find.widgetWithText(OutlinedButton, t.auth.createAccount);

    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(setup.connector.requests, [
      CreateTeamVariables(id: 'new-user', name: 'new-user'),
    ]);
    expect(setup.prefs.getString('selected_team_id:cloud'), 'new-user');
    expect(setup.container.read(selectedTeamIdProvider).value, 'new-user');
    expect(
      (await setup.container.read(teamListProvider.future)).single.id,
      'new-user',
    );
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.widget<OutlinedButton>(button).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the selected team when the SDK rejects creation', (
    tester,
  ) async {
    final setup = await _pumpSignup(
      tester,
      error: StateError('Team creation failed'),
    );
    final button = find.widgetWithText(OutlinedButton, t.auth.createAccount);

    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(setup.connector.requests, hasLength(1));
    expect(setup.prefs.getString('selected_team_id:cloud'), 'previous-team');
    expect(find.textContaining('Team creation failed'), findsOneWidget);
    expect(tester.widget<OutlinedButton>(button).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('finishes team creation after the auth page is disposed', (
    tester,
  ) async {
    final credential = Completer<UserCredential>();
    final setup = await _pumpSignup(tester, credential: credential.future);

    await tester.tap(find.widgetWithText(OutlinedButton, t.auth.createAccount));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    credential.complete(_Credential());
    await tester.pumpAndSettle();

    expect(setup.connector.requests, hasLength(1));
    expect(setup.prefs.getString('selected_team_id:cloud'), 'new-user');
    expect(tester.takeException(), isNull);
  });
}

Future<
  ({
    ProviderContainer container,
    SharedPreferences prefs,
    _Connector connector,
  })
>
_pumpSignup(
  WidgetTester tester, {
  Object? error,
  Future<UserCredential>? credential,
}) async {
  SharedPreferences.setMockInitialValues({
    'selected_team_id:cloud': 'previous-team',
  });
  final prefs = await SharedPreferences.getInstance();
  final connector = _Connector(error);
  final container = ProviderContainer.test(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      firebaseAuthProvider.overrideWith((ref) async => _Auth(credential)),
      teamsConnectorProvider.overrideWith((ref) async => connector),
      teamListProvider.overrideWith((ref) async {
        if (connector.requests.isEmpty || error != null) return [];
        final request = connector.requests.single;
        return [
          Team(
            id: request.id,
            name: request.name,
            members: const ['new-user'],
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
        ];
      }),
    ],
  );
  container.listen(selectedTeamIdProvider, (_, _) {});
  await container.read(selectedTeamIdProvider.future);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: AuthPage()),
    ),
  );
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).at(0), 'user@example.com');
  await tester.enterText(find.byType(TextFormField).at(1), 'test-password');
  await tester.ensureVisible(
    find.widgetWithText(OutlinedButton, t.auth.createAccount),
  );
  return (container: container, prefs: prefs, connector: connector);
}

class _Connector extends Fake implements TeamsConnector {
  _Connector(this.error);

  final Object? error;
  final requests = <CreateTeamVariables>[];

  @override
  CreateTeamVariablesBuilder createTeam({
    required String id,
    required String name,
  }) => _CreateTeam(() async {
    requests.add(CreateTeamVariables(id: id, name: name));
    if (error != null) throw error!;
  });
}

class _CreateTeam extends Fake implements CreateTeamVariablesBuilder {
  _CreateTeam(this.create);

  final Future<void> Function() create;

  @override
  Future<OperationResult<CreateTeamData, CreateTeamVariables>> execute() async {
    await create();
    return _CreateTeamResult();
  }
}

class _CreateTeamResult extends Fake
    implements OperationResult<CreateTeamData, CreateTeamVariables> {}

class _Auth extends Fake implements FirebaseAuth {
  _Auth(this.credential);

  final Future<UserCredential>? credential;

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async => credential ?? _Credential();
}

class _Credential extends Fake implements UserCredential {
  @override
  User get user => _User();
}

class _User extends Fake implements User {
  @override
  String get uid => 'new-user';

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async =>
      'credential-token';
}
