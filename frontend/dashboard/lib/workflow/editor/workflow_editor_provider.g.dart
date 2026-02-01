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
const workflowEditorProvider = WorkflowEditorFamily._();

final class WorkflowEditorProvider
    extends $StreamNotifierProvider<WorkflowEditor, Workflow> {
  const WorkflowEditorProvider._({
    required WorkflowEditorFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workflowEditorProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workflowEditorHash();

  @override
  String toString() {
    return r'workflowEditorProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  WorkflowEditor create() => WorkflowEditor();

  @override
  bool operator ==(Object other) {
    return other is WorkflowEditorProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workflowEditorHash() => r'afc58c7e2f1931954d124a022cd6c1a202825dc7';

final class WorkflowEditorFamily extends $Family
    with
        $ClassFamilyOverride<
          WorkflowEditor,
          AsyncValue<Workflow>,
          Workflow,
          Stream<Workflow>,
          String
        > {
  const WorkflowEditorFamily._()
    : super(
        retry: null,
        name: r'workflowEditorProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkflowEditorProvider call(String workflowId) =>
      WorkflowEditorProvider._(argument: workflowId, from: this);

  @override
  String toString() => r'workflowEditorProvider';
}

abstract class _$WorkflowEditor extends $StreamNotifier<Workflow> {
  late final _$args = ref.$arg as String;
  String get workflowId => _$args;

  Stream<Workflow> build(String workflowId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<AsyncValue<Workflow>, Workflow>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Workflow>, Workflow>,
              AsyncValue<Workflow>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
