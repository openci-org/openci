// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'secret_scanning_ai_detection2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SecretScanningAiDetection2 _$SecretScanningAiDetection2FromJson(
  Map<String, dynamic> json,
) => _SecretScanningAiDetection2(
  status: json['Status'] == null
      ? null
      : Status2.fromJson(json['Status'] as String),
);

Map<String, dynamic> _$SecretScanningAiDetection2ToJson(
  _SecretScanningAiDetection2 instance,
) => <String, dynamic>{'Status': _$Status2EnumMap[instance.status]};

const _$Status2EnumMap = {
  Status2.enabled: 'enabled',
  Status2.disabled: 'disabled',
  Status2.$unknown: r'$unknown',
};
