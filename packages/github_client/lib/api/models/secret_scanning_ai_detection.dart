// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'secret_scanning_ai_detection.freezed.dart';
part 'secret_scanning_ai_detection.g.dart';

@Freezed()
abstract class SecretScanningAiDetection with _$SecretScanningAiDetection {
  const factory SecretScanningAiDetection({
    /// Can be `enabled` or `disabled`.
    @JsonKey(name: 'Status')
    String? status,
  }) = _SecretScanningAiDetection;
  
  factory SecretScanningAiDetection.fromJson(Map<String, Object?> json) => _$SecretScanningAiDetectionFromJson(json);
}
