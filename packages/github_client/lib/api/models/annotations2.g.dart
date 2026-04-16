// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'annotations2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Annotations2 _$Annotations2FromJson(Map<String, dynamic> json) =>
    _Annotations2(
      path: json['path'] as String,
      startLine: (json['start_line'] as num).toInt(),
      endLine: (json['end_line'] as num).toInt(),
      annotationLevel: AnnotationLevel.fromJson(
        json['annotation_level'] as String,
      ),
      message: json['message'] as String,
      startColumn: (json['start_column'] as num?)?.toInt(),
      endColumn: (json['end_column'] as num?)?.toInt(),
      title: json['title'] as String?,
      rawDetails: json['raw_details'] as String?,
    );

Map<String, dynamic> _$Annotations2ToJson(_Annotations2 instance) =>
    <String, dynamic>{
      'path': instance.path,
      'start_line': instance.startLine,
      'end_line': instance.endLine,
      'annotation_level': _$AnnotationLevelEnumMap[instance.annotationLevel]!,
      'message': instance.message,
      'start_column': instance.startColumn,
      'end_column': instance.endColumn,
      'title': instance.title,
      'raw_details': instance.rawDetails,
    };

const _$AnnotationLevelEnumMap = {
  AnnotationLevel.notice: 'notice',
  AnnotationLevel.warning: 'warning',
  AnnotationLevel.failure: 'failure',
  AnnotationLevel.$unknown: r'$unknown',
};
