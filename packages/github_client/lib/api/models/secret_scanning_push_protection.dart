// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'secret_scanning_push_protection.freezed.dart';
part 'secret_scanning_push_protection.g.dart';

@Freezed()
abstract class SecretScanningPushProtection
    with _$SecretScanningPushProtection {
  const factory SecretScanningPushProtection({
    /// Can be `enabled` or `disabled`.
    @JsonKey(name: 'Status') String? status,
  }) = _SecretScanningPushProtection;

  factory SecretScanningPushProtection.fromJson(Map<String, Object?> json) =>
      _$SecretScanningPushProtectionFromJson(json);
}
