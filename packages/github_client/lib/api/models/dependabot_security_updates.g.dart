// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dependabot_security_updates.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DependabotSecurityUpdates _$DependabotSecurityUpdatesFromJson(
  Map<String, dynamic> json,
) => _DependabotSecurityUpdates(
  status: json['Status'] == null
      ? null
      : Status2.fromJson(json['Status'] as String),
);

Map<String, dynamic> _$DependabotSecurityUpdatesToJson(
  _DependabotSecurityUpdates instance,
) => <String, dynamic>{'Status': _$Status2EnumMap[instance.status]};

const _$Status2EnumMap = {
  Status2.enabled: 'enabled',
  Status2.disabled: 'disabled',
  Status2.$unknown: r'$unknown',
};
