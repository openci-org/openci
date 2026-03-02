// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OpenCIUser _$OpenCIUserFromJson(Map<String, dynamic> json) => _OpenCIUser(
  id: json['id'] as String,
  notificationPreference:
      $enumDecodeNullable(
        _$NotificationPreferenceEnumMap,
        json['notificationPreference'],
      ) ??
      NotificationPreference.all,
  fcmTokens:
      (json['fcmTokens'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$OpenCIUserToJson(_OpenCIUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'notificationPreference':
          _$NotificationPreferenceEnumMap[instance.notificationPreference]!,
      'fcmTokens': instance.fcmTokens,
    };

const _$NotificationPreferenceEnumMap = {
  NotificationPreference.all: 'all',
  NotificationPreference.successOnly: 'successOnly',
  NotificationPreference.failureOnly: 'failureOnly',
  NotificationPreference.none: 'none',
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

String _$userHash() => r'39df0c5bd72ba8fddc4c0e795adf28b22ec845a4';

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
