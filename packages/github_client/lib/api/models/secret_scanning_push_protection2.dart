// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'status2.dart';

part 'secret_scanning_push_protection2.freezed.dart';
part 'secret_scanning_push_protection2.g.dart';

@Freezed()
abstract class SecretScanningPushProtection2 with _$SecretScanningPushProtection2 {
  const factory SecretScanningPushProtection2({
    @JsonKey(name: 'Status')
    Status2? status,
  }) = _SecretScanningPushProtection2;
  
  factory SecretScanningPushProtection2.fromJson(Map<String, Object?> json) => _$SecretScanningPushProtection2FromJson(json);
}
