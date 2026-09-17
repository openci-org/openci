import 'package:flutter/foundation.dart';

import '../firebase/firebase_config_provider.dart';
import 'connection_profile.dart';

SelfHostedConfig firebaseConfigForCurrentPlatform(ConnectionProfile profile) {
  final platform = kIsWeb ? 'web' : defaultTargetPlatform.name.toLowerCase();
  final config = profile.firebase[platform];
  if (config == null) {
    throw StateError('${profile.name} の $platform 用Firebase設定がありません。');
  }
  return config;
}
