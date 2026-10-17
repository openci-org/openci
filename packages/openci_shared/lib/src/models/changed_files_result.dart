import 'package:freezed_annotation/freezed_annotation.dart';

part 'changed_files_result.freezed.dart';
part 'changed_files_result.g.dart';

/// Changed repository paths for the webhook's base and head commits.
///
/// Only [isComplete] results can safely be used to skip CI. An incomplete
/// result has no paths and a [reason]; callers should run CI in that case.
@freezed
abstract class ChangedFilesResult with _$ChangedFilesResult {
  const factory ChangedFilesResult({
    required List<String> paths,
    required bool isComplete,
    String? baseSha,
    String? headSha,
    String? reason,
  }) = _ChangedFilesResult;

  factory ChangedFilesResult.fromJson(Map<String, dynamic> json) =>
      _$ChangedFilesResultFromJson(json);
}
