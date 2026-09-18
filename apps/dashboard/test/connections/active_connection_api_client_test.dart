import 'package:chopper/chopper.dart';
import 'package:dashboard/connections/active_connection_api_client.dart';
import 'package:dashboard/connections/active_connection_profile_provider.dart';
import 'package:dashboard/connections/connection_api_client.dart';
import 'package:dashboard/connections/connection_profile.dart';
import 'package:dashboard/connections/connection_snapshot.dart';
import 'package:dashboard/connections/connection_store.dart';
import 'package:dashboard/connections/connection_store_provider.dart';
import 'package:dashboard/firebase/firebase_config_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final provider = activeConnectionApiClientProvider;
  late ConnectionStore store;
  late ProviderContainer container;
  late Map<String, ChopperClient> clients;

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    SharedPreferences.setMockInitialValues({});
    store = ConnectionStore(await SharedPreferences.getInstance(), cloud);
    clients = {
      for (final profile in [cloud, selfHosted])
        profile.id: ChopperClient(baseUrl: Uri.parse(profile.apiUrl)),
    };
    for (final client in clients.values) {
      addTearDown(client.dispose);
    }
    container = ProviderContainer.test(
      overrides: [
        connectionStoreProvider.overrideWithValue(store),
        for (final profile in [cloud, selfHosted])
          connectionApiClientProvider(
            profile,
            profile.firebase['android']!,
          ).overrideWith((ref) => clients[profile.id]!),
      ],
    );
  });

  Future<void> saveProfiles({String activeId = 'cloud'}) => store.save(
    ConnectionSnapshot(profiles: [cloud, selfHosted], activeId: activeId),
  );

  Future<ChopperClient> loadClient() {
    container.listen(provider, (_, _) {});
    return container.read(provider.future);
  }

  test(
    'fresh storage uses the Cloud client for the current platform',
    () async {
      expect(await loadClient(), same(clients[cloud.id]));
    },
  );

  test('restores the saved client selection', () async {
    await saveProfiles(activeId: selfHosted.id);

    expect(await loadClient(), same(clients[selfHosted.id]));
  });

  test('follows profile selections in both directions', () async {
    await saveProfiles();
    expect(await loadClient(), same(clients[cloud.id]));
    final selection = container.read(
      activeConnectionProfileProvider(store).notifier,
    );

    await selection.select(selfHosted.id);
    expect(await container.read(provider.future), same(clients[selfHosted.id]));
    await selection.select(cloud.id);
    expect(await container.read(provider.future), same(clients[cloud.id]));
  });
}
