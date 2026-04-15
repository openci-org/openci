// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'secret_scanning_delegated_bypass2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SecretScanningDelegatedBypass2 _$SecretScanningDelegatedBypass2FromJson(
  Map<String, dynamic> json,
) => _SecretScanningDelegatedBypass2(
  status: json['Status'] == null
      ? null
      : Status2.fromJson(json['Status'] as String),
);

Map<String, dynamic> _$SecretScanningDelegatedBypass2ToJson(
  _SecretScanningDelegatedBypass2 instance,
) => <String, dynamic>{'Status': _$Status2EnumMap[instance.status]};

const _$Status2EnumMap = {
  Status2.enabled: 'enabled',
  Status2.disabled: 'disabled',
  Status2.$unknown: r'$unknown',
};
