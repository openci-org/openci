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
/// When running against a self-hosted project, the project hash and region
/// code are taken from the persisted [SelfHostedConfig].
/// Otherwise the official OpenCI Cloud defaults are used.
///
/// [serviceName] is the kebab-case name as shown in `gcloud run services list`.
/// Example: `dartFunctionUrl('asc-list-apps')`
///   → `https://asc-list-apps-zmg24bcsaq-an.a.run.app`
String dartFunctionUrl(String serviceName) {
  final hash =
      _cachedSelfHostedConfig?.cloudRunHash.isNotEmpty == true
          ? _cachedSelfHostedConfig!.cloudRunHash
          : _defaultProjectHash;
  final region =
      _cachedSelfHostedConfig?.cloudRunRegionCode.isNotEmpty == true
          ? _cachedSelfHostedConfig!.cloudRunRegionCode
          : _defaultRegionCode;
  return 'https://$serviceName-$hash-$region.a.run.app';
}
