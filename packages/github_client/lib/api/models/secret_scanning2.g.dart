// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'secret_scanning2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SecretScanning2 _$SecretScanning2FromJson(Map<String, dynamic> json) =>
    _SecretScanning2(
      status: json['Status'] == null
          ? null
          : Status2.fromJson(json['Status'] as String),
    );

Map<String, dynamic> _$SecretScanning2ToJson(_SecretScanning2 instance) =>
    <String, dynamic>{'Status': _$Status2EnumMap[instance.status]};

const _$Status2EnumMap = {
  Status2.enabled: 'enabled',
  Status2.disabled: 'disabled',
  Status2.$unknown: r'$unknown',
};
