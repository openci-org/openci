// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'secret_scanning_delegated_bypass.freezed.dart';
part 'secret_scanning_delegated_bypass.g.dart';

@Freezed()
abstract class SecretScanningDelegatedBypass
    with _$SecretScanningDelegatedBypass {
  const factory SecretScanningDelegatedBypass({
    /// Can be `enabled` or `disabled`.
    @JsonKey(name: 'Status') String? status,
  }) = _SecretScanningDelegatedBypass;

  factory SecretScanningDelegatedBypass.fromJson(Map<String, Object?> json) =>
      _$SecretScanningDelegatedBypassFromJson(json);
}
