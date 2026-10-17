import 'package:freezed_annotation/freezed_annotation.dart';

part 'ios_signing_credentials.freezed.dart';

@Freezed(toStringOverride: false)
abstract class IosSigningCredentials with _$IosSigningCredentials {
  const factory IosSigningCredentials({
    required String issuerId,
    required String keyId,
    required String ascPrivateKeyPath,
    required String certificatePrivateKeyPath,
  }) = _IosSigningCredentials;
}
