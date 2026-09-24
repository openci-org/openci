import 'dart:async';

import 'package:dashboard/api/openci_api_client.dart';
import 'package:dashboard/api/ws_uri_builder.dart';
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
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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
  final wsUriProvider = FutureProvider<Uri>(
    (ref) => buildAuthedWebSocketUri(ref, '/builds/commits/stream'),
  );
  late ConnectionStore store;
  late ProviderContainer container;
  late Map<String, _Auth> auths;
  late Map<String, FutureOr<FirebaseAuth>> authResults;
  late List<http.Request> requests;
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
    requests = [];
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

  Future<void> withHttp(Future<void> Function() body) => http.runWithClient(
    body,
    () => MockClient((request) async {
      requests.add(request);
      return http.Response(
        '[]',
        200,
        headers: {'content-type': 'application/json'},
      );
    }),
  );

  void listenToConnection() {
    container.listen(authStateChangesProvider, (_, _) {});
    container.listen(currentUserIdProvider, (_, _) {});
    container.listen(openciApiServiceProvider, (_, _) {});
    container.listen(wsUriProvider, (_, _) {});
  }

  Future<void> expectConnection(ConnectionProfile profile) async {
    expect(
      await container.read(firebaseAuthProvider.future),
      same(auths[profile.id]),
    );
    final user = await container.read(authStateChangesProvider.future);
    expect(user?.uid, '${profile.id}-user');
    expect(container.read(currentUserIdProvider), user?.uid);

    final api = await container.read(openciApiServiceProvider.future);
    await api.getTeams();
    expect(requests.last.url.toString(), '${profile.apiUrl}/teams');
    expect(
      requests.last.headers['Authorization'],
      'Bearer ${profile.id}-token',
    );
    final wsUri = await container.read(wsUriProvider.future);
    expect(wsUri.host, Uri.parse(profile.apiUrl).host);
    expect(wsUri.queryParameters['token'], '${profile.id}-token');
  }

  test(
    'restores the saved profile for authentication, HTTP, and WebSocket',
    () {
      return withHttp(() async {
        await saveProfiles(activeId: selfHosted.id);
        listenToConnection();

        await expectConnection(selfHosted);
        expect(requests, hasLength(1));
      });
    },
  );

  test('switches shared providers and signs out only the selected profile', () {
    return withHttp(() async {
      await saveProfiles();
      listenToConnection();
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
    });
  });

  test('local Auth gates API requests and supplies their token', () {
    return withHttp(() async {
      await saveProfiles(activeId: selfHosted.id);
      localSettings = local;
      final ready = Completer<FirebaseAuth>();
      authResults[local.profile.id] = ready.future;
      listenToConnection();
      final api = await container.read(openciApiServiceProvider.future);
      final response = api.getTeams();
      await container.pump();

      expect(container.read(authStateChangesProvider).isLoading, isTrue);
      expect(requests, isEmpty);
      ready.complete(auths[local.profile.id]);
      await response;
      await expectConnection(local.profile);

      expect(requests, hasLength(2));
      for (final request in requests) {
        expect(request.url.toString(), 'http://127.0.0.1:8080/teams');
        expect(
          request.headers['Authorization'],
          'Bearer local-development-token',
        );
      }
      expect(store.load().activeId, selfHosted.id);
    });
  });

  test(
    'failed local Auth blocks API requests without falling back to Cloud',
    () {
      return withHttp(() async {
        await saveProfiles(activeId: selfHosted.id);
        localSettings = local;
        final ready = Completer<FirebaseAuth>();
        authResults[local.profile.id] = ready.future;
        listenToConnection();
        final api = await container.read(openciApiServiceProvider.future);
        final error = StateError('Emulator setup failed');
        final authFailure = expectLater(
          container.read(firebaseAuthProvider.future),
          throwsA(same(error)),
        );
        final requestFailure = expectLater(
          api.getTeams(),
          throwsA(same(error)),
        );

        ready.completeError(error);
        await Future.wait([authFailure, requestFailure]);
        expect(requests, isEmpty);
        expect(store.load().activeId, selfHosted.id);
      });
    },
  );

  test(
    'a delayed previous initialization does not replace the selected profile',
    () {
      return withHttp(() async {
        await saveProfiles();
        final pending = Completer<FirebaseAuth>();
        authResults[cloud.id] = pending.future;
        listenToConnection();
        await container.pump();
        expect(container.read(authStateChangesProvider).isLoading, isTrue);

        await container
            .read(activeConnectionProfileProvider(store).notifier)
            .select(selfHosted.id);
        await expectConnection(selfHosted);

        pending.complete(auths[cloud.id]);
        await container.pump();
        await expectConnection(selfHosted);
      });
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
