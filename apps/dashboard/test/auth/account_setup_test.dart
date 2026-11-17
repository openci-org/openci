import 'dart:async';

import 'package:dashboard/app_strings.dart';
import 'package:dashboard/auth/auth_page.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/auth/google_sign_in.dart';
import 'package:dashboard/cicd_log/cicd_log_providers.dart';
import 'package:dashboard/connections/connection_profile.dart';
import 'package:dashboard/connections/connection_snapshot.dart';
import 'package:dashboard/connections/connection_store.dart';
import 'package:dashboard/connections/connection_store_provider.dart';
import 'package:dashboard/connections/local_development_connection.dart';
import 'package:dashboard/deep_link/deep_link_listener.dart';
import 'package:dashboard/generated/teams/teams.dart';
import 'package:dashboard/root.dart';
import 'package:dashboard/root/dashboard_root.dart';
import 'package:dashboard/router/router.dart';
import 'package:dashboard/secret_manager/secret_manager_provider.dart';
import 'package:dashboard/team/selected_team_provider.dart';
import 'package:dashboard/team/teams_connector_provider.dart';
import 'package:dashboard/utilities/shared_preferences_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late _Auth auth;
  late _GoogleSignIn google;
  late _Connector connector;
  late ProviderContainer container;
  late SharedPreferences prefs;

  Future<void> pumpApp(
    WidgetTester tester, {
    String profileId = 'cloud',
    bool restoredSession = false,
    Map<String, String> teams = const {},
    Future<void> Function()? beforeInsert,
    Object? queryError,
    bool loseResponse = false,
  }) async {
    LocaleSettings.setLocaleSync(AppLocale.ja);
    PackageInfo.setMockInitialValues(
      appName: 'OpenCI',
      packageName: 'org.openci.dashboard',
      version: '2.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    SharedPreferences.setMockInitialValues({
      'selected_team_id:$profileId': 'existing-team',
    });
    prefs = await SharedPreferences.getInstance();
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
      ConnectionSnapshot(
        profiles: [cloud, company],
        activeId: profileId == 'company' ? 'company' : 'cloud',
      ),
    );
    final local = profileId == localDevelopmentProfileId
        ? LocalDevelopmentConnection.parse(
            mode: 'true',
            apiUrl: 'http://127.0.0.1:8080',
            emulatorHost: '127.0.0.1',
            emulatorPort: '9099',
          )
        : null;
    auth = _Auth()..currentUser = restoredSession ? _User() : null;
    addTearDown(auth.changes.close);
    google = _GoogleSignIn(auth);
    connector = _Connector()
      ..teams.addAll(teams)
      ..beforeInsert = beforeInsert
      ..queryError = queryError
      ..loseResponse = loseResponse;
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        connectionStoreProvider.overrideWithValue(store),
        localDevelopmentConnectionProvider.overrideWithValue(local),
        firebaseAuthProvider.overrideWith((_) async => auth),
        googleSignInProvider.overrideWithValue(google),
        teamsConnectorProvider.overrideWith((_) async => connector),
        deepLinkListenerProvider.overrideWith((_) {}),
        cicdCommitGroupsProvider.overrideWith(_EmptyCommitGroups.new),
        secretManagerProvider.overrideWith(_EmptySecrets.new),
      ],
    );
    addTearDown(container.read(routerProvider).dispose);
    await tester.pumpWidget(
      TranslationProvider(
        child: UncontrolledProviderScope(
          container: container,
          child: const Root(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> signIn(WidgetTester tester) async {
    final button = find.widgetWithText(FilledButton, t.auth.continueWithGoogle);
    await tester.ensureVisible(button);
    await tester.tap(button);
  }

  for (final profileId in ['cloud', 'company', localDevelopmentProfileId]) {
    testWidgets(
      '$profileId completes signup for an existing Firebase user without a team',
      (tester) async {
        await pumpApp(tester, profileId: profileId);
        await signIn(tester);
        await tester.pumpAndSettle();

        expect(connector.requests, [
          CreateTeamVariables(id: 'user-1', name: 'user-1'),
        ]);
        expect(await container.read(selectedTeamIdProvider.future), 'user-1');
        expect(prefs.getString('selected_team_id:$profileId'), 'user-1');
        expect(find.byType(DashboardRoot), findsOneWidget);
        expect(find.byType(AuthPage), findsNothing);
        expect(auth.signOuts, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'waits for team creation after auth redirects, before mounting the dashboard',
    (tester) async {
      final pending = Completer<void>();
      await pumpApp(tester, beforeInsert: () => pending.future);
      await signIn(tester);
      // Firebase authStateChanges arrives before signIn returns its credential.
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(container.read(routerProvider).state.uri.path, '/');
      expect(find.byType(AuthPage), findsNothing);
      expect(find.byType(DashboardRouteGateway), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(connector.requests, hasLength(1));
      expect(auth.signOuts, 0);

      pending.complete();
      await tester.pumpAndSettle();
      expect(find.byType(DashboardRoot), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('restored sessions resume setup without another Google prompt', (
    tester,
  ) async {
    await pumpApp(tester, restoredSession: true);
    expect(connector.requests, hasLength(1));
    expect(google.calls, 0);
    expect(find.byType(DashboardRoot), findsOneWidget);
  });

  testWidgets('preserves existing memberships and the selected team', (
    tester,
  ) async {
    await pumpApp(
      tester,
      teams: {'another-team': 'Another', 'existing-team': 'Existing'},
    );
    await signIn(tester);
    await tester.pumpAndSettle();
    expect(connector.requests, isEmpty);
    expect(
      await container.read(selectedTeamIdProvider.future),
      'existing-team',
    );
    expect(prefs.getString('selected_team_id:cloud'), 'existing-team');
    expect(find.byType(DashboardRoot), findsOneWidget);
  });

  testWidgets(
    'shows creation failure after redirect and retries without signing out',
    (tester) async {
      await pumpApp(
        tester,
        beforeInsert: () async => throw StateError('Creation failed'),
      );
      await signIn(tester);
      await tester.pumpAndSettle();
      expect(find.textContaining('Creation failed'), findsOneWidget);
      expect(find.byType(DashboardRoot), findsNothing);
      expect(auth.signOuts, 0);
      expect(prefs.getString('selected_team_id:cloud'), 'existing-team');

      connector.beforeInsert = null;
      await tester.tap(find.widgetWithText(FilledButton, t.common.retry));
      await tester.pumpAndSettle();
      expect(connector.requests, hasLength(2));
      expect(google.calls, 1);
      expect(find.byType(DashboardRoot), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('does not create a team when membership lookup fails', (
    tester,
  ) async {
    await pumpApp(tester, queryError: StateError('Query failed'));
    await signIn(tester);
    await tester.pumpAndSettle();
    expect(find.textContaining('Query failed'), findsOneWidget);
    expect(connector.requests, isEmpty);

    connector.queryError = null;
    await tester.tap(find.widgetWithText(FilledButton, t.common.retry));
    await tester.pumpAndSettle();
    expect(connector.requests, hasLength(1));
    expect(find.byType(DashboardRoot), findsOneWidget);
  });

  testWidgets('reuses a committed team when its create response was lost', (
    tester,
  ) async {
    await pumpApp(tester, loseResponse: true);
    await signIn(tester);
    await tester.pumpAndSettle();
    expect(find.textContaining('Response lost'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, t.common.retry));
    await tester.pumpAndSettle();
    expect(connector.requests, hasLength(1));
    expect(await container.read(selectedTeamIdProvider.future), 'user-1');
    expect(find.byType(DashboardRoot), findsOneWidget);
  });
}

class _Auth extends Fake implements FirebaseAuth {
  final changes = StreamController<User?>.broadcast();
  @override
  User? currentUser;
  int signOuts = 0;
  @override
  Stream<User?> authStateChanges() async* {
    yield currentUser;
    yield* changes.stream;
  }

  @override
  Stream<User?> userChanges() => authStateChanges();
  @override
  Future<void> signOut() async {
    signOuts++;
    currentUser = null;
    changes.add(null);
  }
}

class _GoogleSignIn extends Fake implements GoogleSignInService {
  _GoogleSignIn(this.auth);
  final _Auth auth;
  int calls = 0;
  @override
  Future<UserCredential?> signIn(FirebaseAuth auth) async {
    calls++;
    this.auth.currentUser = _User();
    this.auth.changes.add(this.auth.currentUser);
    await Future<void>.delayed(Duration.zero);
    return _Credential();
  }
}

class _Credential extends Fake implements UserCredential {
  @override
  User get user => _User();
  @override
  AdditionalUserInfo get additionalUserInfo =>
      AdditionalUserInfo(isNewUser: false);
}

class _User extends Fake implements User {
  @override
  String get uid => 'user-1';
  @override
  String? get email => null;
}

class _Connector extends Fake implements TeamsConnector {
  final teams = <String, String>{};
  final requests = <CreateTeamVariables>[];
  Future<void> Function()? beforeInsert;
  Object? queryError;
  bool loseResponse = false;
  @override
  GetMyTeamsVariablesBuilder getMyTeams() => _GetMyTeams(this);
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
}

class _GetMyTeams extends Fake implements GetMyTeamsVariablesBuilder {
  _GetMyTeams(this.connector);
  final _Connector connector;
  @override
  Future<QueryResult<GetMyTeamsData, void>> execute() async {
    if (connector.queryError case final error?) throw error;
    return _QueryResult(
      GetMyTeamsData(
        teams: [
          for (final entry in connector.teams.entries)
            GetMyTeamsTeams(
              id: entry.key,
              name: entry.value,
              members: [GetMyTeamsTeamsMembers(userId: 'user-1')],
              runNumber: BigInt.one,
              createdAt: BigInt.one,
              updatedAt: BigInt.one,
            ),
        ],
      ),
    );
  }
}

class _QueryResult extends Fake implements QueryResult<GetMyTeamsData, void> {
  _QueryResult(this.data);
  @override
  final GetMyTeamsData data;
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

class _EmptyCommitGroups extends CicdCommitGroups {
  @override
  Stream<List<CicdCommitGroup>> build() => Stream.value(const []);
}

class _EmptySecrets extends SecretManager {
  @override
  Stream<List<Secret>> build() => Stream.value(const []);
}
