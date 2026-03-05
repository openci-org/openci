// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'initial_workflow_setup_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InitialWorkflowSetupState _$InitialWorkflowSetupStateFromJson(
  Map<String, dynamic> json,
) => _InitialWorkflowSetupState(
  isCreated: json['isCreated'] as bool,
  name: json['name'] as String,
  selectedRepository: json['selectedRepository'] as String,
  selectedWorkingDirectory: json['selectedWorkingDirectory'] as String,
  selectedTriggerType: $enumDecode(
    _$TriggerTypeEnumMap,
    json['selectedTriggerType'],
  ),
  selectedTriggerBranch: json['selectedTriggerBranch'] as String,
);

Map<String, dynamic> _$InitialWorkflowSetupStateToJson(
  _InitialWorkflowSetupState instance,
) => <String, dynamic>{
  'isCreated': instance.isCreated,
  'name': instance.name,
  'selectedRepository': instance.selectedRepository,
  'selectedWorkingDirectory': instance.selectedWorkingDirectory,
  'selectedTriggerType': _$TriggerTypeEnumMap[instance.selectedTriggerType]!,
  'selectedTriggerBranch': instance.selectedTriggerBranch,
};

const _$TriggerTypeEnumMap = {
  TriggerType.pullRequest: 'pullRequest',
  TriggerType.push: 'push',
  TriggerType.tag: 'tag',
  TriggerType.release: 'release',
};

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(InitialWorkflowSetup)
final initialWorkflowSetupProvider = InitialWorkflowSetupProvider._();

final class InitialWorkflowSetupProvider
    extends $NotifierProvider<InitialWorkflowSetup, InitialWorkflowSetupState> {
  InitialWorkflowSetupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'initialWorkflowSetupProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$initialWorkflowSetupHash();

  @$internal
  @override
  InitialWorkflowSetup create() => InitialWorkflowSetup();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InitialWorkflowSetupState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InitialWorkflowSetupState>(value),
    );
  }
}

String _$initialWorkflowSetupHash() =>
    r'919c0235c6ac9c882159f45f149068354a6f51e9';

abstract class _$InitialWorkflowSetup
    extends $Notifier<InitialWorkflowSetupState> {
  InitialWorkflowSetupState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<InitialWorkflowSetupState, InitialWorkflowSetupState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<InitialWorkflowSetupState, InitialWorkflowSetupState>,
              InitialWorkflowSetupState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
