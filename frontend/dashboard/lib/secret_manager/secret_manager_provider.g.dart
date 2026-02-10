// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'secret_manager_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Secret _$SecretFromJson(Map<String, dynamic> json) => _Secret(
      id: json['id'] as String,
      name: json['name'] as String,
      teamId: json['teamId'] as String,
      pathToSecret: json['pathToSecret'] as String?,
      createdAt: const DateTimeConverter().fromJson(json['createdAt']),
      updatedAt: const DateTimeConverter().fromJson(json['updatedAt']),
    );

Map<String, dynamic> _$SecretToJson(_Secret instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'teamId': instance.teamId,
      'pathToSecret': instance.pathToSecret,
      'createdAt': const DateTimeConverter().toJson(instance.createdAt),
      'updatedAt': const DateTimeConverter().toJson(instance.updatedAt),
    };

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SecretManager)
final secretManagerProvider = SecretManagerProvider._();

final class SecretManagerProvider
    extends $StreamNotifierProvider<SecretManager, List<Secret>> {
  SecretManagerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'secretManagerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$secretManagerHash();

  @$internal
  @override
  SecretManager create() => SecretManager();
}

String _$secretManagerHash() => r'3eefdaa20c152196f709d9b6519eadb649e44aad';

abstract class _$SecretManager extends $StreamNotifier<List<Secret>> {
  Stream<List<Secret>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Secret>>, List<Secret>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<Secret>>, List<Secret>>,
        AsyncValue<List<Secret>>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
