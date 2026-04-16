// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'nullable_license_simple.freezed.dart';
part 'nullable_license_simple.g.dart';

/// License Simple
@Freezed()
abstract class NullableLicenseSimple with _$NullableLicenseSimple {
  const factory NullableLicenseSimple({
    @JsonKey(name: 'Key') required String key,
    required String name,
    required String? url,
    @JsonKey(name: 'spdx_id') required String? spdxId,
    @JsonKey(name: 'node_id') required String nodeId,
    @JsonKey(name: 'html_url') String? htmlUrl,
  }) = _NullableLicenseSimple;

  factory NullableLicenseSimple.fromJson(Map<String, Object?> json) =>
      _$NullableLicenseSimpleFromJson(json);
}
