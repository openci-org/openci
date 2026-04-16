// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'annotation_level.dart';

part 'annotations2.freezed.dart';
part 'annotations2.g.dart';

@Freezed()
abstract class Annotations2 with _$Annotations2 {
  const factory Annotations2({
    /// The path of the file to add an annotation to. For example, `assets/css/main.css`.
    required String path,

    /// The start line of the annotation. Line numbers start at 1.
    @JsonKey(name: 'start_line') required int startLine,

    /// The end line of the annotation.
    @JsonKey(name: 'end_line') required int endLine,

    /// The level of the annotation.
    @JsonKey(name: 'annotation_level') required AnnotationLevel annotationLevel,

    /// A short description of the feedback for these lines of code. The maximum size is 64 KB.
    required String message,

    /// The start column of the annotation. Annotations only support `start_column` and `end_column` on the same line. Omit this parameter if `start_line` and `end_line` have different values. Column numbers start at 1.
    @JsonKey(name: 'start_column') int? startColumn,

    /// The end column of the annotation. Annotations only support `start_column` and `end_column` on the same line. Omit this parameter if `start_line` and `end_line` have different values.
    @JsonKey(name: 'end_column') int? endColumn,

    /// The title that represents the annotation. The maximum size is 255 characters.
    String? title,

    /// Details about this annotation. The maximum size is 64 KB.
    @JsonKey(name: 'raw_details') String? rawDetails,
  }) = _Annotations2;

  factory Annotations2.fromJson(Map<String, Object?> json) =>
      _$Annotations2FromJson(json);
}
