import 'dart:async';

import 'package:dashboard/connections/active_connection_profile_provider.dart';
import 'package:dashboard/connections/connection_profile.dart';
import 'package:dashboard/connections/connection_snapshot.dart';
import 'package:dashboard/connections/connection_store.dart';
import 'package:dashboard/connections/local_development_connection.dart';
import 'package:dashboard/firebase/firebase_config_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ControlledStore extends ConnectionStore {
  _ControlledStore(super.prefs, super.cloud);

  final saves = <Completer<void>>[];

  @override
  Future<void> save(ConnectionSnapshot snapshot) async {
    final completion = Completer<void>();
    saves.add(completion);
    await completion.future;
    await super.save(snapshot);
  }
}

ConnectionProfile profile(String id) => ConnectionProfile(
  id: id,
  name: id,
  apiUrl: 'https://$id.example.com',
  firebase: {
    'web': SelfHostedConfig(
      apiKey: '$id-key',
      appId: '1:123:web:$id',
      projectId: id,
    ),
  },
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final cloud = profile('cloud');
  final selfHosted = profile('self-hosted');
  late SharedPreferences prefs;
  late ConnectionStore store;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    store = ConnectionStore(prefs, cloud);
    container = ProviderContainer.test();
  });

  Future<void> saveProfiles({String activeId = 'cloud'}) => store.save(
    ConnectionSnapshot(profiles: [cloud, selfHosted], activeId: activeId),
  );

  test('fresh storage selects Cloud without writing settings', () async {
    expect(
      await container.read(activeConnectionProfileProvider(store).future),
      cloud,
    );
    expect(prefs.getString(ConnectionStore.storageKey), isNull);
  });

  test(
    'restores the saved selection and its Firebase and API settings',
    () async {
      await saveProfiles(activeId: selfHosted.id);

      expect(
        await container.read(activeConnectionProfileProvider(store).future),
        selfHosted,
      );
    },
  );

  test(
    'switches profiles, notifies listeners, and preserves saved profiles',
    () async {
      await saveProfiles();
      final provider = activeConnectionProfileProvider(store);
      await container.read(provider.future);
      final selections = <AsyncValue<ConnectionProfile>>[];
      final subscription = container.listen(
        provider,
        (_, profile) => selections.add(profile),
        fireImmediately: true,
      );
      final notifier = container.read(provider.notifier);

      await notifier.select(selfHosted.id);
      expect(container.read(provider).requireValue, selfHosted);
      expect(store.load().activeId, selfHosted.id);
      expect(selections.map((selection) => selection.isLoading), [
        false,
        true,
        false,
      ]);
      expect(selections.map((selection) => selection.value), [
        cloud,
        cloud,
        selfHosted,
      ]);
      subscription.close();

      container.invalidate(provider);
      expect(await container.read(provider.future), selfHosted);

      await container.read(provider.notifier).select(cloud.id);
      expect(container.read(provider).requireValue, cloud);
      expect(store.load().activeId, cloud.id);
      expect(store.load().profiles, [cloud, selfHosted]);
    },
  );

  test(
    'local selection preserves storage and rejects profile switching',
    () async {
      await saveProfiles(activeId: selfHosted.id);
      final saved = prefs.getString(ConnectionStore.storageKey);
      final local = LocalDevelopmentConnection.parse(
        mode: 'true',
        apiUrl: 'http://127.0.0.1:8080',
        emulatorHost: '127.0.0.1',
        emulatorPort: '9099',
      )!;
      final localContainer = ProviderContainer.test(
        overrides: [
          localDevelopmentConnectionProvider.overrideWithValue(local),
        ],
      );
      final provider = activeConnectionProfileProvider(store);

      expect(await localContainer.read(provider.future), same(local.profile));
      await expectLater(
        localContainer.read(provider.notifier).select(cloud.id),
        throwsStateError,
      );
      expect(localContainer.read(provider).requireValue, same(local.profile));
      expect(prefs.getString(ConnectionStore.storageKey), saved);
      expect(await container.read(provider.future), selfHosted);

      // Local selection must not depend on loading the saved profiles at all.
      await prefs.setString(ConnectionStore.storageKey, 'invalid JSON');
      expect(
        await localContainer.refresh(provider.future),
        same(local.profile),
      );
    },
  );

  test(
    'rejects an unknown ID without changing state or saved settings',
    () async {
      await saveProfiles();
      final provider = activeConnectionProfileProvider(store);
      await container.read(provider.future);
      final saved = prefs.getString(ConnectionStore.storageKey);

      await expectLater(
        container.read(provider.notifier).select('unknown'),
        throwsStateError,
      );
      expect(container.read(provider).requireValue, cloud);
      expect(container.read(provider).isLoading, isFalse);
      expect(prefs.getString(ConnectionStore.storageKey), saved);
    },
  );

  test(
    'publishes changes only after a successful save and allows retry',
    () async {
      await saveProfiles();
      final controlled = _ControlledStore(prefs, cloud);
      final provider = activeConnectionProfileProvider(controlled);
      await container.read(provider.future);
      final notifier = container.read(provider.notifier);
      final error = StateError('Save failed');
      final failed = expectLater(
        notifier.select(selfHosted.id),
        throwsA(same(error)),
      );
      expect(container.read(provider).isLoading, isTrue);
      expect(container.read(provider).requireValue, cloud);
      expect(store.load().activeId, cloud.id);

      controlled.saves.single.completeError(error);
      await failed;
      expect(container.read(provider).requireValue, cloud);
      expect(container.read(provider).isLoading, isFalse);
      expect(store.load().activeId, cloud.id);

      final retry = notifier.select(selfHosted.id);
      expect(container.read(provider).isLoading, isTrue);
      controlled.saves.last.complete();
      await retry;
      expect(container.read(provider).requireValue, selfHosted);
      expect(container.read(provider).isLoading, isFalse);
      expect(store.load().activeId, selfHosted.id);
    },
  );

  test(
    'ignores additional selections while loading and accepts them afterward',
    () async {
      await saveProfiles();
      final controlled = _ControlledStore(prefs, cloud);
      final provider = activeConnectionProfileProvider(controlled);
      await container.read(provider.future);
      final notifier = container.read(provider.notifier);

      final first = notifier.select(selfHosted.id);
      await notifier.select(cloud.id);
      expect(controlled.saves, hasLength(1));
      expect(container.read(provider).isLoading, isTrue);

      controlled.saves.first.complete();
      await first;
      expect(container.read(provider).requireValue, selfHosted);
      expect(container.read(provider).isLoading, isFalse);
      expect(store.load().activeId, selfHosted.id);

      final second = notifier.select(cloud.id);
      expect(controlled.saves, hasLength(2));

      controlled.saves.last.complete();
      await second;
      expect(container.read(provider).requireValue, cloud);
      expect(container.read(provider).isLoading, isFalse);
      expect(store.load().activeId, cloud.id);
    },
  );

  test('finishes saving without updating a disposed provider', () async {
    await saveProfiles();
    final controlled = _ControlledStore(prefs, cloud);
    final provider = activeConnectionProfileProvider(controlled);
    await container.read(provider.future);
    final selection = container.read(provider.notifier).select(selfHosted.id);
    container.dispose();

    controlled.saves.single.complete();
    await selection;
    expect(store.load().activeId, selfHosted.id);
  });
}
