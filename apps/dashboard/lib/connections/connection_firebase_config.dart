import 'package:dashboard/utilities/error_message.dart';
import 'package:flutter/foundation.dart';

import '../firebase/firebase_config_provider.dart';
import 'connection_profile.dart';

SelfHostedConfig firebaseConfigForCurrentPlatform(ConnectionProfile profile) {
  final platform = kIsWeb ? 'web' : defaultTargetPlatform.name.toLowerCase();
  final config = profile.firebase[platform];
  if (config == null) {
    throw DashboardException(
      'connection_platform_missing',
      name: profile.name,
      platform: platform,
    );
  }
  return config;
}
