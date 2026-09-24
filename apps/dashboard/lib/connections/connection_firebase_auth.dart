import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../firebase/firebase_config_provider.dart';
import 'local_development_connection.dart';

part 'connection_firebase_auth.g.dart';

typedef AuthEmulatorConnector =
    Future<void> Function(FirebaseAuth auth, String host, int port);

final authEmulatorConnectorProvider = Provider<AuthEmulatorConnector>(
  (ref) =>
      (auth, host, port) => auth.useAuthEmulator(host, port),
);

@Riverpod(keepAlive: true)
Future<FirebaseAuth> connectionFirebaseAuth(
  Ref ref,
  String profileId,
  SelfHostedConfig config,
) async {
  final local = profileId == localDevelopmentProfileId
      ? ref.watch(localDevelopmentConnectionProvider)
      : null;
  if (profileId == localDevelopmentProfileId && local == null) {
    throw StateError('Local development connection is not enabled.');
  }
  if (local != null && !local.profile.firebase.values.contains(config)) {
    throw StateError('Local development requires demo Firebase settings.');
  }
  final connectEmulator = local == null
      ? null
      : ref.watch(authEmulatorConnectorProvider);
  final name = profileId == 'cloud'
      ? defaultFirebaseAppName
      : 'connection-$profileId';
  final options = config.toFirebaseOptions();
  final existing = Firebase.apps.where((app) => app.name == name).firstOrNull;
  final app =
      existing ?? await Firebase.initializeApp(name: name, options: options);
  if (app.options != options) {
    throw StateError('同じ接続先IDで異なるFirebase設定は使用できません。新しい接続先として登録してください。');
  }
  final auth = FirebaseAuth.instanceFor(app: app);
  if (local != null) {
    await connectEmulator!(auth, local.emulatorHost, local.emulatorPort);
  }
  return auth;
}
