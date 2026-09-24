import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/firebase_config_provider.dart';
import 'connection_profile.dart';

const localDevelopmentProfileId = 'local-development';

/// A launch-only connection. It is never loaded from or written to preferences.
class LocalDevelopmentConnection {
  LocalDevelopmentConnection._({
    required this.apiUrl,
    required this.emulatorHost,
    required this.emulatorPort,
  }) : profile = ConnectionProfile(
         id: localDevelopmentProfileId,
         name: 'Local development',
         apiUrl: apiUrl,
         firebase: const {
           'web': SelfHostedConfig(
             apiKey: 'demo-openci-api-key',
             appId: '1:1234567890:web:0123456789abcdef012345',
             messagingSenderId: '1234567890',
             projectId: 'demo-openci',
             authDomain: 'demo-openci.firebaseapp.com',
           ),
           'ios': SelfHostedConfig(
             apiKey: 'demo-openci-api-key',
             appId: '1:1234567890:ios:0123456789abcdef012345',
             messagingSenderId: '1234567890',
             projectId: 'demo-openci',
           ),
           'android': SelfHostedConfig(
             apiKey: 'demo-openci-api-key',
             appId: '1:1234567890:android:0123456789abcdef012345',
             messagingSenderId: '1234567890',
             projectId: 'demo-openci',
           ),
           'macos': SelfHostedConfig(
             apiKey: 'demo-openci-api-key',
             appId: '1:1234567890:ios:fedcba9876543210fedcba',
             messagingSenderId: '1234567890',
             projectId: 'demo-openci',
           ),
         },
       );

  final String apiUrl;
  final String emulatorHost;
  final int emulatorPort;
  final ConnectionProfile profile;

  static LocalDevelopmentConnection? fromEnvironment() => parse(
    mode: const String.fromEnvironment('OPENCI_LOCAL_DEV'),
    apiUrl: const String.fromEnvironment('OPENCI_LOCAL_API_URL'),
    emulatorHost: const String.fromEnvironment('OPENCI_AUTH_EMULATOR_HOST'),
    emulatorPort: const String.fromEnvironment('OPENCI_AUTH_EMULATOR_PORT'),
  );

  static LocalDevelopmentConnection? parse({
    required String mode,
    required String apiUrl,
    required String emulatorHost,
    required String emulatorPort,
  }) {
    if (mode != 'true') {
      if (mode != '' && mode != 'false') {
        throw StateError('OPENCI_LOCAL_DEV must be true or false.');
      }
      if (apiUrl.isNotEmpty ||
          emulatorHost.isNotEmpty ||
          emulatorPort.isNotEmpty) {
        throw StateError(
          'Local connection settings require OPENCI_LOCAL_DEV=true.',
        );
      }
      return null;
    }

    final api = Uri.tryParse(apiUrl);
    if (api == null ||
        api.scheme != 'http' ||
        api.host.isEmpty ||
        (api.path.isNotEmpty && api.path != '/') ||
        api.userInfo.isNotEmpty ||
        api.hasQuery ||
        api.hasFragment) {
      throw StateError('OPENCI_LOCAL_API_URL must be a local HTTP base URL.');
    }
    if (!RegExp(r'^[a-zA-Z0-9.-]+$').hasMatch(emulatorHost)) {
      throw StateError(
        'OPENCI_AUTH_EMULATOR_HOST must be a hostname or IPv4 address.',
      );
    }
    final port = int.tryParse(emulatorPort);
    if (port == null || port < 1 || port > 65535) {
      throw StateError('OPENCI_AUTH_EMULATOR_PORT must be a valid port.');
    }
    return LocalDevelopmentConnection._(
      apiUrl: apiUrl,
      emulatorHost: emulatorHost,
      emulatorPort: port,
    );
  }
}

final localDevelopmentConnectionProvider =
    Provider<LocalDevelopmentConnection?>(
      (ref) => LocalDevelopmentConnection.fromEnvironment(),
    );
