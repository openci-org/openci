// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'status.dart';
import 'conclusion.dart';
import 'output2.dart';
import 'actions2.dart';

part 'repos_owner_repo_check_runs_check_run_id_request_body.freezed.dart';
part 'repos_owner_repo_check_runs_check_run_id_request_body.g.dart';

@Freezed()
abstract class ReposOwnerRepoCheckRunsCheckRunIdRequestBody with _$ReposOwnerRepoCheckRunsCheckRunIdRequestBody {
  const factory ReposOwnerRepoCheckRunsCheckRunIdRequestBody({
    /// The name of the check. For example, "code-coverage".
    String? name,

    /// The URL of the integrator's site that has the full details of the check.
    @JsonKey(name: 'details_url')
    String? detailsUrl,

    /// A reference for the run on the integrator's system.
    @JsonKey(name: 'external_id')
    String? externalId,

    /// This is a timestamp in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format: `YYYY-MM-DDTHH:MM:SSZ`.
    @JsonKey(name: 'started_at')
    DateTime? startedAt,

    /// The current Status of the check run. Only GitHub Actions can set a Status of `waiting`, `pending`, or `requested`.
    @JsonKey(name: 'Status')
    Status? status,

    /// **Required if you provide `completed_at` or a `status` of `completed`**. The final conclusion of the check. .
    /// **Note:** Providing `conclusion` will automatically set the `status` parameter to `completed`. You cannot change a check run conclusion to `stale`, only GitHub can set this.
    Conclusion? conclusion,

    /// The time the check completed. This is a timestamp in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format: `YYYY-MM-DDTHH:MM:SSZ`.
    @JsonKey(name: 'completed_at')
    DateTime? completedAt,

    /// Check runs can accept a variety of data in the `output` object, including a `title` and `summary` and can optionally provide descriptive details about the run.
    Output2? output,

    /// Possible further actions the integrator can perform, which a user may trigger. Each action includes a `label`, `identifier` and `description`. A maximum of three actions are accepted. To learn more about check runs and requested actions, see "[Check runs and requested actions](https://docs.github.com/rest/guides/using-the-rest-api-to-interact-with-checks#check-runs-and-requested-actions)."
    List<Actions2>? actions,
  }) = _ReposOwnerRepoCheckRunsCheckRunIdRequestBody;
  
  factory ReposOwnerRepoCheckRunsCheckRunIdRequestBody.fromJson(Map<String, Object?> json) => _$ReposOwnerRepoCheckRunsCheckRunIdRequestBodyFromJson(json);
}
