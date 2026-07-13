import 'package:freezed_annotation/freezed_annotation.dart' hide JsonConverter;

part 'tailscale_models.freezed.dart';
part 'tailscale_models.g.dart';

@freezed
abstract class TailscaleDevice with _$TailscaleDevice {
  const factory TailscaleDevice({
    required String? os,
    required bool? connectedToControl,
    required List<String>? addresses,
  }) = _TailscaleDevice;

  factory TailscaleDevice.fromJson(Map<String, dynamic> json) =>
      _$TailscaleDeviceFromJson(json);
}

@freezed
abstract class TailscaleDevicesResponse with _$TailscaleDevicesResponse {
  const factory TailscaleDevicesResponse({
    required List<TailscaleDevice>? devices,
  }) = _TailscaleDevicesResponse;

  factory TailscaleDevicesResponse.fromJson(Map<String, dynamic> json) =>
      _$TailscaleDevicesResponseFromJson(json);
}
