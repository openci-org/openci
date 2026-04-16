// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// The default value for a merge Commit message.
///
/// - `PR_TITLE` - default to the pull request's title.
/// - `PR_BODY` - default to the pull request's body.
/// - `BLANK` - default to a blank Commit message.
@JsonEnum()
enum FullRepositoryMergeCommitMessage {
  @JsonValue('PR_BODY')
  prBody('PR_BODY'),
  @JsonValue('PR_TITLE')
  prTitle('PR_TITLE'),
  @JsonValue('BLANK')
  blank('BLANK'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const FullRepositoryMergeCommitMessage(this.json);

  factory FullRepositoryMergeCommitMessage.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<FullRepositoryMergeCommitMessage> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
