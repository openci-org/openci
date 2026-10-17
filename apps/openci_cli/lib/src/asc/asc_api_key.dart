import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'asc_api_key.freezed.dart';

@Freezed(toStringOverride: false)
abstract class AscApiKey with _$AscApiKey {
  const factory AscApiKey({
    required String keyId,
    required String issuerId,
    required File privateKeyFile,
  }) = _AscApiKey;
}
