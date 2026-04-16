// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// Required when using `squash_merge_commit_message`.
///
/// The default value for a squash merge Commit title:.
///
/// - `PR_TITLE` - default to the pull request's title.
/// - `COMMIT_OR_PR_TITLE` - default to the Commit's title (if only one commit) or the pull request's title (when more than one commit).
@JsonEnum()
enum SquashMergeCommitTitle {
  @JsonValue('PR_TITLE')
  prTitle('PR_TITLE'),
  @JsonValue('COMMIT_OR_PR_TITLE')
  commitOrPrTitle('COMMIT_OR_PR_TITLE'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const SquashMergeCommitTitle(this.json);

  factory SquashMergeCommitTitle.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<SquashMergeCommitTitle> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
