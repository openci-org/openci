import 'dart:async';
import 'dart:convert';

import 'package:dashboard/app_strings.dart';
import 'package:dashboard/auth/auth_page.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/auth/google_sign_in.dart';
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
  for (final (localMode, locale) in [
    for (final local in [false, true])
      for (final language in AppLocale.values) (local, language),
  ]) {
    testWidgets(
      'shows the active connection indicator: local=$localMode, locale=$locale',
      (
        tester,
      ) async {
        LocaleSettings.setLocaleSync(locale);
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
          TranslationProvider(
            child: ProviderScope(
              overrides: [
                sharedPreferencesProvider.overrideWithValue(prefs),
                connectionStoreProvider.overrideWithValue(store),
                localDevelopmentConnectionProvider.overrideWithValue(
                  localMode ? local : null,
                ),
              ],
              child: const MaterialApp(home: AuthPage()),
            ),
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
        expect(find.text(t.auth.signInSubtitle), findsOneWidget);
        expect(find.text(t.auth.createAccount), findsNothing);
        expect(find.text(t.auth.continueWithGoogle), findsOneWidget);
        await tester.ensureVisible(
          find.widgetWithText(OutlinedButton, t.auth.login),
        );
        await tester.tap(find.widgetWithText(OutlinedButton, t.auth.login));
        await tester.pumpAndSettle();
        expect(find.text(t.auth.enterEmail), findsOneWidget);
        expect(find.text(t.auth.enterPassword), findsOneWidget);
        await tester.ensureVisible(find.byType(DropdownButton<String>));
        await tester.tap(find.byType(DropdownButton<String>));
        await tester.pumpAndSettle();
        await tester.tap(
          find.text(locale == AppLocale.en ? '日本語' : 'English').last,
        );
        await tester.pumpAndSettle();
        expect(find.text(t.auth.enterEmail), findsOneWidget);
        expect(find.text(t.auth.enterPassword), findsOneWidget);
        expect(prefs.getString('sh_firebase_config'), saved);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('creates and selects the signup team through the SDK', (
    tester,
  ) async {
    final setup = await _pumpSignup(tester);
    final button = find.widgetWithText(FilledButton, t.auth.continueWithGoogle);

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
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  for (final profileId in ['cloud', 'company', localDevelopmentProfileId]) {
    testWidgets('$profileId registers with Google in the selected connection', (
      tester,
    ) async {
      final setup = await _pumpSignup(tester, profileId: profileId);
      expect(find.text(t.auth.createAccount), findsNothing);
      expect(find.text(t.auth.existingEmailAccount), findsOneWidget);
      await tester.tap(
        find.widgetWithText(FilledButton, t.auth.continueWithGoogle),
      );
      await tester.pumpAndSettle();
      expect(setup.google.calls, 1);
      expect(setup.google.auth, same(setup.auth));
      expect(setup.connector.requests, hasLength(1));
      expect(setup.prefs.getString('selected_team_id:$profileId'), 'new-user');
      expect(find.text(t.auth.enterEmail), findsNothing);
      expect(find.text(t.auth.enterPassword), findsNothing);
    });
  }

  testWidgets(
    'existing Google users keep their team and do not create another',
    (tester) async {
      final setup = await _pumpSignup(tester, isNewUser: false);
      await tester.tap(
        find.widgetWithText(FilledButton, t.auth.continueWithGoogle),
      );
      await tester.pumpAndSettle();
      expect(setup.connector.requests, isEmpty);
      expect(setup.prefs.getString('selected_team_id:cloud'), 'previous-team');
    },
  );

  testWidgets('canceling Google sign-in leaves the form usable', (
    tester,
  ) async {
    final setup = await _pumpSignup(tester, cancel: true);
    final button = find.widgetWithText(FilledButton, t.auth.continueWithGoogle);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(setup.connector.requests, isEmpty);
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
  });

  testWidgets('Google signup requires agreement to the terms', (tester) async {
    final setup = await _pumpSignup(tester);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    final button = find.widgetWithText(FilledButton, t.auth.continueWithGoogle);
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    expect(setup.google.calls, 0);
  });

  testWidgets('existing email and password users can still sign in', (
    tester,
  ) async {
    final setup = await _pumpSignup(tester);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'existing@example.com',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'existing-password',
    );
    final button = find.widgetWithText(OutlinedButton, t.auth.login);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(setup.auth.logins, [('existing@example.com', 'existing-password')]);
    expect(setup.google.calls, 0);
    expect(setup.connector.requests, isEmpty);
  });

  testWidgets('provider conflicts direct the user to their existing login', (
    tester,
  ) async {
    final pending = Completer<UserCredential>();
    final setup = await _pumpSignup(tester, credential: pending.future);
    final button = find.widgetWithText(FilledButton, t.auth.continueWithGoogle);
    await tester.tap(button);
    await tester.pump();
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, t.auth.login),
          )
          .onPressed,
      isNull,
    );
    pending.completeError(
      FirebaseAuthException(code: 'account-exists-with-different-credential'),
    );
    await tester.pumpAndSettle();
    expect(find.text(t.auth.googleAccountConflict), findsOneWidget);
    expect(setup.connector.requests, isEmpty);
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
  });

  testWidgets('keeps the selected team when the SDK rejects creation', (
    tester,
  ) async {
    final setup = await _pumpSignup(
      tester,
      error: StateError('Team creation failed'),
    );
    final button = find.widgetWithText(FilledButton, t.auth.continueWithGoogle);

    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(setup.connector.requests, hasLength(1));
    expect(setup.prefs.getString('selected_team_id:cloud'), 'previous-team');
    expect(find.textContaining('Team creation failed'), findsOneWidget);
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('finishes team creation after the auth page is disposed', (
    tester,
  ) async {
    final credential = Completer<UserCredential>();
    final setup = await _pumpSignup(tester, credential: credential.future);

    await tester.tap(
      find.widgetWithText(FilledButton, t.auth.continueWithGoogle),
    );
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
    _Auth auth,
    _GoogleSignIn google,
  })
>
_pumpSignup(
  WidgetTester tester, {
  Object? error,
  Future<UserCredential>? credential,
  bool isNewUser = true,
  bool cancel = false,
  String profileId = 'cloud',
}) async {
  SharedPreferences.setMockInitialValues({
    'selected_team_id:$profileId': 'previous-team',
  });
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
  final connector = _Connector(error);
  final auth = _Auth();
  final google = _GoogleSignIn(
    credential,
    isNewUser: isNewUser,
    cancel: cancel,
  );
  final container = ProviderContainer.test(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      connectionStoreProvider.overrideWithValue(store),
      localDevelopmentConnectionProvider.overrideWithValue(local),
      firebaseAuthProvider.overrideWith((ref) async => auth),
      googleSignInProvider.overrideWithValue(google),
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
    TranslationProvider(
      child: UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AuthPage()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(
    find.widgetWithText(FilledButton, t.auth.continueWithGoogle),
  );
  return (
    container: container,
    prefs: prefs,
    connector: connector,
    auth: auth,
    google: google,
  );
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
  final logins = <(String, String)>[];

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    logins.add((email, password));
    return _Credential(isNewUser: false);
  }
}

class _GoogleSignIn extends Fake implements GoogleSignInService {
  _GoogleSignIn(
    this.credential, {
    required this.isNewUser,
    required this.cancel,
  });

  final Future<UserCredential>? credential;
  final bool isNewUser;
  final bool cancel;
  int calls = 0;
  FirebaseAuth? auth;

  @override
  Future<UserCredential?> signIn(FirebaseAuth auth) async {
    this.auth = auth;
    calls++;
    if (cancel) return null;
    return credential ?? _Credential(isNewUser: isNewUser);
  }
}

class _Credential extends Fake implements UserCredential {
  _Credential({this.isNewUser = true});
  final bool isNewUser;

  @override
  User get user => _User();

  @override
  AdditionalUserInfo get additionalUserInfo =>
      AdditionalUserInfo(isNewUser: isNewUser);
}

class _User extends Fake implements User {
  @override
  String get uid => 'new-user';

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async =>
      'credential-token';
}
