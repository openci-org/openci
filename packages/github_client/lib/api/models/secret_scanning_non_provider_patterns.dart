// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'secret_scanning_non_provider_patterns.freezed.dart';
part 'secret_scanning_non_provider_patterns.g.dart';

@Freezed()
abstract class SecretScanningNonProviderPatterns with _$SecretScanningNonProviderPatterns {
  const factory SecretScanningNonProviderPatterns({
    /// Can be `enabled` or `disabled`.
    @JsonKey(name: 'Status')
    String? status,
  }) = _SecretScanningNonProviderPatterns;
  
  factory SecretScanningNonProviderPatterns.fromJson(Map<String, Object?> json) => _$SecretScanningNonProviderPatternsFromJson(json);
}
