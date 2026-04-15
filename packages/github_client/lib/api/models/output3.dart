// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'output3.freezed.dart';
part 'output3.g.dart';

@Freezed()
abstract class Output3 with _$Output3 {
  const factory Output3({
    required String? title,
    required String? summary,
    required String? text,
    @JsonKey(name: 'annotations_count')
    required int annotationsCount,
    @JsonKey(name: 'annotations_url')
    required String annotationsUrl,
  }) = _Output3;
  
  factory Output3.fromJson(Map<String, Object?> json) => _$Output3FromJson(json);
}
