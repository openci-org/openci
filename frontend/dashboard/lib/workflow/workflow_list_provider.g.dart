// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workflow_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workflowList)
final workflowListProvider = WorkflowListProvider._();

final class WorkflowListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Workflow>>,
          List<Workflow>,
          Stream<List<Workflow>>
        >
    with $FutureModifier<List<Workflow>>, $StreamProvider<List<Workflow>> {
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
  $StreamProviderElement<List<Workflow>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Workflow>> create(Ref ref) {
    return workflowList(ref);
  }
}

String _$workflowListHash() => r'cb431fc5d725b2aeb4fba840416deba8a0561f30';
