// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workflow_editor_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WorkflowEditor)
final workflowEditorProvider = WorkflowEditorFamily._();

final class WorkflowEditorProvider
    extends $AsyncNotifierProvider<WorkflowEditor, WorkflowEditorState> {
  WorkflowEditorProvider._({
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

String _$workflowEditorHash() => r'e7f910162660728c8250d80884a9228c61ea11e8';

final class WorkflowEditorFamily extends $Family
    with
        $ClassFamilyOverride<
          WorkflowEditor,
          AsyncValue<WorkflowEditorState>,
          WorkflowEditorState,
          FutureOr<WorkflowEditorState>,
          String
        > {
  WorkflowEditorFamily._()
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

abstract class _$WorkflowEditor extends $AsyncNotifier<WorkflowEditorState> {
  late final _$args = ref.$arg as String;
  String get workflowId => _$args;

  FutureOr<WorkflowEditorState> build(String workflowId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<WorkflowEditorState>, WorkflowEditorState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<WorkflowEditorState>, WorkflowEditorState>,
              AsyncValue<WorkflowEditorState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
