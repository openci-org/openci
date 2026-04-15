// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'status.dart';
import 'conclusion.dart';
import 'output.dart';
import 'actions.dart';

part 'repos_owner_repo_check_runs_request_body.freezed.dart';
part 'repos_owner_repo_check_runs_request_body.g.dart';

@Freezed()
abstract class ReposOwnerRepoCheckRunsRequestBody with _$ReposOwnerRepoCheckRunsRequestBody {
  const factory ReposOwnerRepoCheckRunsRequestBody({
    /// The name of the check. For example, "code-coverage".
    required String name,

    /// The SHA of the commit.
    @JsonKey(name: 'head_sha')
    required String headSha,

    /// The current Status of the check run. Only GitHub Actions can set a Status of `waiting`, `pending`, or `requested`.
    @JsonKey(name: 'Status')
    @Default(Status.queued)
    Status status,

    /// The URL of the integrator's site that has the full details of the check. If the integrator does not provide this, then the homepage of the GitHub app is used.
    @JsonKey(name: 'details_url')
    String? detailsUrl,

    /// A reference for the run on the integrator's system.
    @JsonKey(name: 'external_id')
    String? externalId,

    /// The time that the check run began. This is a timestamp in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format: `YYYY-MM-DDTHH:MM:SSZ`.
    @JsonKey(name: 'started_at')
    DateTime? startedAt,

    /// **Required if you provide `completed_at` or a `status` of `completed`**. The final conclusion of the check. .
    /// **Note:** Providing `conclusion` will automatically set the `status` parameter to `completed`. You cannot change a check run conclusion to `stale`, only GitHub can set this.
    Conclusion? conclusion,

    /// The time the check completed. This is a timestamp in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format: `YYYY-MM-DDTHH:MM:SSZ`.
    @JsonKey(name: 'completed_at')
    DateTime? completedAt,

    /// Check runs can accept a variety of data in the `output` object, including a `title` and `summary` and can optionally provide descriptive details about the run.
    Output? output,

    /// Displays a button on GitHub that can be clicked to alert your app to do additional tasks. For example, a code linting app can display a button that automatically fixes detected errors. The button created in this object is displayed after the check run completes. When a user clicks the button, GitHub sends the [`check_run.requested_action` webhook](https://docs.github.com/webhooks/event-payloads/#check_run) to your app. Each action includes a `label`, `identifier` and `description`. A maximum of three actions are accepted. To learn more about check runs and requested actions, see "[Check runs and requested actions](https://docs.github.com/rest/guides/using-the-rest-api-to-interact-with-checks#check-runs-and-requested-actions)."
    List<Actions>? actions,
  }) = _ReposOwnerRepoCheckRunsRequestBody;
  
  factory ReposOwnerRepoCheckRunsRequestBody.fromJson(Map<String, Object?> json) => _$ReposOwnerRepoCheckRunsRequestBodyFromJson(json);
}
