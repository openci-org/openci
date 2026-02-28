import 'package:freezed_annotation/freezed_annotation.dart';

part 'yaml_workflow.freezed.dart';
part 'yaml_workflow.g.dart';

@freezed
abstract class YamlWorkflow with _$YamlWorkflow {
  const factory YamlWorkflow({
    required String name,
    required YamlWorkflowTrigger on,
    @Default('.') String workingDirectory,
    @Default([]) List<YamlWorkflowStep> steps,
  }) = _YamlWorkflow;

  factory YamlWorkflow.fromJson(Map<String, Object?> json) =>
      _$YamlWorkflowFromJson(json);
}

@freezed
abstract class YamlWorkflowTrigger with _$YamlWorkflowTrigger {
  const factory YamlWorkflowTrigger({
    YamlTriggerConfig? push,
    YamlTriggerConfig? pullRequest,
    bool? tag,
    YamlReleaseTriggerConfig? release,
  }) = _YamlWorkflowTrigger;

  factory YamlWorkflowTrigger.fromJson(Map<String, Object?> json) =>
      _$YamlWorkflowTriggerFromJson(json);
}

@freezed
abstract class YamlTriggerConfig with _$YamlTriggerConfig {
  const factory YamlTriggerConfig({
    @Default([]) List<String> branches,
  }) = _YamlTriggerConfig;

  factory YamlTriggerConfig.fromJson(Map<String, Object?> json) =>
      _$YamlTriggerConfigFromJson(json);
}

@freezed
abstract class YamlReleaseTriggerConfig with _$YamlReleaseTriggerConfig {
  const factory YamlReleaseTriggerConfig({
    @Default(['published']) List<String> types,
  }) = _YamlReleaseTriggerConfig;

  factory YamlReleaseTriggerConfig.fromJson(Map<String, Object?> json) =>
      _$YamlReleaseTriggerConfigFromJson(json);
}

@freezed
abstract class YamlWorkflowStep with _$YamlWorkflowStep {
  const factory YamlWorkflowStep({
    required String name,
    String? run,
    String? uses,
    @Default({}) Map<String, String> withParams,
  }) = _YamlWorkflowStep;

  factory YamlWorkflowStep.fromJson(Map<String, Object?> json) =>
      _$YamlWorkflowStepFromJson(json);
}
