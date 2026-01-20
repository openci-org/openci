// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_workflow_provider.dart';

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
  'selectedWorkflowSteps': instance.selectedWorkflowSteps,
};

const _$TriggerTypeEnumMap = {
  TriggerType.pullRequest: 'pullRequest',
  TriggerType.push: 'push',
};

_WorkflowStep _$WorkflowStepFromJson(Map<String, dynamic> json) =>
    _WorkflowStep(
      name: json['name'] as String,
      isCompleted: json['isCompleted'] as bool,
    );

Map<String, dynamic> _$WorkflowStepToJson(_WorkflowStep instance) =>
    <String, dynamic>{
      'name': instance.name,
      'isCompleted': instance.isCompleted,
    };

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CreateWorkflow)
const createWorkflowProvider = CreateWorkflowProvider._();

final class CreateWorkflowProvider
    extends $NotifierProvider<CreateWorkflow, CreateWorkflowState> {
  const CreateWorkflowProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createWorkflowProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createWorkflowHash();

  @$internal
  @override
  CreateWorkflow create() => CreateWorkflow();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CreateWorkflowState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CreateWorkflowState>(value),
    );
  }
}

String _$createWorkflowHash() => r'b4b7ab4db373d07086ea10866ffe5d13482e00ea';

abstract class _$CreateWorkflow extends $Notifier<CreateWorkflowState> {
  CreateWorkflowState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<CreateWorkflowState, CreateWorkflowState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CreateWorkflowState, CreateWorkflowState>,
              CreateWorkflowState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
