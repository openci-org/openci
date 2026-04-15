// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'secret_scanning_non_provider_patterns2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SecretScanningNonProviderPatterns2
_$SecretScanningNonProviderPatterns2FromJson(Map<String, dynamic> json) =>
    _SecretScanningNonProviderPatterns2(
      status: json['Status'] == null
          ? null
          : Status2.fromJson(json['Status'] as String),
    );

Map<String, dynamic> _$SecretScanningNonProviderPatterns2ToJson(
  _SecretScanningNonProviderPatterns2 instance,
) => <String, dynamic>{'Status': _$Status2EnumMap[instance.status]};

const _$Status2EnumMap = {
  Status2.enabled: 'enabled',
  Status2.disabled: 'disabled',
  Status2.$unknown: r'$unknown',
};
