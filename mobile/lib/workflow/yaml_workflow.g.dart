// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yaml_workflow.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_YamlWorkflow _$YamlWorkflowFromJson(Map<String, dynamic> json) =>
    _YamlWorkflow(
      name: json['name'] as String,
      on: YamlWorkflowTrigger.fromJson(json['on'] as Map<String, dynamic>),
      workingDirectory: json['workingDirectory'] as String? ?? '.',
      steps:
          (json['steps'] as List<dynamic>?)
              ?.map((e) => YamlWorkflowStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$YamlWorkflowToJson(_YamlWorkflow instance) =>
    <String, dynamic>{
      'name': instance.name,
      'on': instance.on.toJson(),
      'workingDirectory': instance.workingDirectory,
      'steps': instance.steps.map((e) => e.toJson()).toList(),
    };

_YamlWorkflowTrigger _$YamlWorkflowTriggerFromJson(Map<String, dynamic> json) =>
    _YamlWorkflowTrigger(
      push: json['push'] == null
          ? null
          : YamlTriggerConfig.fromJson(json['push'] as Map<String, dynamic>),
      pullRequest: json['pullRequest'] == null
          ? null
          : YamlTriggerConfig.fromJson(
              json['pullRequest'] as Map<String, dynamic>,
            ),
      tag: json['tag'] as bool?,
      release: json['release'] == null
          ? null
          : YamlReleaseTriggerConfig.fromJson(
              json['release'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$YamlWorkflowTriggerToJson(
  _YamlWorkflowTrigger instance,
) => <String, dynamic>{
  'push': instance.push?.toJson(),
  'pullRequest': instance.pullRequest?.toJson(),
  'tag': instance.tag,
  'release': instance.release?.toJson(),
};

_YamlTriggerConfig _$YamlTriggerConfigFromJson(Map<String, dynamic> json) =>
    _YamlTriggerConfig(
      branches:
          (json['branches'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$YamlTriggerConfigToJson(_YamlTriggerConfig instance) =>
    <String, dynamic>{'branches': instance.branches};

_YamlReleaseTriggerConfig _$YamlReleaseTriggerConfigFromJson(
  Map<String, dynamic> json,
) => _YamlReleaseTriggerConfig(
  types:
      (json['types'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const ['published'],
);

Map<String, dynamic> _$YamlReleaseTriggerConfigToJson(
  _YamlReleaseTriggerConfig instance,
) => <String, dynamic>{'types': instance.types};

_YamlWorkflowStep _$YamlWorkflowStepFromJson(Map<String, dynamic> json) =>
    _YamlWorkflowStep(
      name: json['name'] as String,
      run: json['run'] as String?,
      uses: json['uses'] as String?,
      withParams:
          (json['withParams'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$YamlWorkflowStepToJson(_YamlWorkflowStep instance) =>
    <String, dynamic>{
      'name': instance.name,
      'run': instance.run,
      'uses': instance.uses,
      'withParams': instance.withParams,
    };
