import 'dart:convert';

import 'package:dashboard/connections/connection_profile.dart';
import 'package:dashboard/connections/connection_store.dart';
import 'package:dashboard/connections/connection_snapshot.dart';
import 'package:dashboard/firebase/firebase_config_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const webConfig = SelfHostedConfig(
  apiKey: 'client-api-key',
  appId: '1:123:web:abc',
  projectId: 'test-project',
  messagingSenderId: '123',
  authDomain: 'test-project.firebaseapp.com',
  storageBucket: 'test-project.firebasestorage.app',
  measurementId: 'G-TEST',
);
const appleConfig = SelfHostedConfig(
  apiKey: 'apple-client-api-key',
  appId: '1:123:ios:def',
  projectId: 'test-project',
  iosBundleId: 'org.example.dashboard',
  iosClientId: 'apple-client-id',
  androidClientId: 'android-client-id',
  databaseURL: 'https://test-project.firebaseio.com',
);

ConnectionProfile profile(String id, {String? apiUrl, String? name}) =>
    ConnectionProfile(
      id: id,
      name: name ?? id,
      apiUrl: apiUrl ?? 'https://$id.example.com',
      firebase: {'web': webConfig, 'ios': appleConfig, 'macos': appleConfig},
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  late ConnectionProfile cloud;
  late ConnectionStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    cloud = profile('cloud');
    store = ConnectionStore(prefs, cloud);
  });

  test('Freezed supports value equality and independent profile updates', () {
    final original = profile('dmis');
    expect(ConnectionProfile.fromJson(original.toJson()), original);
    expect(
      ConnectionProfile.fromJson(original.toJson()).hashCode,
      original.hashCode,
    );

    final configs = {'web': webConfig.copyWith(projectId: 'updated-project')};
    final updated = original.copyWith(
      name: 'Updated',
      apiUrl: 'https://updated.example.com',
      firebase: configs,
    );
    expect(updated.name, 'Updated');
    expect(updated.apiUrl, 'https://updated.example.com');
    expect(updated.firebase['web']!.projectId, 'updated-project');
    expect(original.name, 'dmis');
    expect(original.firebase['web'], webConfig);
    expect(updated, isNot(original));
    expect(() => updated.firebase.clear(), throwsUnsupportedError);
  });

  test(
    'snapshots support value equality and selection updates with copyWith',
    () {
      final dmis = profile('dmis');
      final snapshot = ConnectionSnapshot(
        profiles: [cloud, dmis],
        activeId: cloud.id,
      );
      final equal = ConnectionSnapshot(
        profiles: [cloud, profile('dmis')],
        activeId: cloud.id,
      );
      expect(snapshot, equal);
      expect(snapshot.hashCode, equal.hashCode);

      final selected = snapshot.copyWith(activeId: dmis.id);
      expect(selected.activeId, dmis.id);
      expect(selected.profiles, snapshot.profiles);
      expect(snapshot.activeId, cloud.id);
      expect(selected, isNot(snapshot));
      expect(() => selected.profiles.clear(), throwsUnsupportedError);
    },
  );

  test('a fresh installation contains only the built-in Cloud profile', () {
    final snapshot = store.load();
    expect(snapshot.profiles, [cloud]);
    expect(snapshot.activeId, 'cloud');
  });

  test('old Firebase, API and team settings are ignored', () async {
    await prefs.setString('sh_firebase_config', '{invalid old config');
    await prefs.setString(
      'sh_firebase_configs',
      jsonEncode([webConfig.toJson()]),
    );
    await prefs.setString('sh_firebase_active_project_id', webConfig.projectId);
    await prefs.setString(
      'custom_openci_server_url',
      'https://old.example.com',
    );
    await prefs.setString('selected_team_id', 'old-team');

    final snapshot = store.load();
    expect(snapshot.profiles, [cloud]);
    expect(snapshot.activeId, cloud.id);
    await store.save(snapshot);
    expect(store.load().profiles, [cloud]);
    expect(prefs.getString('selected_team_id:cloud'), isNull);
  });

  test(
    'round trip preserves names, URLs, platform options and selected profile',
    () async {
      final dmis = profile('dmis', name: 'DMIS');
      final another = ConnectionProfile(
        id: 'another',
        name: 'Another',
        apiUrl: 'https://another.example.com',
        firebase: {'web': webConfig.copyWith(projectId: 'another-project')},
      );
      await store.save(
        ConnectionSnapshot(profiles: [cloud, dmis, another], activeId: dmis.id),
      );

      final restored = ConnectionStore(prefs, cloud).load();
      expect(restored.activeId, dmis.id);
      expect(restored.profiles.map((p) => p.toJson()).toList(), [
        cloud.toJson(),
        dmis.toJson(),
        another.toJson(),
      ]);
      expect(
        restored.profiles[1].firebase['web']!.authDomain,
        webConfig.authDomain,
      );
      expect(
        restored.profiles[1].firebase['ios']!.iosBundleId,
        appleConfig.iosBundleId,
      );
    },
  );

  test(
    'updating a profile saves its Firebase configuration and API URL together',
    () async {
      await store.save(
        ConnectionSnapshot(
          profiles: [cloud, profile('dmis')],
          activeId: 'dmis',
        ),
      );
      final updated = ConnectionProfile(
        id: 'dmis',
        name: 'Renamed',
        apiUrl: 'https://new.example.com',
        firebase: {'web': webConfig.copyWith(projectId: 'new-project')},
      );
      await store.save(
        ConnectionSnapshot(profiles: [cloud, updated], activeId: 'dmis'),
      );
      final restored = store.load();
      expect(restored.profiles.length, 2);
      expect(restored.profiles.last.toJson(), updated.toJson());
    },
  );

  test(
    'removing a profile and returning to Cloud persists across reloads',
    () async {
      await store.save(
        ConnectionSnapshot(
          profiles: [cloud, profile('dmis')],
          activeId: 'dmis',
        ),
      );
      await store.save(
        ConnectionSnapshot(profiles: [cloud], activeId: cloud.id),
      );
      final restored = ConnectionStore(prefs, cloud).load();
      expect(restored.profiles, [cloud]);
      expect(restored.activeId, cloud.id);
    },
  );

  test(
    'Cloud configuration comes from the application, not saved JSON',
    () async {
      await store.save(
        ConnectionSnapshot(
          profiles: [cloud, profile('dmis')],
          activeId: cloud.id,
        ),
      );
      final json =
          jsonDecode(prefs.getString(ConnectionStore.storageKey)!)
              as Map<String, dynamic>;
      expect((json['profiles'] as List).map((p) => p['id']), ['dmis']);
      final newCloud = profile(
        'cloud',
        apiUrl: 'https://new-cloud.example.com',
      );
      expect(
        ConnectionStore(prefs, newCloud).load().profiles.first,
        same(newCloud),
      );
    },
  );

  test(
    'profile maps and snapshot lists are read-only',
    () {
      final configs = {'web': webConfig};
      final saved = ConnectionProfile(
        id: 'test',
        name: 'Test',
        apiUrl: 'https://test.example.com',
        firebase: configs,
      );
      expect(saved.firebase['web'], webConfig);
      expect(() => saved.firebase.clear(), throwsUnsupportedError);
      final profiles = [cloud, saved];
      final snapshot = ConnectionSnapshot(
        profiles: profiles,
        activeId: saved.id,
      );
      expect(snapshot.profiles.length, 2);
      expect(() => snapshot.profiles.clear(), throwsUnsupportedError);
    },
  );

  test(
    'malformed new settings are reported without overwriting them',
    () async {
      await prefs.setString(ConnectionStore.storageKey, '{invalid');
      expect(store.load, throwsFormatException);
      expect(prefs.getString(ConnectionStore.storageKey), '{invalid');
    },
  );
}
