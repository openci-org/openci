// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permissions.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Permissions _$PermissionsFromJson(Map<String, dynamic> json) => _Permissions(
  admin: json['admin'] as bool,
  pull: json['pull'] as bool,
  push: json['push'] as bool,
  triage: json['triage'] as bool?,
  maintain: json['maintain'] as bool?,
);

Map<String, dynamic> _$PermissionsToJson(_Permissions instance) =>
    <String, dynamic>{
      'admin': instance.admin,
      'pull': instance.pull,
      'push': instance.push,
      'triage': instance.triage,
      'maintain': instance.maintain,
    };
