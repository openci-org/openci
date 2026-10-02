import 'package:json_annotation/json_annotation.dart';

part 'changed_files_result.g.dart';

/// Changed repository paths for the webhook's base and head commits.
///
/// Only [isComplete] results can safely be used to skip CI. An incomplete
/// result has no paths and a [reason]; callers should run CI in that case.
@JsonSerializable()
class ChangedFilesResult {
  const ChangedFilesResult({
    required this.paths,
    required this.isComplete,
    this.baseSha,
    this.headSha,
    this.reason,
  });

  factory ChangedFilesResult.fromJson(Map<String, dynamic> json) =>
      _$ChangedFilesResultFromJson(json);

  final List<String> paths;
  final String? baseSha;
  final String? headSha;
  final bool isComplete;
  final String? reason;

  Map<String, dynamic> toJson() => _$ChangedFilesResultToJson(this);
}
