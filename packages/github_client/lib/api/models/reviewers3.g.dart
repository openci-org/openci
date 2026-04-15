// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reviewers3.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Reviewers3 _$Reviewers3FromJson(Map<String, dynamic> json) => _Reviewers3(
  reviewerId: (json['reviewer_id'] as num).toInt(),
  reviewerType: ReviewerType.fromJson(json['reviewer_type'] as String),
  mode: json['mode'] == null
      ? Mode.always
      : Mode.fromJson(json['mode'] as String),
);

Map<String, dynamic> _$Reviewers3ToJson(_Reviewers3 instance) =>
    <String, dynamic>{
      'reviewer_id': instance.reviewerId,
      'reviewer_type': _$ReviewerTypeEnumMap[instance.reviewerType]!,
      'mode': _$ModeEnumMap[instance.mode]!,
    };

const _$ReviewerTypeEnumMap = {
  ReviewerType.team: 'TEAM',
  ReviewerType.role: 'ROLE',
  ReviewerType.$unknown: r'$unknown',
};

const _$ModeEnumMap = {
  Mode.always: 'ALWAYS',
  Mode.exempt: 'EXEMPT',
  Mode.$unknown: r'$unknown',
};
