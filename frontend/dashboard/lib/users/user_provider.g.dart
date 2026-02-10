// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OpenCIUser _$OpenCIUserFromJson(Map<String, dynamic> json) => _OpenCIUser(
      id: json['id'] as String,
      selectedTeamId: json['selectedTeamId'] as String,
    );

Map<String, dynamic> _$OpenCIUserToJson(_OpenCIUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'selectedTeamId': instance.selectedTeamId,
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
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$userHash();

  @$internal
  @override
  User create() => User();
}

String _$userHash() => r'33365c1e230e8ba3c1862d7bc1a0a16c3d3897fc';

abstract class _$User extends $StreamNotifier<OpenCIUser> {
  Stream<OpenCIUser> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<OpenCIUser>, OpenCIUser>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<OpenCIUser>, OpenCIUser>,
        AsyncValue<OpenCIUser>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
