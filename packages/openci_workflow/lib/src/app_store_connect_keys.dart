import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_store_connect_keys.freezed.dart';

@Freezed(toStringOverride: false)
abstract class AppStoreConnectKeys with _$AppStoreConnectKeys {
  const factory AppStoreConnectKeys({
    required String issuerId,
    required String keyId,
    required String privateKeyBase64,
  }) = _AppStoreConnectKeys;
}
