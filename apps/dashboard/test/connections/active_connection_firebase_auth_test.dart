import 'dart:async';

import 'package:dashboard/connections/active_connection_firebase_auth.dart';
import 'package:dashboard/connections/active_connection_profile_provider.dart';
import 'package:dashboard/connections/connection_firebase_auth.dart';
import 'package:dashboard/connections/connection_profile.dart';
import 'package:dashboard/connections/connection_snapshot.dart';
import 'package:dashboard/connections/connection_store.dart';
import 'package:dashboard/connections/connection_store_provider.dart';
import 'package:dashboard/firebase/firebase_config_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Auth extends Fake implements FirebaseAuth {}

ConnectionProfile profile(String id) => ConnectionProfile(
  id: id,
  name: id,
  apiUrl: 'https://$id.example.com',
  firebase: {
    for (final platform in ['android', 'web'])
      platform: SelfHostedConfig(
        apiKey: '$id-key',
        appId: '1:123:$platform:$id',
        projectId: id,
      ),
  },
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final cloud = profile('cloud');
  final selfHosted = profile('self-hosted');
  final provider = activeConnectionFirebaseAuthProvider;
  late ConnectionStore store;
  late ProviderContainer container;
  late FirebaseAuth cloudAuth;
  late FirebaseAuth selfHostedAuth;
  late FutureOr<FirebaseAuth> selfHostedResult;
  late List<String> initialized;

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    SharedPreferences.setMockInitialValues({});
    store = ConnectionStore(await SharedPreferences.getInstance(), cloud);
    cloudAuth = _Auth();
    selfHostedAuth = _Auth();
    selfHostedResult = selfHostedAuth;
    initialized = [];
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        connectionStoreProvider.overrideWithValue(store),
        for (final profile in [cloud, selfHosted])
          connectionFirebaseAuthProvider(
            profile.id,
            profile.firebase['android']!,
          ).overrideWith((ref) {
            initialized.add(profile.id);
            return profile.isCloud ? cloudAuth : selfHostedResult;
          }),
      ],
    );
  });

  Future<void> saveProfiles({String activeId = 'cloud'}) => store.save(
    ConnectionSnapshot(profiles: [cloud, selfHosted], activeId: activeId),
  );

  Future<FirebaseAuth> loadAuth() {
    container.listen(provider, (_, _) {});
    return container.read(provider.future);
  }

  test(
    'fresh storage uses Cloud authentication for the current platform',
    () async {
      expect(await loadAuth(), same(cloudAuth));
      expect(initialized, [cloud.id]);
    },
  );

  test('restores the saved selection without initializing Cloud', () async {
    await saveProfiles(activeId: selfHosted.id);

    expect(await loadAuth(), same(selfHostedAuth));
    expect(initialized, [selfHosted.id]);
  });

  test(
    'follows profile selections and reuses each authentication instance',
    () async {
      await saveProfiles();
      expect(await loadAuth(), same(cloudAuth));
      final selection = container.read(
        activeConnectionProfileProvider(store).notifier,
      );

      await selection.select(selfHosted.id);
      expect(await container.read(provider.future), same(selfHostedAuth));
      await selection.select(cloud.id);
      expect(await container.read(provider.future), same(cloudAuth));
      expect(initialized, [cloud.id, selfHosted.id]);
    },
  );

  test('waits for the selected FirebaseAuth to initialize', () async {
    await saveProfiles(activeId: selfHosted.id);
    final ready = Completer<FirebaseAuth>();
    selfHostedResult = ready.future;

    final result = loadAuth();
    await container.pump();
    expect(container.read(provider).isLoading, isTrue);
    ready.complete(selfHostedAuth);

    expect(await result, same(selfHostedAuth));
    expect(container.read(provider).isLoading, isFalse);
  });

  test('exposes initialization errors without falling back to Cloud', () async {
    await saveProfiles(activeId: selfHosted.id);
    final ready = Completer<FirebaseAuth>();
    selfHostedResult = ready.future;
    final error = StateError('Initialization failed');

    final failed = expectLater(loadAuth(), throwsA(same(error)));
    await container.pump();
    ready.completeError(error);
    await failed;

    expect(container.read(provider).hasError, isTrue);
    expect(initialized, [selfHosted.id]);
  });
}
