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

String _$workflowListHash() => r'4cd083196c9273725adaef99a034af24e6697647';

abstract class _$WorkflowList extends $StreamNotifier<List<Workflow>> {
  Stream<List<Workflow>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Workflow>>, List<Workflow>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<Workflow>>, List<Workflow>>,
        AsyncValue<List<Workflow>>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
