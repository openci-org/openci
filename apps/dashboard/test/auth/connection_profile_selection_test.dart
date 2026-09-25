import 'dart:async';

import 'package:dashboard/api/ws_uri_builder.dart';
import 'package:dashboard/app_strings.dart';
import 'package:dashboard/auth/auth_page.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/connections/connection_firebase_auth.dart';
import 'package:dashboard/connections/connection_profile.dart';
import 'package:dashboard/connections/connection_snapshot.dart';
import 'package:dashboard/connections/connection_store.dart';
import 'package:dashboard/connections/connection_store_provider.dart';
import 'package:dashboard/connections/local_development_connection.dart';
import 'package:dashboard/deep_link/deep_link_listener.dart';
import 'package:dashboard/firebase/firebase_config_provider.dart';
import 'package:dashboard/root.dart';
import 'package:dashboard/router/router.dart';
import 'package:dashboard/settings/settings_page.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/utilities/shared_preferences_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _platform = kIsWeb ? 'web' : 'android';
const _cloudConfig = SelfHostedConfig(
  apiKey: 'cloud-key',
  appId: 'cloud-app',
  projectId: 'cloud-project',
);
const _companyConfig = SelfHostedConfig(
  apiKey: 'company-key',
  appId: 'company-app',
  projectId: 'company-project',
);
const _cloud = ConnectionProfile(
  id: 'cloud',
  name: 'Cloud',
  apiUrl: 'https://cloud.example.com',
  firebase: {_platform: _cloudConfig},
);
const _company = ConnectionProfile(
  id: 'company',
  name: 'Company',
  apiUrl: 'https://company.example.com',
  firebase: {_platform: _companyConfig},
);

void main() {
  final formT = t.auth.firebaseForm;
  late SharedPreferences prefs;
  late ConnectionStore store;
  late ProviderContainer container;
  late GoRouter router;
  late _Auth cloudAuth;
  late _Auth companyAuth;
  Future<FirebaseAuth> Function()? initializeCloud;
  Future<FirebaseAuth> Function()? initializeCompany;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    store = ConnectionStore(prefs, _cloud);
    await store.save(
      const ConnectionSnapshot(
        profiles: [_cloud, _company],
        activeId: 'cloud',
      ),
    );
    cloudAuth = _Auth(null);
    companyAuth = _Auth(_User('company'));
    initializeCloud = null;
    initializeCompany = null;
    PackageInfo.setMockInitialValues(
      appName: 'OpenCI',
      packageName: 'org.openci.dashboard',
      version: '2.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  Finder useButton(ConnectionProfile profile) => find.descendant(
    of: find.byKey(ValueKey(profile.id)),
    matching: find.byType(TextButton),
  );

  Future<void> pumpApp(
    WidgetTester tester, {
    String location = '/auth?from=%2Fruns%2Fold-server-job',
    Widget loginPage = const _Page('Login'),
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(900, 1200);
    addTearDown(tester.view.reset);
    router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(path: '/auth', builder: (_, _) => loginPage),
        GoRoute(path: '/', builder: (_, _) => const _Page('Home')),
        GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
      ],
    );
    addTearDown(router.dispose);
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        connectionStoreProvider.overrideWithValue(store),
        localDevelopmentConnectionProvider.overrideWith((ref) => null),
        connectionFirebaseAuthProvider('cloud', _cloudConfig).overrideWith(
          (ref) => initializeCloud?.call() ?? cloudAuth,
        ),
        connectionFirebaseAuthProvider('company', _companyConfig).overrideWith(
          (ref) => initializeCompany?.call() ?? companyAuth,
        ),
        deepLinkListenerProvider.overrideWith((ref) {}),
        routerProvider.overrideWithValue(router),
        selectedTeamProvider.overrideWith(
          (ref) async => Team(
            id: 'company-team',
            name: 'Company team',
            members: const ['company'],
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const Root()),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpSelector(WidgetTester tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Open form'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows saved connection names and API URLs', (tester) async {
    await pumpSelector(tester);

    final labels = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byKey(const ValueKey('company')),
            matching: find.byType(Text),
          ),
        )
        .map((text) => text.data);
    expect(labels, containsAll(['Company', 'https://company.example.com']));
  });

  testWidgets('marks the active connection in the list', (tester) async {
    await pumpSelector(tester);

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('cloud')),
        matching: find.text(formT.active),
      ),
      findsOneWidget,
    );
  });

  testWidgets('persists the connection selected with Use', (tester) async {
    await pumpSelector(tester);
    await tester.tap(useButton(_company));
    await tester.pumpAndSettle();

    expect(ConnectionStore(prefs, _cloud).load().activeId, 'company');
  });

  testWidgets('opens home for a signed-in connection', (tester) async {
    await pumpSelector(tester);
    await tester.tap(useButton(_company));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('opens login without the previous server return path', (
    tester,
  ) async {
    companyAuth.currentUser = null;
    await pumpSelector(tester);
    await tester.tap(useButton(_company));
    await tester.pumpAndSettle();

    expect(router.state.uri.toString(), '/auth');
  });

  testWidgets('uses the selected connection for API URL and token', (
    tester,
  ) async {
    await pumpSelector(tester);
    await tester.tap(useButton(_company));
    await tester.pumpAndSettle();
    final uriProvider = FutureProvider(
      (ref) => buildAuthedWebSocketUri(ref, '/builds/commits/stream'),
    );

    expect(
      await container.read(uriProvider.future),
      Uri.parse(
        'wss://company.example.com/builds/commits/stream?token=company-token',
      ),
    );
  });

  testWidgets('preserves the other connection login session', (tester) async {
    final cloudUser = _User('cloud');
    cloudAuth.currentUser = cloudUser;
    await pumpSelector(tester);
    await tester.tap(useButton(_company));
    await tester.pumpAndSettle();

    expect(cloudAuth.currentUser, same(cloudUser));
  });

  testWidgets('disables actions while authentication initializes', (
    tester,
  ) async {
    final ready = Completer<FirebaseAuth>();
    initializeCompany = () => ready.future;
    await pumpSelector(tester);
    await tester.tap(useButton(_company));
    await tester.pump();

    final buttons = tester.widgetList<ButtonStyleButton>(
      find.descendant(
        of: find.byType(FirebaseFormSheet),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );
    expect(buttons.map((button) => button.onPressed), everyElement(isNull));

    ready.complete(companyAuth);
    await tester.pumpAndSettle();
  });

  testWidgets('shows loading until the selection is persisted', (tester) async {
    final delayedStore = _DelayedStore(prefs, _cloud);
    store = delayedStore;
    await pumpSelector(tester);
    await tester.tap(useButton(_company));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    delayedStore.ready.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('ignores repeated Use clicks while switching', (tester) async {
    final delayedStore = _DelayedStore(prefs, _cloud);
    store = delayedStore;
    await pumpSelector(tester);
    await tester.tap(useButton(_company));
    await tester.tap(useButton(_company));
    await tester.pump();

    expect(delayedStore.saveCount, 1);

    delayedStore.ready.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('shows an initialization error', (
    tester,
  ) async {
    initializeCompany = () async => throw StateError('Initialization failed');
    await pumpSelector(tester);
    await tester.tap(useButton(_company));
    await tester.pumpAndSettle();

    expect(find.textContaining('Initialization failed'), findsOneWidget);
  });

  testWidgets('can retry initialization after an error', (tester) async {
    initializeCompany = () async => throw StateError('Initialization failed');
    await pumpSelector(tester);
    await tester.tap(useButton(_company));
    await tester.pumpAndSettle();

    initializeCompany = () async => companyAuth;
    await tester.tap(useButton(_company));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('keeps the active connection when initialization fails', (
    tester,
  ) async {
    initializeCompany = () async => throw StateError('Initialization failed');
    await pumpSelector(tester);
    await tester.tap(useButton(_company));
    await tester.pumpAndSettle();

    expect(store.load().activeId, 'cloud');
  });

  testWidgets('rejects a profile without Firebase settings for this platform', (
    tester,
  ) async {
    await store.save(
      ConnectionSnapshot(
        profiles: [
          _cloud,
          _company.copyWith(firebase: {}),
        ],
        activeId: 'cloud',
      ),
    );
    await pumpSelector(tester);
    await tester.tap(useButton(_company));
    await tester.pumpAndSettle();

    expect(find.textContaining('用Firebase設定がありません'), findsOneWidget);
  });

  testWidgets('shows a save error even when Root has removed the form', (
    tester,
  ) async {
    final delayedStore = _DelayedStore(prefs, _cloud);
    store = delayedStore;
    await pumpSelector(tester);
    await tester.tap(useButton(_company));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    delayedStore.ready.completeError(
      StateError('Selection could not be saved'),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Selection could not be saved'), findsOneWidget);
  });

  testWidgets('keeps the original selection when saving fails', (tester) async {
    final delayedStore = _DelayedStore(prefs, _cloud);
    store = delayedStore;
    await pumpSelector(tester);
    await tester.tap(useButton(_company));
    await tester.pump();
    delayedStore.ready.completeError(
      StateError('Selection could not be saved'),
    );
    await tester.pumpAndSettle();

    expect(
      await container.read(firebaseAuthProvider.future),
      same(cloudAuth),
    );
  });

  testWidgets('returns from login to home when Cloud is signed in', (
    tester,
  ) async {
    await store.save(store.load().copyWith(activeId: 'company'));
    companyAuth.currentUser = null;
    cloudAuth.currentUser = _User('cloud');
    await pumpApp(tester, loginPage: const AuthPage());

    await tester.tap(find.text(t.settings.returnToCloud));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('returns from login to the Cloud login screen when signed out', (
    tester,
  ) async {
    await store.save(store.load().copyWith(activeId: 'company'));
    companyAuth.currentUser = null;
    await pumpApp(tester, loginPage: const AuthPage());

    await tester.tap(find.text(t.settings.returnToCloud));
    await tester.pumpAndSettle();

    expect(find.text('Cloud'), findsOneWidget);
  });

  testWidgets('returns from settings to home when Cloud is signed in', (
    tester,
  ) async {
    await store.save(store.load().copyWith(activeId: 'company'));
    cloudAuth.currentUser = _User('cloud');
    await pumpApp(tester, location: '/settings');

    await tester.tap(find.text(t.settings.returnToCloud));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets(
    'returns from settings to the Cloud login screen when signed out',
    (
      tester,
    ) async {
      await store.save(store.load().copyWith(activeId: 'company'));
      await pumpApp(
        tester,
        location: '/settings',
        loginPage: const AuthPage(),
      );

      await tester.tap(find.text(t.settings.returnToCloud));
      await tester.pumpAndSettle();

      expect(find.text('Cloud'), findsOneWidget);
    },
  );

  testWidgets('keeps saved self-hosted settings when returning to Cloud', (
    tester,
  ) async {
    await store.save(store.load().copyWith(activeId: 'company'));
    await pumpApp(tester, location: '/settings');

    await tester.tap(find.text(t.settings.returnToCloud));
    await tester.pumpAndSettle();

    expect(
      ConnectionStore(prefs, _cloud).load(),
      const ConnectionSnapshot(profiles: [_cloud, _company], activeId: 'cloud'),
    );
  });

  testWidgets('keeps the self-hosted login session when returning to Cloud', (
    tester,
  ) async {
    await store.save(store.load().copyWith(activeId: 'company'));
    final companyUser = companyAuth.currentUser;
    await pumpApp(tester, location: '/settings');

    await tester.tap(find.text(t.settings.returnToCloud));
    await tester.pumpAndSettle();

    expect(companyAuth.currentUser, same(companyUser));
  });

  testWidgets('leaves legacy preferences intact when returning to Cloud', (
    tester,
  ) async {
    const legacySettings = {
      'sh_firebase_config': 'legacy-config',
      'sh_firebase_active_project_id': 'legacy-project',
      'custom_openci_server_url': 'https://legacy.example.com',
      'selected_team_id': 'legacy-team',
      'selected_team_id:company': 'company-team',
    };
    for (final entry in legacySettings.entries) {
      await prefs.setString(entry.key, entry.value);
    }
    await store.save(store.load().copyWith(activeId: 'company'));
    companyAuth.currentUser = null;
    await pumpApp(tester, loginPage: const AuthPage());

    await tester.tap(find.text(t.settings.returnToCloud));
    await tester.pumpAndSettle();

    expect(
      {for (final key in legacySettings.keys) key: prefs.getString(key)},
      legacySettings,
    );
  });

  testWidgets('uses the Cloud API URL and token after returning to Cloud', (
    tester,
  ) async {
    await store.save(store.load().copyWith(activeId: 'company'));
    cloudAuth.currentUser = _User('cloud');
    await pumpApp(tester, location: '/settings');

    await tester.tap(find.text(t.settings.returnToCloud));
    await tester.pumpAndSettle();
    final uriProvider = FutureProvider(
      (ref) => buildAuthedWebSocketUri(ref, '/builds/commits/stream'),
    );

    expect(
      await container.read(uriProvider.future),
      Uri.parse(
        'wss://cloud.example.com/builds/commits/stream?token=cloud-token',
      ),
    );
  });

  testWidgets('shows the active connection and API URL in settings', (
    tester,
  ) async {
    await store.save(store.load().copyWith(activeId: 'company'));
    await pumpApp(tester, location: '/settings');

    expect(
      tester.widgetList<Text>(find.byType(Text)).map((text) => text.data),
      containsAll(['Company', 'https://company.example.com']),
    );
  });

  testWidgets('hides return to Cloud in settings when Cloud is selected', (
    tester,
  ) async {
    await pumpApp(tester, location: '/settings');

    expect(find.text(t.settings.returnToCloud), findsNothing);
  });

  testWidgets('disables return to Cloud while authentication initializes', (
    tester,
  ) async {
    final ready = Completer<FirebaseAuth>();
    initializeCloud = () => ready.future;
    await store.save(store.load().copyWith(activeId: 'company'));
    await pumpApp(tester, location: '/settings');

    await tester.tap(find.text(t.settings.returnToCloud));
    await tester.pump();
    final button = find.ancestor(
      of: find.byType(CircularProgressIndicator),
      matching: find.byType(TextButton),
    );
    expect(tester.widget<TextButton>(button).onPressed, isNull);

    ready.complete(cloudAuth);
    await tester.pumpAndSettle();
  });

  testWidgets(
    'keeps the self-hosted selection when Cloud initialization fails',
    (
      tester,
    ) async {
      initializeCloud = () async =>
          throw StateError('Cloud initialization failed');
      await store.save(store.load().copyWith(activeId: 'company'));
      await pumpApp(tester, location: '/settings');

      await tester.tap(find.text(t.settings.returnToCloud));
      await tester.pumpAndSettle();

      expect(store.load().activeId, 'company');
    },
  );

  testWidgets('shows a failure to save the return to Cloud selection', (
    tester,
  ) async {
    await store.save(store.load().copyWith(activeId: 'company'));
    final delayedStore = _DelayedStore(prefs, _cloud);
    store = delayedStore;
    await pumpApp(tester, location: '/settings');

    await tester.tap(find.text(t.settings.returnToCloud));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    delayedStore.ready.completeError(StateError('Cloud selection not saved'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Cloud selection not saved'), findsOneWidget);
  });
}

class _Page extends StatelessWidget {
  const _Page(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Text(title),
        TextButton(
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => const FirebaseFormSheet(),
          ),
          child: const Text('Open form'),
        ),
      ],
    ),
  );
}

class _Auth extends Fake implements FirebaseAuth {
  _Auth(this.currentUser);

  @override
  User? currentUser;

  @override
  Stream<User?> authStateChanges() => Stream.value(currentUser);

  @override
  Stream<User?> idTokenChanges() => authStateChanges();

  @override
  Future<void> signOut() async => currentUser = null;
}

class _User extends Fake implements User {
  _User(this.uid);

  @override
  final String uid;

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async => '$uid-token';
}

class _DelayedStore extends ConnectionStore {
  _DelayedStore(super.prefs, super.cloud);

  final ready = Completer<void>();
  int saveCount = 0;

  @override
  Future<void> save(ConnectionSnapshot snapshot) async {
    saveCount++;
    await ready.future;
    await super.save(snapshot);
  }
}
