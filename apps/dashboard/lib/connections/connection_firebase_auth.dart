import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../firebase/firebase_config_provider.dart';

part 'connection_firebase_auth.g.dart';

@Riverpod(keepAlive: true)
Future<FirebaseAuth> connectionFirebaseAuth(
  Ref ref,
  String profileId,
  SelfHostedConfig config,
) async {
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
  return FirebaseAuth.instanceFor(app: app);
}
