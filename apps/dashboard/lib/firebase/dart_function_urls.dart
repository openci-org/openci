import 'package:dashboard/firebase/firebase_config_provider.dart';

/// Default values for the official OpenCI Cloud project.
///
/// Confirmed via:
///   gcloud run services list --region asia-northeast1 --project openci-b1b91
const _defaultProjectHash = 'zmg24bcsaq';
const _defaultRegionCode = 'an'; // asia-northeast1

/// Cached self-hosted config loaded once at startup.
SelfHostedConfig? _cachedSelfHostedConfig;

/// Call this once from [main] after loading the self-hosted config.
void initDartFunctionUrls(SelfHostedConfig? selfHostedConfig) {
  _cachedSelfHostedConfig = selfHostedConfig;
}

/// Returns the Cloud Run HTTPS URL for a Dart Firebase Function.
///
/// Supports two URL formats:
///
/// **Legacy format** (hash-based):
///   `https://<service>-<hash>-<regionCode>.a.run.app`
///   Example: `https://asc-list-apps-zmg24bcsaq-an.a.run.app`
///
/// **New format** (project-number-based):
///   `https://<service>-<projectNumber>.<fullRegion>.run.app`
///   Example: `https://asc-list-apps-186060084322.asia-northeast1.run.app`
///
/// Auto-detects the format based on [cloudRunHash]:
/// - If it is purely numeric → new format (project number).
/// - Otherwise → legacy format (hash + short region code).
///
/// For self-hosted projects, set [cloudRunHash] to the project number
/// (e.g. `186060084322`) and [cloudRunRegionCode] to the full region
/// (e.g. `asia-northeast1`).
String dartFunctionUrl(String serviceName) {
  final hash =
      _cachedSelfHostedConfig?.cloudRunHash.isNotEmpty == true
          ? _cachedSelfHostedConfig!.cloudRunHash
          : _defaultProjectHash;
  final region =
      _cachedSelfHostedConfig?.cloudRunRegionCode.isNotEmpty == true
          ? _cachedSelfHostedConfig!.cloudRunRegionCode
          : _defaultRegionCode;

  // New format: project number is purely numeric.
  final isNewFormat = RegExp(r'^\d+$').hasMatch(hash);

  if (isNewFormat) {
    // https://<service>-<projectNumber>.<fullRegion>.run.app
    return 'https://$serviceName-$hash.$region.run.app';
  } else {
    // https://<service>-<hash>-<regionCode>.a.run.app
    return 'https://$serviceName-$hash-$region.a.run.app';
  }
}

