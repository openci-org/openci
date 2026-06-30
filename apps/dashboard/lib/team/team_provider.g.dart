// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TeamState)
final teamStateProvider = TeamStateProvider._();

final class TeamStateProvider extends $AsyncNotifierProvider<TeamState, Team> {
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

String _$teamStateHash() => r'5539f6264c66208af7662c236106b915cd84ecce';

abstract class _$TeamState extends $AsyncNotifier<Team> {
  FutureOr<Team> build();
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

String _$teamListHash() => r'f8cd3c24137e564cd232e0d0e2009614a360422d';

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
