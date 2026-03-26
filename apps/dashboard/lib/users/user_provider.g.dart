// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OpenCIUser _$OpenCIUserFromJson(Map<String, dynamic> json) => _OpenCIUser(
  id: json['id'] as String,
  selectedTeamId: json['selectedTeamId'] as String,
  notificationPreference:
      $enumDecodeNullable(
        _$NotificationPreferenceEnumMap,
        json['notificationPreference'],
      ) ??
      NotificationPreference.all,
  fcmTokens:
      (json['fcmTokens'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  selectedRepository: json['selectedRepository'] as String?,
  selectedBranch: json['selectedBranch'] as String?,
);

Map<String, dynamic> _$OpenCIUserToJson(_OpenCIUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'selectedTeamId': instance.selectedTeamId,
      'notificationPreference':
          _$NotificationPreferenceEnumMap[instance.notificationPreference]!,
      'fcmTokens': instance.fcmTokens,
      'selectedRepository': instance.selectedRepository,
      'selectedBranch': instance.selectedBranch,
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

String _$userHash() => r'06f99c619f10902fe12152463656c64636f6cbfc';

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
