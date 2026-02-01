// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workflow.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Workflow _$WorkflowFromJson(Map<String, dynamic> json) => _Workflow(
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  documentId: json['documentId'] as String,
  userId: json['userId'] as String,
  name: json['name'] as String,
  workflowConfig: WorkflowConfig.fromJson(
    json['workflowConfig'] as Map<String, dynamic>,
  ),
  workflowSteps: (json['workflowSteps'] as List<dynamic>)
      .map((e) => WorkflowStep.fromJson(e as Map<String, dynamic>))
      .toList(),
  isEditing: json['isEditing'] as bool,
);

Map<String, dynamic> _$WorkflowToJson(_Workflow instance) => <String, dynamic>{
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'documentId': instance.documentId,
  'userId': instance.userId,
  'name': instance.name,
  'workflowConfig': instance.workflowConfig.toJson(),
  'workflowSteps': instance.workflowSteps.map((e) => e.toJson()).toList(),
  'isEditing': instance.isEditing,
};

_WorkflowConfig _$WorkflowConfigFromJson(Map<String, dynamic> json) =>
    _WorkflowConfig(
      selectedRepository: json['selectedRepository'] as String,
      selectedWorkingDirectory: json['selectedWorkingDirectory'] as String,
      selectedTriggerType: $enumDecode(
        _$TriggerTypeEnumMap,
        json['selectedTriggerType'],
      ),
      selectedTriggerBranch: json['selectedTriggerBranch'] as String?,
    );

Map<String, dynamic> _$WorkflowConfigToJson(
  _WorkflowConfig instance,
) => <String, dynamic>{
  'selectedRepository': instance.selectedRepository,
  'selectedWorkingDirectory': instance.selectedWorkingDirectory,
  'selectedTriggerType': _$TriggerTypeEnumMap[instance.selectedTriggerType]!,
  'selectedTriggerBranch': instance.selectedTriggerBranch,
};

const _$TriggerTypeEnumMap = {
  TriggerType.pullRequest: 'pullRequest',
  TriggerType.push: 'push',
  TriggerType.tag: 'tag',
};

_WorkflowStep _$WorkflowStepFromJson(Map<String, dynamic> json) =>
    _WorkflowStep(
      name: json['name'] as String,
      command: json['command'] as String,
      isCompleted: json['isCompleted'] as bool,
      requiredSecrets:
          (json['requiredSecrets'] as List<dynamic>?)
              ?.map(
                (e) => WorkflowStepRequiredSecret.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
    );

Map<String, dynamic> _$WorkflowStepToJson(
  _WorkflowStep instance,
) => <String, dynamic>{
  'name': instance.name,
  'command': instance.command,
  'isCompleted': instance.isCompleted,
  'requiredSecrets': instance.requiredSecrets.map((e) => e.toJson()).toList(),
};

_WorkflowStepRequiredSecret _$WorkflowStepRequiredSecretFromJson(
  Map<String, dynamic> json,
) => _WorkflowStepRequiredSecret(
  key: json['key'] as String,
  secretDocumentId: json['secretDocumentId'] as String,
);

Map<String, dynamic> _$WorkflowStepRequiredSecretToJson(
  _WorkflowStepRequiredSecret instance,
) => <String, dynamic>{
  'key': instance.key,
  'secretDocumentId': instance.secretDocumentId,
};
