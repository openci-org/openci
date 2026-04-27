import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'firebase_config_provider.freezed.dart';
part 'firebase_config_provider.g.dart';

const _prefKey = 'sh_firebase_config';
const _profilesPrefKey = 'sh_firebase_configs';
const _activeProjectIdPrefKey = 'sh_firebase_active_project_id';

@freezed
abstract class SelfHostedConfig with _$SelfHostedConfig {
  const SelfHostedConfig._();

  const factory SelfHostedConfig({
    required String apiKey,
    required String appId,
    @Default('') String messagingSenderId,
    required String projectId,
    @Default('') String storageBucket,
    @Default('') String dataConnectServiceId,
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
  final activeProjectId = prefs.getString(_activeProjectIdPrefKey);
  if (activeProjectId != null) {
    final configs = await loadSelfHostedConfigs();
    for (final config in configs) {
      if (config.projectId == activeProjectId) {
        return config;
      }
    }
  }

  final raw = prefs.getString(_prefKey);
  if (raw == null) return null;
  return SelfHostedConfig.fromJson(
    jsonDecode(raw) as Map<String, dynamic>,
  );
}

Future<List<SelfHostedConfig>> loadSelfHostedConfigs() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_profilesPrefKey);
  final configs = <SelfHostedConfig>[];
  if (raw != null) {
    final values = jsonDecode(raw) as List<dynamic>;
    for (final value in values) {
      configs.add(
        SelfHostedConfig.fromJson(value as Map<String, dynamic>),
      );
    }
  }

  final legacyRaw = prefs.getString(_prefKey);
  if (legacyRaw != null) {
    final legacyConfig = SelfHostedConfig.fromJson(
      jsonDecode(legacyRaw) as Map<String, dynamic>,
    );
    final alreadySaved = configs.any(
      (config) => config.projectId == legacyConfig.projectId,
    );
    if (!alreadySaved) {
      configs.add(legacyConfig);
    }
  }

  return configs;
}

Future<void> saveSelfHostedConfig(SelfHostedConfig config) async {
  final prefs = await SharedPreferences.getInstance();
  final configs = await loadSelfHostedConfigs();
  final index = configs.indexWhere(
    (savedConfig) => savedConfig.projectId == config.projectId,
  );
  if (index == -1) {
    configs.add(config);
  } else {
    configs[index] = config;
  }
  await prefs.setString(
    _profilesPrefKey,
    jsonEncode(configs.map((config) => config.toJson()).toList()),
  );
  await prefs.setString(_activeProjectIdPrefKey, config.projectId);
  await prefs.setString(_prefKey, jsonEncode(config.toJson()));
}

Future<void> activateSelfHostedConfig(String projectId) async {
  final prefs = await SharedPreferences.getInstance();
  SelfHostedConfig? config;
  for (final savedConfig in await loadSelfHostedConfigs()) {
    if (savedConfig.projectId == projectId) {
      config = savedConfig;
      break;
    }
  }
  if (config == null) return;

  await prefs.setString(_activeProjectIdPrefKey, config.projectId);
  await prefs.setString(_prefKey, jsonEncode(config.toJson()));
}

Future<void> deleteSelfHostedConfig(String projectId) async {
  final prefs = await SharedPreferences.getInstance();
  final configs = await loadSelfHostedConfigs()
    ..removeWhere((config) => config.projectId == projectId);
  await prefs.setString(
    _profilesPrefKey,
    jsonEncode(configs.map((config) => config.toJson()).toList()),
  );

  final activeProjectId = prefs.getString(_activeProjectIdPrefKey);
  if (activeProjectId == projectId) {
    await clearSelfHostedConfig();
  }
}

Future<void> clearSelfHostedConfig() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_prefKey);
  await prefs.remove(_activeProjectIdPrefKey);
}

/// Riverpod provider to expose the self-hosted config to UI widgets.
final selfHostedConfigProvider = FutureProvider<SelfHostedConfig?>((ref) {
  return loadSelfHostedConfig();
});
