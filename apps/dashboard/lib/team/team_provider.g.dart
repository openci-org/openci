// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(selectedTeam)
final selectedTeamProvider = SelectedTeamProvider._();

final class SelectedTeamProvider
    extends $FunctionalProvider<AsyncValue<Team>, Team, FutureOr<Team>>
    with $FutureModifier<Team>, $FutureProvider<Team> {
  SelectedTeamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedTeamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedTeamHash();

  @$internal
  @override
  $FutureProviderElement<Team> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Team> create(Ref ref) {
    return selectedTeam(ref);
  }
}

String _$selectedTeamHash() => r'd4dac19c287248adf4836bc1ff536af33c1f5849';

@ProviderFor(teamList)
final teamListProvider = TeamListProvider._();

final class TeamListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Team>>,
          List<Team>,
          FutureOr<List<Team>>
        >
    with $FutureModifier<List<Team>>, $FutureProvider<List<Team>> {
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
  $FutureProviderElement<List<Team>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Team>> create(Ref ref) {
    return teamList(ref);
  }
}

String _$teamListHash() => r'0cce5ff0dd3b0b799e2d4ad521a1b55fbd2691af';

@ProviderFor(teamService)
final teamServiceProvider = TeamServiceProvider._();

final class TeamServiceProvider
    extends $FunctionalProvider<TeamService, TeamService, TeamService>
    with $Provider<TeamService> {
  TeamServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teamServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamServiceHash();

  @$internal
  @override
  $ProviderElement<TeamService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TeamService create(Ref ref) {
    return teamService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TeamService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TeamService>(value),
    );
  }
}

String _$teamServiceHash() => r'c7af76967284024376f59e5774e81dcb21801bf8';
