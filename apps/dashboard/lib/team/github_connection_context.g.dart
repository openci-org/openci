// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_connection_context.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GitHubConnectionContext _$GitHubConnectionContextFromJson(
  Map<String, dynamic> json,
) => _GitHubConnectionContext(
  profileId: json['profileId'] as String,
  apiUrl: json['apiUrl'] as String,
  userId: json['userId'] as String,
  teamId: json['teamId'] as String,
);

Map<String, dynamic> _$GitHubConnectionContextToJson(
  _GitHubConnectionContext instance,
) => <String, dynamic>{
  'profileId': instance.profileId,
  'apiUrl': instance.apiUrl,
  'userId': instance.userId,
  'teamId': instance.teamId,
};
