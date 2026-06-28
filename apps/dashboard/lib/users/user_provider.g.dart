// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OpenCIUser _$OpenCIUserFromJson(Map<String, dynamic> json) =>
    _OpenCIUser(id: json['id'] as String);

Map<String, dynamic> _$OpenCIUserToJson(_OpenCIUser instance) =>
    <String, dynamic>{'id': instance.id};

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

String _$userHash() => r'8077201c08ee9c11c1ddd681725e2e354e5fdabf';

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

@ProviderFor(UserDevices)
final userDevicesProvider = UserDevicesProvider._();

final class UserDevicesProvider
    extends $StreamNotifierProvider<UserDevices, List<UserDevice>> {
  UserDevicesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userDevicesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userDevicesHash();

  @$internal
  @override
  UserDevices create() => UserDevices();
}

String _$userDevicesHash() => r'12cf9fc6eb9a6131fa3a8b53b8c0bc406d04d6b8';

abstract class _$UserDevices extends $StreamNotifier<List<UserDevice>> {
  Stream<List<UserDevice>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<UserDevice>>, List<UserDevice>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<UserDevice>>, List<UserDevice>>,
              AsyncValue<List<UserDevice>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
