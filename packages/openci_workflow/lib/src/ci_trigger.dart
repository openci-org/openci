// The map callbacks retain the original Freezed variant types.
// ignore_for_file: library_private_types_in_public_api

import 'package:freezed_annotation/freezed_annotation.dart';

part 'ci_trigger.freezed.dart';

@Freezed(map: FreezedMapOptions.none, when: FreezedWhenOptions.none)
abstract class CITrigger with _$CITrigger {
  const CITrigger._();

  /// The branch filter for push and pull request triggers; null for releases.
  String? get branch => null;

  /// Changed-file filters apply to push and pull request triggers only.
  List<String>? get paths => null;

  /// Repository-relative patterns to ignore on push and pull request triggers.
  ///
  /// The trigger runs when at least one changed file matches none of these
  /// patterns. Choose either [paths] or [pathsIgnore] for a trigger.
  List<String>? get pathsIgnore => null;

  const factory CITrigger.push({
    required String branch,
    List<String>? paths,
    List<String>? pathsIgnore,
  }) = _PushCITrigger;

  const factory CITrigger.pullRequest({
    required String branch,
    List<String>? paths,
    List<String>? pathsIgnore,
  }) = _PullRequestCITrigger;

  /// Run when a GitHub Release is published, including pre-releases.
  ///
  /// [tag] matches the release's tag name, without `refs/tags/`. `*` matches
  /// any tag. Drafts, edits, and tag pushes do not start this trigger.
  const factory CITrigger.release({@Default('*') String tag}) =
      _ReleaseCITrigger;
}

/// Pattern matching helpers for [CITrigger].
///
/// The `when` callbacks retain their original arguments. Use [map] or the
/// [CITrigger.pathsIgnore] getter to access exclusion patterns.
extension CITriggerPatterns on CITrigger {
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_PushCITrigger value) push,
    required TResult Function(_PullRequestCITrigger value) pullRequest,
    required TResult Function(_ReleaseCITrigger value) release,
  }) => switch (this) {
    _PushCITrigger value => push(value),
    _PullRequestCITrigger value => pullRequest(value),
    _ReleaseCITrigger value => release(value),
    _ => throw StateError('Unexpected subclass'),
  };

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_PushCITrigger value)? push,
    TResult Function(_PullRequestCITrigger value)? pullRequest,
    TResult Function(_ReleaseCITrigger value)? release,
    required TResult Function() orElse,
  }) => switch (this) {
    _PushCITrigger value when push != null => push(value),
    _PullRequestCITrigger value when pullRequest != null => pullRequest(value),
    _ReleaseCITrigger value when release != null => release(value),
    _ => orElse(),
  };

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_PushCITrigger value)? push,
    TResult? Function(_PullRequestCITrigger value)? pullRequest,
    TResult? Function(_ReleaseCITrigger value)? release,
  }) => switch (this) {
    _PushCITrigger value => push?.call(value),
    _PullRequestCITrigger value => pullRequest?.call(value),
    _ReleaseCITrigger value => release?.call(value),
    _ => null,
  };

  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String branch, List<String>? paths) push,
    required TResult Function(String branch, List<String>? paths) pullRequest,
    required TResult Function(String tag) release,
  }) => map(
    push: (value) => push(value.branch, value.paths),
    pullRequest: (value) => pullRequest(value.branch, value.paths),
    release: (value) => release(value.tag),
  );

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String branch, List<String>? paths)? push,
    TResult Function(String branch, List<String>? paths)? pullRequest,
    TResult Function(String tag)? release,
    required TResult Function() orElse,
  }) => maybeMap(
    push: push == null ? null : (value) => push(value.branch, value.paths),
    pullRequest: pullRequest == null
        ? null
        : (value) => pullRequest(value.branch, value.paths),
    release: release == null ? null : (value) => release(value.tag),
    orElse: orElse,
  );

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String branch, List<String>? paths)? push,
    TResult? Function(String branch, List<String>? paths)? pullRequest,
    TResult? Function(String tag)? release,
  }) => mapOrNull(
    push: (value) => push?.call(value.branch, value.paths),
    pullRequest: (value) => pullRequest?.call(value.branch, value.paths),
    release: (value) => release?.call(value.tag),
  );
}
