// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permissions10.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Permissions10 _$Permissions10FromJson(Map<String, dynamic> json) =>
    _Permissions10(
      admin: json['admin'] as bool,
      pull: json['pull'] as bool,
      push: json['push'] as bool,
      triage: json['triage'] as bool?,
      maintain: json['maintain'] as bool?,
    );

Map<String, dynamic> _$Permissions10ToJson(_Permissions10 instance) =>
    <String, dynamic>{
      'admin': instance.admin,
      'pull': instance.pull,
      'push': instance.push,
      'triage': instance.triage,
      'maintain': instance.maintain,
    };
