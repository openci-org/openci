// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TeamState)
final teamStateProvider = TeamStateProvider._();

final class TeamStateProvider extends $StreamNotifierProvider<TeamState, Team> {
  TeamStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teamStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamStateHash();

  @$internal
  @override
  TeamState create() => TeamState();
}

String _$teamStateHash() => r'cb89fa7e22f8e2268f64d2469c18ee52c5bf0477';

abstract class _$TeamState extends $StreamNotifier<Team> {
  Stream<Team> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Team>, Team>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Team>, Team>,
              AsyncValue<Team>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(TeamList)
final teamListProvider = TeamListProvider._();

final class TeamListProvider
    extends $StreamNotifierProvider<TeamList, List<Team>> {
  TeamListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teamListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamListHash();

  @$internal
  @override
  TeamList create() => TeamList();
}

String _$teamListHash() => r'ff9f4c8705193a1bc48f00189d1473f85eb76faf';

abstract class _$TeamList extends $StreamNotifier<List<Team>> {
  Stream<List<Team>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Team>>, List<Team>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Team>>, List<Team>>,
              AsyncValue<List<Team>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
