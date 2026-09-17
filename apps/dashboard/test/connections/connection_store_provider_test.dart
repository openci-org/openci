import 'package:dashboard/connections/active_connection_profile_provider.dart';
import 'package:dashboard/connections/connection_firebase_config.dart';
import 'package:dashboard/connections/connection_store_provider.dart';
import 'package:dashboard/firebase_options.dart';
import 'package:dashboard/utilities/shared_preferences_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('uses the bundled Cloud settings and ignores legacy settings', () async {
    SharedPreferences.setMockInitialValues({
      'sh_firebase_config': 'legacy Firebase settings',
      'custom_openci_server_url': 'https://legacy.example.com',
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer.test(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    final store = container.read(connectionStoreProvider);
    expect(container.read(connectionStoreProvider), same(store));
    final profile = await container.read(
      activeConnectionProfileProvider(store).future,
    );
    expect(profile.isCloud, isTrue);
    expect(profile.apiUrl, const String.fromEnvironment('OPENCI_SERVER_URL'));
    expect(
      profile.firebase['web']!.toFirebaseOptions(),
      DefaultFirebaseOptions.web,
    );

    for (final (platform, options) in [
      (TargetPlatform.iOS, DefaultFirebaseOptions.ios),
      (TargetPlatform.android, DefaultFirebaseOptions.android),
      (TargetPlatform.macOS, DefaultFirebaseOptions.macos),
    ]) {
      debugDefaultTargetPlatformOverride = platform;
      expect(
        firebaseConfigForCurrentPlatform(profile).toFirebaseOptions(),
        options,
      );
    }
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'missing platform settings fail without a Cloud or web fallback',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer.test(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      final cloud = container.read(connectionStoreProvider).cloud;
      final webOnly = cloud.copyWith(
        id: 'self-hosted',
        firebase: {'web': cloud.firebase['web']!},
      );
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      expect(() => firebaseConfigForCurrentPlatform(webOnly), throwsStateError);
    },
  );
}
