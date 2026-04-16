// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nullable_git_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NullableGitUser _$NullableGitUserFromJson(Map<String, dynamic> json) =>
    _NullableGitUser(
      name: json['name'] as String?,
      email: json['Email'] as String?,
      date: json['date'] == null
          ? null
          : DateTime.parse(json['date'] as String),
    );

Map<String, dynamic> _$NullableGitUserToJson(_NullableGitUser instance) =>
    <String, dynamic>{
      'name': instance.name,
      'Email': instance.email,
      'date': instance.date?.toIso8601String(),
    };
