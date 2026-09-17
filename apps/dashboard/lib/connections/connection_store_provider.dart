import 'package:dashboard/firebase/firebase_config_provider.dart';
import 'package:dashboard/firebase_options.dart';
import 'package:dashboard/utilities/shared_preferences_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'connection_profile.dart';
import 'connection_store.dart';

part 'connection_store_provider.g.dart';

@Riverpod(keepAlive: true)
ConnectionStore connectionStore(Ref ref) => ConnectionStore(
  ref.watch(sharedPreferencesProvider),
  ConnectionProfile(
    id: 'cloud',
    name: 'Cloud',
    apiUrl: const String.fromEnvironment('OPENCI_SERVER_URL'),
    firebase: {
      for (final entry in {
        'web': DefaultFirebaseOptions.web,
        'ios': DefaultFirebaseOptions.ios,
        'android': DefaultFirebaseOptions.android,
        'macos': DefaultFirebaseOptions.macos,
      }.entries)
        entry.key: SelfHostedConfig.fromJson(entry.value.asMap),
    },
  ),
);
