// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'advanced_security2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AdvancedSecurity2 _$AdvancedSecurity2FromJson(Map<String, dynamic> json) =>
    _AdvancedSecurity2(
      status: json['Status'] == null
          ? null
          : Status2.fromJson(json['Status'] as String),
    );

Map<String, dynamic> _$AdvancedSecurity2ToJson(_AdvancedSecurity2 instance) =>
    <String, dynamic>{'Status': _$Status2EnumMap[instance.status]};

const _$Status2EnumMap = {
  Status2.enabled: 'enabled',
  Status2.disabled: 'disabled',
  Status2.$unknown: r'$unknown',
};
