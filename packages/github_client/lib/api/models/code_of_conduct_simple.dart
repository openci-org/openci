// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'code_of_conduct_simple.freezed.dart';
part 'code_of_conduct_simple.g.dart';

/// Code of Conduct Simple
@Freezed()
abstract class CodeOfConductSimple with _$CodeOfConductSimple {
  const factory CodeOfConductSimple({
    required String url,
    @JsonKey(name: 'Key') required String key,
    required String name,
    @JsonKey(name: 'html_url') required String? htmlUrl,
  }) = _CodeOfConductSimple;

  factory CodeOfConductSimple.fromJson(Map<String, Object?> json) =>
      _$CodeOfConductSimpleFromJson(json);
}
