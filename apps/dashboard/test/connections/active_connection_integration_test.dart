import 'dart:async';

import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/connections/active_connection_profile_provider.dart';
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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

ConnectionProfile profile(String id) => ConnectionProfile(
  id: id,
  name: id,
  apiUrl: 'https://$id.example.com',
  firebase: {
    'android': SelfHostedConfig(
      apiKey: '$id-key',
      appId: '1:123:android:$id',
      projectId: id,
    ),
  },
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final cloud = profile('cloud');
  final selfHosted = profile('self-hosted');
  final local = LocalDevelopmentConnection.parse(
    mode: 'true',
    apiUrl: 'http://127.0.0.1:8080',
    emulatorHost: '127.0.0.1',
    emulatorPort: '9099',
  )!;
  late ConnectionStore store;
  late ProviderContainer container;
  late Map<String, _Auth> auths;
  late Map<String, FutureOr<FirebaseAuth>> authResults;
  LocalDevelopmentConnection? localSettings;

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    SharedPreferences.setMockInitialValues({
      'custom_openci_server_url': 'https://legacy.example.com',
    });
    store = ConnectionStore(await SharedPreferences.getInstance(), cloud);
    localSettings = null;
    auths = {
      for (final profile in [cloud, selfHosted, local.profile])
        profile.id: _Auth(_User(profile.id)),
    };
    for (final auth in auths.values) {
      addTearDown(auth.changes.close);
    }
    authResults = {...auths};
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Dashboard')),
        ),
      ],
    );
    addTearDown(router.dispose);
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        connectionStoreProvider.overrideWithValue(store),
        localDevelopmentConnectionProvider.overrideWith((ref) => localSettings),
        for (final profile in [cloud, selfHosted, local.profile])
          connectionFirebaseAuthProvider(
            profile.id,
            profile.firebase['android']!,
          ).overrideWith((ref) => authResults[profile.id]!),
        deepLinkListenerProvider.overrideWith((ref) {}),
        routerProvider.overrideWithValue(router),
      ],
    );
  });

  Future<void> saveProfiles({String activeId = 'cloud'}) => store.save(
    ConnectionSnapshot(profiles: [cloud, selfHosted], activeId: activeId),
  );

  Future<void> listenToConnection() async {
    container.listen(authStateChangesProvider, (_, _) {});
    container.listen(currentUserIdProvider, (_, _) {});
    await container.read(activeConnectionProfileProvider(store).future);
    await container.pump();
  }

  Future<void> expectConnection(ConnectionProfile profile) async {
    expect(
      await container.read(firebaseAuthProvider.future),
      same(auths[profile.id]),
    );
    final user = await container.read(authStateChangesProvider.future);
    expect(user?.uid, '${profile.id}-user');
    expect(container.read(currentUserIdProvider), user?.uid);
  }

  test('restores the saved profile for authentication', () async {
    await saveProfiles(activeId: selfHosted.id);
    await listenToConnection();
    await expectConnection(selfHosted);
  });

  test(
    'switches authentication and signs out only the selected profile',
    () async {
      await saveProfiles();
      await listenToConnection();
      await expectConnection(cloud);
      final selection = container.read(
        activeConnectionProfileProvider(store).notifier,
      );
      await selection.select(selfHosted.id);
      await expectConnection(selfHosted);
      await (await container.read(firebaseAuthProvider.future)).signOut();
      await container.pump();
      expect(container.read(currentUserProvider), isNull);
      expect(auths[selfHosted.id]!.currentUser, isNull);
      expect(auths[cloud.id]!.currentUser, isNotNull);
      await selection.select(cloud.id);
      await expectConnection(cloud);
    },
  );

  test('waits for local Auth without changing the saved selection', () async {
    await saveProfiles(activeId: selfHosted.id);
    localSettings = local;
    final ready = Completer<FirebaseAuth>();
    authResults[local.profile.id] = ready.future;
    await listenToConnection();
    await container.pump();
    expect(container.read(authStateChangesProvider).isLoading, isTrue);
    ready.complete(auths[local.profile.id]);
    await expectConnection(local.profile);
    expect(store.load().activeId, selfHosted.id);
  });

  test('failed local Auth does not fall back to Cloud', () async {
    await saveProfiles(activeId: selfHosted.id);
    localSettings = local;
    final ready = Completer<FirebaseAuth>();
    authResults[local.profile.id] = ready.future;
    await listenToConnection();
    final error = StateError('Emulator setup failed');
    final failure = expectLater(
      container.read(firebaseAuthProvider.future),
      throwsA(same(error)),
    );
    ready.completeError(error);
    await failure;
    expect(store.load().activeId, selfHosted.id);
  });

  test(
    'a delayed previous initialization does not replace the selected profile',
    () async {
      await saveProfiles();
      final pending = Completer<FirebaseAuth>();
      authResults[cloud.id] = pending.future;
      await listenToConnection();
      await container.pump();
      expect(container.read(authStateChangesProvider).isLoading, isTrue);
      await container
          .read(activeConnectionProfileProvider(store).notifier)
          .select(selfHosted.id);
      await expectConnection(selfHosted);
      pending.complete(auths[cloud.id]);
      await container.pump();
      await expectConnection(selfHosted);
    },
  );

  testWidgets(
    'retries failed Firebase initialization from the root error screen',
    (tester) async {
      try {
        await saveProfiles(activeId: selfHosted.id);
        final pending = Completer<FirebaseAuth>();
        authResults[selfHosted.id] = pending.future;
        await tester.pumpWidget(
          UncontrolledProviderScope(container: container, child: const Root()),
        );
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Dashboard'), findsNothing);

        pending.completeError(StateError('Firebase initialization failed'));
        await tester.pumpAndSettle();
        expect(find.text('認証状態を確認できませんでした。'), findsOneWidget);

        authResults[selfHosted.id] = auths[selfHosted.id]!;
        await tester.tap(find.text('再試行'));
        await tester.pumpAndSettle();

        expect(find.text('Dashboard'), findsOneWidget);
        expect(find.text('再試行'), findsNothing);
        expect(
          await container.read(firebaseAuthProvider.future),
          same(auths[selfHosted.id]),
        );
        expect(tester.takeException(), isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}

class _Auth extends Fake implements FirebaseAuth {
  _Auth(this.currentUser);

  @override
  User? currentUser;

  final changes = StreamController<User?>.broadcast();

  @override
  Stream<User?> authStateChanges() async* {
    yield currentUser;
    yield* changes.stream;
  }

  @override
  Stream<User?> idTokenChanges() => authStateChanges();

  @override
  Future<void> signOut() async {
    currentUser = null;
    changes.add(null);
  }
}

class _User extends Fake implements User {
  _User(this.profileId);

  final String profileId;

  @override
  String get uid => '$profileId-user';

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async =>
      '$profileId-token';
}
