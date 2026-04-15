// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'status2.dart';

part 'secret_scanning_delegated_bypass2.freezed.dart';
part 'secret_scanning_delegated_bypass2.g.dart';

@Freezed()
abstract class SecretScanningDelegatedBypass2 with _$SecretScanningDelegatedBypass2 {
  const factory SecretScanningDelegatedBypass2({
    @JsonKey(name: 'Status')
    Status2? status,
  }) = _SecretScanningDelegatedBypass2;
  
  factory SecretScanningDelegatedBypass2.fromJson(Map<String, Object?> json) => _$SecretScanningDelegatedBypass2FromJson(json);
}
