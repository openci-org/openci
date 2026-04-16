// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'security_and_analysis.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SecurityAndAnalysis _$SecurityAndAnalysisFromJson(
  Map<String, dynamic> json,
) => _SecurityAndAnalysis(
  advancedSecurity: json['advanced_security'] == null
      ? null
      : AdvancedSecurity.fromJson(
          json['advanced_security'] as Map<String, dynamic>,
        ),
  codeSecurity: json['code_security'] == null
      ? null
      : CodeSecurity.fromJson(json['code_security'] as Map<String, dynamic>),
  secretScanning: json['secret_scanning'] == null
      ? null
      : SecretScanning.fromJson(
          json['secret_scanning'] as Map<String, dynamic>,
        ),
  secretScanningPushProtection: json['secret_scanning_push_protection'] == null
      ? null
      : SecretScanningPushProtection.fromJson(
          json['secret_scanning_push_protection'] as Map<String, dynamic>,
        ),
  secretScanningAiDetection: json['secret_scanning_ai_detection'] == null
      ? null
      : SecretScanningAiDetection.fromJson(
          json['secret_scanning_ai_detection'] as Map<String, dynamic>,
        ),
  secretScanningNonProviderPatterns:
      json['secret_scanning_non_provider_patterns'] == null
      ? null
      : SecretScanningNonProviderPatterns.fromJson(
          json['secret_scanning_non_provider_patterns'] as Map<String, dynamic>,
        ),
  secretScanningDelegatedAlertDismissal:
      json['secret_scanning_delegated_alert_dismissal'] == null
      ? null
      : SecretScanningDelegatedAlertDismissal.fromJson(
          json['secret_scanning_delegated_alert_dismissal']
              as Map<String, dynamic>,
        ),
  secretScanningDelegatedBypass:
      json['secret_scanning_delegated_bypass'] == null
      ? null
      : SecretScanningDelegatedBypass.fromJson(
          json['secret_scanning_delegated_bypass'] as Map<String, dynamic>,
        ),
  secretScanningDelegatedBypassOptions:
      json['secret_scanning_delegated_bypass_options'] == null
      ? null
      : SecretScanningDelegatedBypassOptions.fromJson(
          json['secret_scanning_delegated_bypass_options']
              as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$SecurityAndAnalysisToJson(
  _SecurityAndAnalysis instance,
) => <String, dynamic>{
  'advanced_security': instance.advancedSecurity,
  'code_security': instance.codeSecurity,
  'secret_scanning': instance.secretScanning,
  'secret_scanning_push_protection': instance.secretScanningPushProtection,
  'secret_scanning_ai_detection': instance.secretScanningAiDetection,
  'secret_scanning_non_provider_patterns':
      instance.secretScanningNonProviderPatterns,
  'secret_scanning_delegated_alert_dismissal':
      instance.secretScanningDelegatedAlertDismissal,
  'secret_scanning_delegated_bypass': instance.secretScanningDelegatedBypass,
  'secret_scanning_delegated_bypass_options':
      instance.secretScanningDelegatedBypassOptions,
};
