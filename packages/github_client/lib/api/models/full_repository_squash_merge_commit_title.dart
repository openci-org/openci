// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// The default value for a squash merge Commit title:.
///
/// - `PR_TITLE` - default to the pull request's title.
/// - `COMMIT_OR_PR_TITLE` - default to the Commit's title (if only one commit) or the pull request's title (when more than one commit).
@JsonEnum()
enum FullRepositorySquashMergeCommitTitle {
  @JsonValue('PR_TITLE')
  prTitle('PR_TITLE'),
  @JsonValue('COMMIT_OR_PR_TITLE')
  commitOrPrTitle('COMMIT_OR_PR_TITLE'),
  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const FullRepositorySquashMergeCommitTitle(this.json);

  factory FullRepositorySquashMergeCommitTitle.fromJson(String json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();
  /// Returns all defined enum values excluding the $unknown value.
  static List<FullRepositorySquashMergeCommitTitle> get $valuesDefined => values.where((value) => value != $unknown).toList();
}
