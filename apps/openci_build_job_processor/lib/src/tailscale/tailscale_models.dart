import 'dart:async';
import 'package:chopper/chopper.dart';
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

class TailscaleJsonConverter extends JsonConverter {
  const TailscaleJsonConverter();

  @override
  FutureOr<Response<BodyType>> convertResponse<BodyType, InnerType>(
    Response response,
  ) async {
    final jsonResponse = await super.convertResponse<dynamic, dynamic>(
      response,
    );
    final body = jsonResponse.body;
    final convertedBody = _convertToType<InnerType>(body);
    return jsonResponse.copyWith<BodyType>(body: convertedBody as BodyType);
  }

  dynamic _convertToType<T>(dynamic json) {
    if (json == null) return null;
    if (T == TailscaleDevicesResponse) {
      return TailscaleDevicesResponse.fromJson(
        Map<String, dynamic>.from(json as Map),
      );
    }
    return json;
  }
}
