// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'secret_manager_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Secret _$SecretFromJson(Map<String, dynamic> json) => _Secret(
  id: json['id'] as String,
  name: json['name'] as String,
  userId: json['userId'] as String,
  pathToSecret: json['pathToSecret'] as String?,
  createdAt: const TimestampConverter().fromJson(json['createdAt']),
  updatedAt: const TimestampConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$SecretToJson(_Secret instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'userId': instance.userId,
  'pathToSecret': instance.pathToSecret,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'updatedAt': const TimestampConverter().toJson(instance.updatedAt),
};

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SecretManager)
final secretManagerProvider = SecretManagerProvider._();

final class SecretManagerProvider
    extends $StreamNotifierProvider<SecretManager, dynamic> {
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

String _$secretManagerHash() => r'7d98d55b03953001844c0e43fb08e59730b74254';

abstract class _$SecretManager extends $StreamNotifier<dynamic> {
  Stream<dynamic> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<dynamic>, dynamic>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<dynamic>, dynamic>,
              AsyncValue<dynamic>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
