// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Team _$TeamFromJson(Map<String, dynamic> json) => _Team(
      id: json['id'] as String,
      name: json['name'] as String,
      members:
          (json['members'] as List<dynamic>).map((e) => e as String).toList(),
      installationIds: (json['installationIds'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      createdAt: const DateTimeConverter().fromJson(json['createdAt']),
      updatedAt: const DateTimeConverter().fromJson(json['updatedAt']),
    );

Map<String, dynamic> _$TeamToJson(_Team instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'members': instance.members,
      'installationIds': instance.installationIds,
      'createdAt': const DateTimeConverter().toJson(instance.createdAt),
      'updatedAt': const DateTimeConverter().toJson(instance.updatedAt),
    };

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

String _$teamStateHash() => r'd2e0560c0a1a73211121226b44856ce2209646cb';

abstract class _$TeamState extends $StreamNotifier<Team> {
  Stream<Team> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Team>, Team>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<Team>, Team>,
        AsyncValue<Team>,
        Object?,
        Object?>;
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

String _$teamListHash() => r'5c8b6af5512a36ede5c1697b930c5ccaf2f0756a';

abstract class _$TeamList extends $StreamNotifier<List<Team>> {
  Stream<List<Team>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Team>>, List<Team>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<Team>>, List<Team>>,
        AsyncValue<List<Team>>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
