// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LumeDiskSize _$LumeDiskSizeFromJson(Map<String, dynamic> json) =>
    _LumeDiskSize(
      allocated: (json['allocated'] as num).toInt(),
      total: (json['total'] as num).toInt(),
    );

Map<String, dynamic> _$LumeDiskSizeToJson(_LumeDiskSize instance) =>
    <String, dynamic>{'allocated': instance.allocated, 'total': instance.total};

_LumeVM _$LumeVMFromJson(Map<String, dynamic> json) => _LumeVM(
  name: json['name'] as String,
  status: json['status'] as String,
  ipAddress: json['ipAddress'] as String?,
  sshAvailable: json['sshAvailable'] as bool?,
  cpuCount: (json['cpuCount'] as num?)?.toInt(),
  memorySize: (json['memorySize'] as num?)?.toInt(),
  display: json['display'] as String?,
  networkMode: json['networkMode'] as String?,
  os: json['os'] as String?,
  locationName: json['locationName'] as String?,
  vncUrl: json['vncUrl'] as String?,
  diskSize: json['diskSize'] == null
      ? null
      : LumeDiskSize.fromJson(json['diskSize'] as Map<String, dynamic>),
);

Map<String, dynamic> _$LumeVMToJson(_LumeVM instance) => <String, dynamic>{
  'name': instance.name,
  'status': instance.status,
  'ipAddress': instance.ipAddress,
  'sshAvailable': instance.sshAvailable,
  'cpuCount': instance.cpuCount,
  'memorySize': instance.memorySize,
  'display': instance.display,
  'networkMode': instance.networkMode,
  'os': instance.os,
  'locationName': instance.locationName,
  'vncUrl': instance.vncUrl,
  'diskSize': instance.diskSize,
};
