// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workflow_editor_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CreateWorkflowState _$CreateWorkflowStateFromJson(Map<String, dynamic> json) =>
    _CreateWorkflowState(
      isCreated: json['isCreated'] as bool,
      selectedRepository: json['selectedRepository'] as String,
      selectedWorkingDirectory: json['selectedWorkingDirectory'] as String,
      selectedTriggerType: $enumDecode(
        _$TriggerTypeEnumMap,
        json['selectedTriggerType'],
      ),
      selectedTriggerBranch: json['selectedTriggerBranch'] as String,
      selectedWorkflowSteps: (json['selectedWorkflowSteps'] as List<dynamic>)
          .map((e) => WorkflowStep.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CreateWorkflowStateToJson(
  _CreateWorkflowState instance,
) => <String, dynamic>{
  'isCreated': instance.isCreated,
  'selectedRepository': instance.selectedRepository,
  'selectedWorkingDirectory': instance.selectedWorkingDirectory,
  'selectedTriggerType': _$TriggerTypeEnumMap[instance.selectedTriggerType]!,
  'selectedTriggerBranch': instance.selectedTriggerBranch,
  'selectedWorkflowSteps': instance.selectedWorkflowSteps
      .map((e) => e.toJson())
      .toList(),
};

const _$TriggerTypeEnumMap = {
  TriggerType.pullRequest: 'pullRequest',
  TriggerType.push: 'push',
};

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WorkflowEditor)
const workflowEditorProvider = WorkflowEditorProvider._();

final class WorkflowEditorProvider
    extends $StreamNotifierProvider<WorkflowEditor, Workflow?> {
  const WorkflowEditorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workflowEditorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workflowEditorHash();

  @$internal
  @override
  WorkflowEditor create() => WorkflowEditor();
}

String _$workflowEditorHash() => r'abb0095501718aec23e612226da72a82ad93bc9c';

abstract class _$WorkflowEditor extends $StreamNotifier<Workflow?> {
  Stream<Workflow?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<Workflow?>, Workflow?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Workflow?>, Workflow?>,
              AsyncValue<Workflow?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
