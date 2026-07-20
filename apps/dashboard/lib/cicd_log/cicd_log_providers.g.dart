// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cicd_log_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cicdCommitGroups)
final cicdCommitGroupsProvider = CicdCommitGroupsProvider._();

final class CicdCommitGroupsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CicdCommitGroup>>,
          List<CicdCommitGroup>,
          Stream<List<CicdCommitGroup>>
        >
    with
        $FutureModifier<List<CicdCommitGroup>>,
        $StreamProvider<List<CicdCommitGroup>> {
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
  $StreamProviderElement<List<CicdCommitGroup>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<CicdCommitGroup>> create(Ref ref) {
    return cicdCommitGroups(ref);
  }
}

String _$cicdCommitGroupsHash() => r'dcbd65d22fe8308cb146e7e974541cdf4a4a65a2';
