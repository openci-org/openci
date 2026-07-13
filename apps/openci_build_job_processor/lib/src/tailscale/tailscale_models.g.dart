// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tailscale_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TailscaleDevice _$TailscaleDeviceFromJson(Map<String, dynamic> json) =>
    _TailscaleDevice(
      os: json['os'] as String?,
      connectedToControl: json['connectedToControl'] as bool?,
      addresses: (json['addresses'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$TailscaleDeviceToJson(_TailscaleDevice instance) =>
    <String, dynamic>{
      'os': instance.os,
      'connectedToControl': instance.connectedToControl,
      'addresses': instance.addresses,
    };

_TailscaleDevicesResponse _$TailscaleDevicesResponseFromJson(
  Map<String, dynamic> json,
) => _TailscaleDevicesResponse(
  devices: (json['devices'] as List<dynamic>?)
      ?.map((e) => TailscaleDevice.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$TailscaleDevicesResponseToJson(
  _TailscaleDevicesResponse instance,
) => <String, dynamic>{'devices': instance.devices};
