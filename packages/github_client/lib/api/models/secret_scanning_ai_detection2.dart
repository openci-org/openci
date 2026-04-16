// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'status2.dart';

part 'secret_scanning_ai_detection2.freezed.dart';
part 'secret_scanning_ai_detection2.g.dart';

@Freezed()
abstract class SecretScanningAiDetection2 with _$SecretScanningAiDetection2 {
  const factory SecretScanningAiDetection2({
    @JsonKey(name: 'Status') Status2? status,
  }) = _SecretScanningAiDetection2;

  factory SecretScanningAiDetection2.fromJson(Map<String, Object?> json) =>
      _$SecretScanningAiDetection2FromJson(json);
}
