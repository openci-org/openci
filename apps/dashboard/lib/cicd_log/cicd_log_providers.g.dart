// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cicd_log_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CicdCommitGroups)
final cicdCommitGroupsProvider = CicdCommitGroupsProvider._();

final class CicdCommitGroupsProvider
    extends $StreamNotifierProvider<CicdCommitGroups, List<CicdCommitGroup>> {
  CicdCommitGroupsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cicdCommitGroupsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cicdCommitGroupsHash();

  @$internal
  @override
  CicdCommitGroups create() => CicdCommitGroups();
}

String _$cicdCommitGroupsHash() => r'827069803b7cb8edbe6fd6af17c4c145ceb13bdc';

abstract class _$CicdCommitGroups
    extends $StreamNotifier<List<CicdCommitGroup>> {
  Stream<List<CicdCommitGroup>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<CicdCommitGroup>>, List<CicdCommitGroup>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<CicdCommitGroup>>,
                List<CicdCommitGroup>
              >,
              AsyncValue<List<CicdCommitGroup>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
