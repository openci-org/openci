import 'package:freezed_annotation/freezed_annotation.dart';

import 'build_job_plan.dart';
import 'skipped_workflow_plan.dart';

part 'webhook_task_plan.freezed.dart';
part 'webhook_task_plan.g.dart';

@freezed
abstract class WebhookTaskPlan with _$WebhookTaskPlan {
  // ignore: invalid_annotation_target
  @JsonSerializable(
    disallowUnrecognizedKeys: true,
    explicitToJson: true,
    includeIfNull: false,
  )
  const factory WebhookTaskPlan({
    required List<BuildJobPlan> jobs,
    @JsonKey(disallowNullValue: true)
    @Default(<SkippedWorkflowPlan>[])
    List<SkippedWorkflowPlan> skippedWorkflows,
    String? changedFilesFallbackReason,
  }) = _WebhookTaskPlan;

  factory WebhookTaskPlan.fromJson(Map<String, Object?> json) =>
      _$WebhookTaskPlanFromJson(json);
}
