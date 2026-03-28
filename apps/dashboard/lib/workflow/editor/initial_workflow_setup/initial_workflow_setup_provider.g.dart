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
  triggers: Map<String, String?>.from(json['triggers'] as Map),
);

Map<String, dynamic> _$InitialWorkflowSetupStateToJson(
  _InitialWorkflowSetupState instance,
) => <String, dynamic>{
  'isCreated': instance.isCreated,
  'name': instance.name,
  'selectedRepository': instance.selectedRepository,
  'selectedWorkingDirectory': instance.selectedWorkingDirectory,
  'triggers': instance.triggers,
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
    r'08e6cb2947b173b9ead1b0650fccb26de001903d';

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
