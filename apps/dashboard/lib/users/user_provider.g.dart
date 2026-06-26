// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OpenCIUser _$OpenCIUserFromJson(Map<String, dynamic> json) => _OpenCIUser(
  id: json['id'] as String,
  selectedTeamId: json['selectedTeamId'] as String,
  selectedRepository: json['selectedRepository'] as String?,
  selectedBranch: json['selectedBranch'] as String?,
  teamUdids:
      (json['teamUdids'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const {},
  teamDeviceProducts:
      (json['teamDeviceProducts'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const {},
  teamDeviceOsVersions:
      (json['teamDeviceOsVersions'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const {},
);

Map<String, dynamic> _$OpenCIUserToJson(_OpenCIUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'selectedTeamId': instance.selectedTeamId,
      'selectedRepository': instance.selectedRepository,
      'selectedBranch': instance.selectedBranch,
      'teamUdids': instance.teamUdids,
      'teamDeviceProducts': instance.teamDeviceProducts,
      'teamDeviceOsVersions': instance.teamDeviceOsVersions,
    };

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(User)
final userProvider = UserProvider._();

final class UserProvider extends $StreamNotifierProvider<User, OpenCIUser> {
  UserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userHash();

  @$internal
  @override
  User create() => User();
}

String _$userHash() => r'73bcd21f20c0bd8342027ddbae1ca17c96ea1ede';

abstract class _$User extends $StreamNotifier<OpenCIUser> {
  Stream<OpenCIUser> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<OpenCIUser>, OpenCIUser>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<OpenCIUser>, OpenCIUser>,
              AsyncValue<OpenCIUser>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
