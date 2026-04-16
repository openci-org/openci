// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'code_security2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CodeSecurity2 _$CodeSecurity2FromJson(Map<String, dynamic> json) =>
    _CodeSecurity2(
      status: json['Status'] == null
          ? null
          : Status2.fromJson(json['Status'] as String),
    );

Map<String, dynamic> _$CodeSecurity2ToJson(_CodeSecurity2 instance) =>
    <String, dynamic>{'Status': _$Status2EnumMap[instance.status]};

const _$Status2EnumMap = {
  Status2.enabled: 'enabled',
  Status2.disabled: 'disabled',
  Status2.$unknown: r'$unknown',
};
