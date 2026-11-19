import 'package:freezed_annotation/freezed_annotation.dart';

part 'ci_trigger.freezed.dart';

@freezed
abstract class CITrigger with _$CITrigger {
  const CITrigger._();

  /// The branch filter for push and pull request triggers; null for releases.
  String? get branch => null;

  /// Changed-file filters apply to push and pull request triggers only.
  List<String>? get paths => null;

  const factory CITrigger.push({
    required String branch,
    List<String>? paths,
  }) = _PushCITrigger;

  const factory CITrigger.pullRequest({
    required String branch,
    List<String>? paths,
  }) = _PullRequestCITrigger;

  /// Run when a GitHub Release is published, including pre-releases.
  ///
  /// [tag] matches the release's tag name, without `refs/tags/`. `*` matches
  /// any tag. Drafts, edits, and tag pushes do not start this trigger.
  const factory CITrigger.release({@Default('*') String tag}) =
      _ReleaseCITrigger;
}
