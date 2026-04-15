// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'reviewer_type.dart';
import 'mode.dart';

part 'reviewers3.freezed.dart';
part 'reviewers3.g.dart';

@Freezed()
abstract class Reviewers3 with _$Reviewers3 {
  const factory Reviewers3({
    /// The ID of the Team or role selected as a bypass reviewer
    @JsonKey(name: 'reviewer_id')
    required int reviewerId,

    /// The type of the bypass reviewer
    @JsonKey(name: 'reviewer_type')
    required ReviewerType reviewerType,

    /// The bypass mode for the reviewer
    @Default(Mode.always)
    Mode mode,
  }) = _Reviewers3;
  
  factory Reviewers3.fromJson(Map<String, Object?> json) => _$Reviewers3FromJson(json);
}
