// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'advanced_security.dart';
import 'code_security.dart';
import 'secret_scanning.dart';
import 'secret_scanning_push_protection.dart';
import 'secret_scanning_ai_detection.dart';
import 'secret_scanning_non_provider_patterns.dart';
import 'secret_scanning_delegated_alert_dismissal.dart';
import 'secret_scanning_delegated_bypass.dart';
import 'secret_scanning_delegated_bypass_options.dart';

part 'security_and_analysis.freezed.dart';
part 'security_and_analysis.g.dart';

@Freezed()
abstract class SecurityAndAnalysis with _$SecurityAndAnalysis {
  const factory SecurityAndAnalysis({
    /// Use the `status` property to enable or disable GitHub Advanced Security for this repository.
    /// For more information, see "[About GitHub Advanced.
    /// Security](/github/getting-started-with-github/learning-about-github/about-github-advanced-security).".
    ///
    /// For standalone Code Scanning or Secret Protection products, this parameter cannot be used.
    @JsonKey(name: 'advanced_security')
    AdvancedSecurity? advancedSecurity,

    /// Use the `status` property to enable or disable GitHub Code Security for this repository.
    @JsonKey(name: 'code_security')
    CodeSecurity? codeSecurity,

    /// Use the `status` property to enable or disable secret scanning for this repository. For more information, see "[About secret scanning](/code-security/secret-security/about-secret-scanning)."
    @JsonKey(name: 'secret_scanning')
    SecretScanning? secretScanning,

    /// Use the `status` property to enable or disable secret scanning push protection for this repository. For more information, see "[Protecting pushes with secret scanning](/code-security/secret-scanning/protecting-pushes-with-secret-scanning)."
    @JsonKey(name: 'secret_scanning_push_protection')
    SecretScanningPushProtection? secretScanningPushProtection,

    /// Use the `status` property to enable or disable secret scanning AI detection for this repository. For more information, see "[Responsible detection of generic secrets with AI](https://docs.github.com/code-security/secret-scanning/using-advanced-secret-scanning-and-push-protection-features/generic-secret-detection/responsible-ai-generic-secrets)."
    @JsonKey(name: 'secret_scanning_ai_detection')
    SecretScanningAiDetection? secretScanningAiDetection,

    /// Use the `status` property to enable or disable secret scanning non-provider patterns for this repository. For more information, see "[Supported secret scanning patterns](/code-security/secret-scanning/introduction/supported-secret-scanning-patterns#supported-secrets)."
    @JsonKey(name: 'secret_scanning_non_provider_patterns')
    SecretScanningNonProviderPatterns? secretScanningNonProviderPatterns,

    /// Use the `status` property to enable or disable secret scanning delegated alert dismissal for this repository.
    @JsonKey(name: 'secret_scanning_delegated_alert_dismissal')
    SecretScanningDelegatedAlertDismissal? secretScanningDelegatedAlertDismissal,

    /// Use the `status` property to enable or disable secret scanning delegated bypass for this repository.
    @JsonKey(name: 'secret_scanning_delegated_bypass')
    SecretScanningDelegatedBypass? secretScanningDelegatedBypass,

    /// Feature options for secret scanning delegated bypass.
    /// This object is only honored when `security_and_analysis.secret_scanning_delegated_bypass.status` is set to `enabled`.
    /// You can send this object in the same request as `secret_scanning_delegated_bypass`, or update just the options in a separate request.
    @JsonKey(name: 'secret_scanning_delegated_bypass_options')
    SecretScanningDelegatedBypassOptions? secretScanningDelegatedBypassOptions,
  }) = _SecurityAndAnalysis;
  
  factory SecurityAndAnalysis.fromJson(Map<String, Object?> json) => _$SecurityAndAnalysisFromJson(json);
}
