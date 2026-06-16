// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'environment_variable_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EnvironmentVariable _$EnvironmentVariableFromJson(
  Map<String, dynamic> json,
) => _EnvironmentVariable(
  id: json['id'] as String,
  key: json['key'] as String,
  value: json['value'] as String,
  teamId: json['teamId'] as String,
  autoIncrement: json['autoIncrement'] as bool? ?? false,
  createdAt: const DateTimeConverter().fromJson(json['createdAt'] as Object),
  updatedAt: const DateTimeConverter().fromJson(json['updatedAt'] as Object),
);

Map<String, dynamic> _$EnvironmentVariableToJson(
  _EnvironmentVariable instance,
) => <String, dynamic>{
  'id': instance.id,
  'key': instance.key,
  'value': instance.value,
  'teamId': instance.teamId,
  'autoIncrement': instance.autoIncrement,
  'createdAt': const DateTimeConverter().toJson(instance.createdAt),
  'updatedAt': const DateTimeConverter().toJson(instance.updatedAt),
};

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EnvironmentVariableManager)
final environmentVariableManagerProvider =
    EnvironmentVariableManagerProvider._();

final class EnvironmentVariableManagerProvider
    extends
        $StreamNotifierProvider<
          EnvironmentVariableManager,
          List<EnvironmentVariable>
        > {
  EnvironmentVariableManagerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'environmentVariableManagerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$environmentVariableManagerHash();

  @$internal
  @override
  EnvironmentVariableManager create() => EnvironmentVariableManager();
}

String _$environmentVariableManagerHash() =>
    r'8b8950e9a799914845cde10a612628bbcaa33d00';

abstract class _$EnvironmentVariableManager
    extends $StreamNotifier<List<EnvironmentVariable>> {
  Stream<List<EnvironmentVariable>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<EnvironmentVariable>>,
              List<EnvironmentVariable>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<EnvironmentVariable>>,
                List<EnvironmentVariable>
              >,
              AsyncValue<List<EnvironmentVariable>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
