// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permissions11.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Permissions11 _$Permissions11FromJson(Map<String, dynamic> json) =>
    _Permissions11(
      admin: json['admin'] as bool,
      push: json['push'] as bool,
      pull: json['pull'] as bool,
      maintain: json['maintain'] as bool?,
      triage: json['triage'] as bool?,
    );

Map<String, dynamic> _$Permissions11ToJson(_Permissions11 instance) =>
    <String, dynamic>{
      'admin': instance.admin,
      'push': instance.push,
      'pull': instance.pull,
      'maintain': instance.maintain,
      'triage': instance.triage,
    };
