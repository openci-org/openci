import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_device.freezed.dart';
part 'user_device.g.dart';

@freezed
abstract class UserDevice with _$UserDevice {
  const factory UserDevice({
    required String id,
    required String userId,
    required String teamId,
    required String udid,
    required String deviceProduct,
    required String deviceOsVersion,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _UserDevice;

  factory UserDevice.fromJson(Map<String, Object?> json) =>
      _$UserDeviceFromJson(json);
}
