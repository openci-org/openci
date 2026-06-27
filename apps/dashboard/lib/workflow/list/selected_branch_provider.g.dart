// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selected_branch_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SelectedBranch)
final selectedBranchProvider = SelectedBranchProvider._();

final class SelectedBranchProvider
    extends $AsyncNotifierProvider<SelectedBranch, String?> {
  SelectedBranchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedBranchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedBranchHash();

  @$internal
  @override
  SelectedBranch create() => SelectedBranch();
}

String _$selectedBranchHash() => r'7cd970fbb2ab80425bdbc65f0960dcd05c755797';

abstract class _$SelectedBranch extends $AsyncNotifier<String?> {
  FutureOr<String?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<String?>, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<String?>, String?>,
              AsyncValue<String?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
