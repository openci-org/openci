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

String _$teamStateHash() => r'51776b84699d46bc3283c9fdc37eb774038b3e73';

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

String _$teamListHash() => r'3ac6c19fa5025fe946b363095864358cd708da62';

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
