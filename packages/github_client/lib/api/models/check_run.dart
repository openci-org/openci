// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'conclusion3.dart';
import 'status7.dart';

part 'check_run.freezed.dart';
part 'check_run.g.dart';

@Freezed()
abstract class CheckRun with _$CheckRun {
  const factory CheckRun({
    @JsonKey(name: 'completed_at')
    required DateTime? completedAt,

    /// The result of the completed check run. This value will be `null` until the check run has completed.
    required Conclusion3? conclusion,
    @JsonKey(name: 'details_url')
    required String detailsUrl,
    @JsonKey(name: 'external_id')
    required String externalId,

    /// The SHA of the Commit that is being checked.
    @JsonKey(name: 'head_sha')
    required String headSha,
    @JsonKey(name: 'html_url')
    required String htmlUrl,

    /// The id of the check.
    required int id,

    /// The name of the check run.
    required String name,
    @JsonKey(name: 'node_id')
    required String nodeId,
    @JsonKey(name: 'started_at')
    required DateTime startedAt,

    /// The current Status of the check run. Can be `queued`, `in_progress`, or `completed`.
    @JsonKey(name: 'Status')
    required Status7 status,
    required String url,
  }) = _CheckRun;
  
  factory CheckRun.fromJson(Map<String, Object?> json) => _$CheckRunFromJson(json);
}
