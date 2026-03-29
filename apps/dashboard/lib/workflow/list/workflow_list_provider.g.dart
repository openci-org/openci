// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workflow_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WorkflowList)
final workflowListProvider = WorkflowListProvider._();

final class WorkflowListProvider
    extends $StreamNotifierProvider<WorkflowList, List<Workflow>> {
  WorkflowListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workflowListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workflowListHash();

  @$internal
  @override
  WorkflowList create() => WorkflowList();
}

String _$workflowListHash() => r'bf17df753d7ae8e88adfe6f1bc3d16ed2f28cff2';

abstract class _$WorkflowList extends $StreamNotifier<List<Workflow>> {
  Stream<List<Workflow>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Workflow>>, List<Workflow>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Workflow>>, List<Workflow>>,
              AsyncValue<List<Workflow>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
