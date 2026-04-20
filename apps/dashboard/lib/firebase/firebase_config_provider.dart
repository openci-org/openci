import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys used to persist a self-hosted Firebase configuration.
const _keyApiKey = 'sh_firebase_api_key';
const _keyAppId = 'sh_firebase_app_id';
const _keyMessagingSenderId = 'sh_firebase_messaging_sender_id';
const _keyProjectId = 'sh_firebase_project_id';
const _keyStorageBucket = 'sh_firebase_storage_bucket';
const _keyCloudRunHash = 'sh_cloud_run_hash';
const _keyCloudRunRegionCode = 'sh_cloud_run_region_code';

/// The Firebase app name used for self-hosted instances.
const selfHostedAppName = 'self-hosted';

/// Lightweight value class holding every field needed to initialise
/// a self-hosted Firebase project from the dashboard.
class SelfHostedConfig {
  const SelfHostedConfig({
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    required this.projectId,
    required this.storageBucket,
    required this.cloudRunHash,
    required this.cloudRunRegionCode,
  });

  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String projectId;
  final String storageBucket;
  final String cloudRunHash;
  final String cloudRunRegionCode;

  FirebaseOptions toFirebaseOptions() => FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    storageBucket: storageBucket,
  );
}

/// Reads a previously-saved self-hosted configuration from disk.
/// Returns `null` when running against the official OpenCI Cloud project.
Future<SelfHostedConfig?> loadSelfHostedConfig() async {
  final prefs = await SharedPreferences.getInstance();
  final apiKey = prefs.getString(_keyApiKey);
  final appId = prefs.getString(_keyAppId);
  final senderId = prefs.getString(_keyMessagingSenderId);
  final projectId = prefs.getString(_keyProjectId);
  final bucket = prefs.getString(_keyStorageBucket);
  final hash = prefs.getString(_keyCloudRunHash);
  final regionCode = prefs.getString(_keyCloudRunRegionCode);

  if (apiKey == null || appId == null || projectId == null) return null;

  return SelfHostedConfig(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: senderId ?? '',
    projectId: projectId,
    storageBucket: bucket ?? '',
    cloudRunHash: hash ?? '',
    cloudRunRegionCode: regionCode ?? 'an',
  );
}

/// Persists a self-hosted configuration to disk.
Future<void> saveSelfHostedConfig(SelfHostedConfig config) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_keyApiKey, config.apiKey);
  await prefs.setString(_keyAppId, config.appId);
  await prefs.setString(_keyMessagingSenderId, config.messagingSenderId);
  await prefs.setString(_keyProjectId, config.projectId);
  await prefs.setString(_keyStorageBucket, config.storageBucket);
  await prefs.setString(_keyCloudRunHash, config.cloudRunHash);
  await prefs.setString(_keyCloudRunRegionCode, config.cloudRunRegionCode);
}

/// Removes all self-hosted configuration from disk.
Future<void> clearSelfHostedConfig() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_keyApiKey);
  await prefs.remove(_keyAppId);
  await prefs.remove(_keyMessagingSenderId);
  await prefs.remove(_keyProjectId);
  await prefs.remove(_keyStorageBucket);
  await prefs.remove(_keyCloudRunHash);
  await prefs.remove(_keyCloudRunRegionCode);
}

/// Returns `true` when a self-hosted Firebase app is currently initialised.
bool get isSelfHosted =>
    Firebase.apps.any((app) => app.name == selfHostedAppName);
