// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// Required when using `merge_commit_message`.
///
/// The default value for a merge Commit title.
///
/// - `PR_TITLE` - default to the pull request's title.
/// - `MERGE_MESSAGE` - default to the classic title for a merge message (e.g., Merge pull request #123 from branch-name).
@JsonEnum()
enum MergeCommitTitle {
  @JsonValue('PR_TITLE')
  prTitle('PR_TITLE'),
  @JsonValue('MERGE_MESSAGE')
  mergeMessage('MERGE_MESSAGE'),
  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const MergeCommitTitle(this.json);

  factory MergeCommitTitle.fromJson(String json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();
  /// Returns all defined enum values excluding the $unknown value.
  static List<MergeCommitTitle> get $valuesDefined => values.where((value) => value != $unknown).toList();
}
