// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workflow_file_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WorkflowFile _$WorkflowFileFromJson(Map<String, dynamic> json) =>
    _WorkflowFile(
      name: json['name'] as String,
      path: json['path'] as String,
      content: json['content'] as String,
      enabled: json['enabled'] as bool? ?? true,
    );

Map<String, dynamic> _$WorkflowFileToJson(_WorkflowFile instance) =>
    <String, dynamic>{
      'name': instance.name,
      'path': instance.path,
      'content': instance.content,
      'enabled': instance.enabled,
    };

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workflowFiles)
final workflowFilesProvider = WorkflowFilesProvider._();

final class WorkflowFilesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WorkflowFile>>,
          List<WorkflowFile>,
          Stream<List<WorkflowFile>>
        >
    with
        $FutureModifier<List<WorkflowFile>>,
        $StreamProvider<List<WorkflowFile>> {
  WorkflowFilesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workflowFilesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workflowFilesHash();

  @$internal
  @override
  $StreamProviderElement<List<WorkflowFile>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<WorkflowFile>> create(Ref ref) {
    return workflowFiles(ref);
  }
}

String _$workflowFilesHash() => r'2d6edcff2895908d2e6e9bc4b98eaae00b2caf4a';

@ProviderFor(syncWorkflowFiles)
final syncWorkflowFilesProvider = SyncWorkflowFilesProvider._();

final class SyncWorkflowFilesProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  SyncWorkflowFilesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncWorkflowFilesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncWorkflowFilesHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return syncWorkflowFiles(ref);
  }
}

String _$syncWorkflowFilesHash() => r'0a362ecd203c5723383acf9550dd91806a7c1f8a';

@ProviderFor(toggleWorkflowEnabled)
final toggleWorkflowEnabledProvider = ToggleWorkflowEnabledFamily._();

final class ToggleWorkflowEnabledProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  ToggleWorkflowEnabledProvider._({
    required ToggleWorkflowEnabledFamily super.from,
    required ({String fileName, bool enabled}) super.argument,
  }) : super(
         retry: null,
         name: r'toggleWorkflowEnabledProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$toggleWorkflowEnabledHash();

  @override
  String toString() {
    return r'toggleWorkflowEnabledProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as ({String fileName, bool enabled});
    return toggleWorkflowEnabled(
      ref,
      fileName: argument.fileName,
      enabled: argument.enabled,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ToggleWorkflowEnabledProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$toggleWorkflowEnabledHash() =>
    r'78b3bc1d1b153575ece319eed13e293fd2fe8456';

final class ToggleWorkflowEnabledFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<void>,
          ({String fileName, bool enabled})
        > {
  ToggleWorkflowEnabledFamily._()
    : super(
        retry: null,
        name: r'toggleWorkflowEnabledProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ToggleWorkflowEnabledProvider call({
    required String fileName,
    required bool enabled,
  }) => ToggleWorkflowEnabledProvider._(
    argument: (fileName: fileName, enabled: enabled),
    from: this,
  );

  @override
  String toString() => r'toggleWorkflowEnabledProvider';
}
