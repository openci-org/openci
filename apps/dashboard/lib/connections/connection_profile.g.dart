// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ConnectionProfile _$ConnectionProfileFromJson(Map<String, dynamic> json) =>
    _ConnectionProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      apiUrl: json['apiUrl'] as String,
      firebase: (json['firebase'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, SelfHostedConfig.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$ConnectionProfileToJson(_ConnectionProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'apiUrl': instance.apiUrl,
      'firebase': instance.firebase.map((k, e) => MapEntry(k, e.toJson())),
    };
