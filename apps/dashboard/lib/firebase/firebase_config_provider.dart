import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'firebase_config_provider.freezed.dart';
part 'firebase_config_provider.g.dart';

const _prefKey = 'sh_firebase_config';

@freezed
abstract class SelfHostedConfig with _$SelfHostedConfig {
  const SelfHostedConfig._();

  const factory SelfHostedConfig({
    required String apiKey,
    required String appId,
    @Default('') String messagingSenderId,
    required String projectId,
    @Default('') String storageBucket,
    @Default('') String cloudRunHash,
    @Default('an') String cloudRunRegionCode,
  }) = _SelfHostedConfig;

  factory SelfHostedConfig.fromJson(Map<String, dynamic> json) =>
      _$SelfHostedConfigFromJson(json);

  FirebaseOptions toFirebaseOptions() => FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    storageBucket: storageBucket,
  );
}

Future<SelfHostedConfig?> loadSelfHostedConfig() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_prefKey);
  if (raw == null) return null;
  return SelfHostedConfig.fromJson(
    jsonDecode(raw) as Map<String, dynamic>,
  );
}

Future<void> saveSelfHostedConfig(SelfHostedConfig config) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_prefKey, jsonEncode(config.toJson()));
}

Future<void> clearSelfHostedConfig() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_prefKey);
}

/// Riverpod provider to expose the self-hosted config to UI widgets.
final selfHostedConfigProvider = FutureProvider<SelfHostedConfig?>((ref) {
  return loadSelfHostedConfig();
});
