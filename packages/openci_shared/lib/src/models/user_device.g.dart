// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserDevice _$UserDeviceFromJson(Map<String, dynamic> json) => _UserDevice(
  id: json['id'] as String,
  userId: json['userId'] as String,
  teamId: json['teamId'] as String,
  udid: json['udid'] as String,
  deviceProduct: json['deviceProduct'] as String,
  deviceOsVersion: json['deviceOsVersion'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$UserDeviceToJson(_UserDevice instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'teamId': instance.teamId,
      'udid': instance.udid,
      'deviceProduct': instance.deviceProduct,
      'deviceOsVersion': instance.deviceOsVersion,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
