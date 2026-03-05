import 'package:freezed_annotation/freezed_annotation.dart';

part 'workflow.freezed.dart';
part 'workflow.g.dart';

@Freezed(makeCollectionsUnmodifiable: false)
abstract class Workflow with _$Workflow {
  const factory Workflow({
    required DateTime createdAt,
    required DateTime updatedAt,
    required String documentId,
    required String name,
    required String teamId,
    required WorkflowConfig workflowConfig,
    required List<WorkflowStep> workflowSteps,
    required bool isEditing,
  }) = _Workflow;

  factory Workflow.fromJson(Map<String, Object?> json) =>
      _$WorkflowFromJson(json);
}

@freezed
abstract class WorkflowConfig with _$WorkflowConfig {
  const factory WorkflowConfig({
    required String selectedRepository,
    required String selectedWorkingDirectory,
    required TriggerType selectedTriggerType,
    String? selectedTriggerBranch,
  }) = _WorkflowConfig;
  factory WorkflowConfig.fromJson(Map<String, Object?> json) =>
      _$WorkflowConfigFromJson(json);
}

@Freezed(makeCollectionsUnmodifiable: false)
abstract class WorkflowStep with _$WorkflowStep {
  const factory WorkflowStep({
    required String name,
    @Default('') String command,
    required bool isCompleted,
    @Default([]) List<WorkflowStepRequiredSecret> requiredSecrets,
  }) = _WorkflowStep;
  factory WorkflowStep.fromJson(Map<String, Object?> json) =>
      _$WorkflowStepFromJson(json);
}

@freezed
abstract class WorkflowStepRequiredSecret with _$WorkflowStepRequiredSecret {
  const factory WorkflowStepRequiredSecret({
    required String key,
    required String secretDocumentId,
  }) = _WorkflowStepRequiredSecret;

  factory WorkflowStepRequiredSecret.fromJson(Map<String, Object?> json) =>
      _$WorkflowStepRequiredSecretFromJson(json);
}

enum TriggerType {
  pullRequest,
  push,
  tag,
  release,
  ;

  @override
  toString() {
    switch (this) {
      case TriggerType.pullRequest:
        return 'pullRequest';
      case TriggerType.push:
        return 'push';
      case TriggerType.tag:
        return 'tag';
      case TriggerType.release:
        return 'release';
    }
  }

  static TriggerType fromValue(String value) {
    switch (value) {
      case 'pullRequest':
        return TriggerType.pullRequest;
      case 'push':
        return TriggerType.push;
      case 'tag':
        return TriggerType.tag;
      case 'release':
        return TriggerType.release;
      default:
        throw ArgumentError('Invalid TriggerType value: $value');
    }
  }
}
