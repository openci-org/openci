// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'status2.dart';

part 'secret_scanning_non_provider_patterns2.freezed.dart';
part 'secret_scanning_non_provider_patterns2.g.dart';

@Freezed()
abstract class SecretScanningNonProviderPatterns2 with _$SecretScanningNonProviderPatterns2 {
  const factory SecretScanningNonProviderPatterns2({
    @JsonKey(name: 'Status')
    Status2? status,
  }) = _SecretScanningNonProviderPatterns2;
  
  factory SecretScanningNonProviderPatterns2.fromJson(Map<String, Object?> json) => _$SecretScanningNonProviderPatterns2FromJson(json);
}
