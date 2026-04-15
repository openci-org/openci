// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'parents.freezed.dart';
part 'parents.g.dart';

@Freezed()
abstract class Parents with _$Parents {
  const factory Parents({
    required String sha,
    required String url,
    @JsonKey(name: 'html_url')
    String? htmlUrl,
  }) = _Parents;
  
  factory Parents.fromJson(Map<String, Object?> json) => _$ParentsFromJson(json);
}
