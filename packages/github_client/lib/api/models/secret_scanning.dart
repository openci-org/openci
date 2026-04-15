// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'secret_scanning.freezed.dart';
part 'secret_scanning.g.dart';

@Freezed()
abstract class SecretScanning with _$SecretScanning {
  const factory SecretScanning({
    /// Can be `enabled` or `disabled`.
    @JsonKey(name: 'Status')
    String? status,
  }) = _SecretScanning;
  
  factory SecretScanning.fromJson(Map<String, Object?> json) => _$SecretScanningFromJson(json);
}
