import 'dart:async';

import 'package:dashboard/connections/connection_firebase_auth.dart';
import 'package:dashboard/connections/local_development_connection.dart';
import 'package:dashboard/firebase/firebase_config_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Firebase extends FirebasePlatform {
  @override
  final apps = <FirebaseAppPlatform>[];
  var initializations = 0;
  var failNext = false;

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    initializations++;
    await Future<void>.delayed(Duration.zero);
    if (failNext) {
      failNext = false;
      throw StateError('Initialization failed');
    }
    final app = FirebaseAppPlatform(name!, options!);
    apps.add(app);
    return app;
  }

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) =>
      apps.firstWhere((app) => app.name == name);
}

const config = SelfHostedConfig(
  apiKey: 'client-key',
  appId: '1:123:web:abc',
  projectId: 'project',
  authDomain: 'project.firebaseapp.com',
);

void main() {
  late _Firebase firebase;
  late ProviderContainer container;
  var nextId = 0;
  late String profileId;

  setUp(() {
    firebase = _Firebase();
    final previous = Firebase.delegatePackingProperty;
    Firebase.delegatePackingProperty = firebase;
    addTearDown(() => Firebase.delegatePackingProperty = previous);
    container = ProviderContainer.test(retry: (_, _) => null);
    profileId = 'self-hosted-${nextId++}';
  });

  test(
    'Cloud and self-hosted profiles get separate FirebaseAuth instances',
    () async {
      final cloud = await container.read(
        connectionFirebaseAuthProvider('cloud', config).future,
      );
      final selfHosted = await container.read(
        connectionFirebaseAuthProvider(profileId, config).future,
      );
      final another = await container.read(
        connectionFirebaseAuthProvider('another', config).future,
      );
      expect(cloud.app.name, defaultFirebaseAppName);
      expect(selfHosted.app.name, 'connection-$profileId');
      expect(selfHosted, isNot(same(cloud)));
      expect(another, isNot(same(selfHosted)));
      expect(selfHosted, same(FirebaseAuth.instanceFor(app: selfHosted.app)));
      expect(firebase.initializations, 3);
    },
  );

  test(
    'concurrent reads share one initialization, including equal configs',
    () async {
      final results = await Future.wait(
        List.generate(
          5,
          (_) => container.read(
            connectionFirebaseAuthProvider(profileId, config.copyWith()).future,
          ),
        ),
      );
      expect(firebase.initializations, 1);
      expect(results.every((auth) => identical(auth, results.first)), isTrue);
      expect(results.first.app.options, config.toFirebaseOptions());
    },
  );

  test('reuses existing Firebase apps after provider recreation', () async {
    final provider = connectionFirebaseAuthProvider(profileId, config);
    final auth = await container.read(provider.future);
    container.invalidate(provider);
    expect(await container.read(provider.future), same(auth));
    expect(firebase.initializations, 1);
  });

  test('rejects different Firebase settings for the same profile ID', () async {
    await container.read(
      connectionFirebaseAuthProvider(profileId, config).future,
    );
    await expectLater(
      container.read(
        connectionFirebaseAuthProvider(
          profileId,
          config.copyWith(projectId: 'different'),
        ).future,
      ),
      throwsStateError,
    );
    expect(firebase.initializations, 1);
  });

  test(
    'checks existing Firebase settings, including the default app',
    () async {
      firebase.apps.add(
        FirebaseAppPlatform(
          defaultFirebaseAppName,
          config.copyWith(projectId: 'different').toFirebaseOptions(),
        ),
      );
      await expectLater(
        container.read(connectionFirebaseAuthProvider('cloud', config).future),
        throwsStateError,
      );
      expect(firebase.initializations, 0);
    },
  );

  test(
    'failed initialization can be retried by refreshing the provider',
    () async {
      final provider = connectionFirebaseAuthProvider(profileId, config);
      firebase.failNext = true;
      await expectLater(container.read(provider.future), throwsStateError);
      expect(await container.refresh(provider.future), isA<FirebaseAuth>());
      expect(firebase.initializations, 2);
    },
  );

  group('local connection', () {
    final local = LocalDevelopmentConnection.parse(
      mode: 'true',
      apiUrl: 'http://127.0.0.1:8080',
      emulatorHost: '127.0.0.1',
      emulatorPort: '9099',
    )!;
    final provider = connectionFirebaseAuthProvider(
      local.profile.id,
      local.profile.firebase['web']!,
    );
    late List<(FirebaseAuth, String, int)> connections;
    late Future<void> Function() connect;

    setUp(() {
      connections = [];
      connect = () async {};
      container = ProviderContainer.test(
        retry: (_, _) => null,
        overrides: [
          localDevelopmentConnectionProvider.overrideWithValue(local),
          authEmulatorConnectorProvider.overrideWithValue((
            auth,
            host,
            port,
          ) async {
            connections.add((auth, host, port));
            await connect();
          }),
        ],
      );
    });

    test(
      'waits for emulator setup and shares the named Auth instance',
      () async {
        final started = Completer<void>();
        final ready = Completer<void>();
        connect = () {
          started.complete();
          return ready.future;
        };
        final pending = container.read(provider.future);
        final concurrent = container.read(
          connectionFirebaseAuthProvider(
            local.profile.id,
            local.profile.firebase['web']!.copyWith(),
          ).future,
        );
        await started.future;

        expect(container.read(provider).isLoading, isTrue);
        expect(connections, hasLength(1));
        expect(connections.single.$2, '127.0.0.1');
        expect(connections.single.$3, 9099);
        expect(connections.single.$1.app.name, 'connection-local-development');
        expect(connections.single.$1.app.options.projectId, 'demo-openci');

        ready.complete();
        final auth = await pending;
        expect(auth, same(connections.single.$1));
        expect(await concurrent, same(auth));
        expect(await container.read(provider.future), same(auth));
        expect(connections, hasLength(1));
      },
    );

    test('keeps Cloud and deployed self-hosted Auth separate', () async {
      final localAuth = await container.read(provider.future);
      for (final id in ['cloud', profileId]) {
        final auth = await container.read(
          connectionFirebaseAuthProvider(id, config).future,
        );
        expect(auth, isNot(same(localAuth)));
      }
      expect(connections, hasLength(1));
    });

    test('rejects local Auth when local mode is disabled', () async {
      final disabled = ProviderContainer.test(retry: (_, _) => null);
      await expectLater(disabled.read(provider.future), throwsStateError);
      expect(firebase.initializations, 0);
    });

    test('rejects non-demo settings before Firebase initialization', () async {
      await expectLater(
        container.read(
          connectionFirebaseAuthProvider(local.profile.id, config).future,
        ),
        throwsStateError,
      );
      expect(firebase.initializations, 0);
    });

    test('propagates emulator setup errors and allows retry', () async {
      final error = StateError('Emulator setup failed');
      connect = () => Future.error(error);
      await expectLater(container.read(provider.future), throwsA(same(error)));
      expect(firebase.apps.map((app) => app.name), [
        'connection-local-development',
      ]);

      connect = () async {};
      expect(
        await container.refresh(provider.future),
        same(connections.first.$1),
      );
      expect(firebase.initializations, 1);
      expect(connections, hasLength(2));
    });
  });
}
