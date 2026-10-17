import 'package:freezed_annotation/freezed_annotation.dart';

part 'asc_authentication_status.freezed.dart';

@freezed
abstract class AscAuthenticationStatus with _$AscAuthenticationStatus {
  const factory AscAuthenticationStatus({
    required bool authenticated,
    String? providerName,
    int? providerId,
    String? publicProviderId,
  }) = _AscAuthenticationStatus;
}
