// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'secret_scanning_push_protection2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SecretScanningPushProtection2 _$SecretScanningPushProtection2FromJson(
  Map<String, dynamic> json,
) => _SecretScanningPushProtection2(
  status: json['Status'] == null
      ? null
      : Status2.fromJson(json['Status'] as String),
);

Map<String, dynamic> _$SecretScanningPushProtection2ToJson(
  _SecretScanningPushProtection2 instance,
) => <String, dynamic>{'Status': _$Status2EnumMap[instance.status]};

const _$Status2EnumMap = {
  Status2.enabled: 'enabled',
  Status2.disabled: 'disabled',
  Status2.$unknown: r'$unknown',
};
