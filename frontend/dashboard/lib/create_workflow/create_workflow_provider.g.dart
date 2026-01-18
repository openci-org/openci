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
    );

Map<String, dynamic> _$CreateWorkflowStateToJson(
  _CreateWorkflowState instance,
) => <String, dynamic>{
  'isCreated': instance.isCreated,
  'selectedRepository': instance.selectedRepository,
  'selectedWorkingDirectory': instance.selectedWorkingDirectory,
  'selectedTriggerType': _$TriggerTypeEnumMap[instance.selectedTriggerType]!,
  'selectedTriggerBranch': instance.selectedTriggerBranch,
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

String _$createWorkflowHash() => r'1f4a4e31b1e65c0908ddb4bc6f7c28aab78dc9bc';

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
