// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_members_bottom_sheet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TeamMember _$TeamMemberFromJson(Map<String, dynamic> json) => _TeamMember(
  uid: json['uid'] as String,
  email: json['email'] as String?,
  displayName: json['displayName'] as String?,
  photoURL: json['photoURL'] as String?,
);

Map<String, dynamic> _$TeamMemberToJson(_TeamMember instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'email': instance.email,
      'displayName': instance.displayName,
      'photoURL': instance.photoURL,
    };

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(teamMembers)
final teamMembersProvider = TeamMembersProvider._();

final class TeamMembersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TeamMember>>,
          List<TeamMember>,
          FutureOr<List<TeamMember>>
        >
    with $FutureModifier<List<TeamMember>>, $FutureProvider<List<TeamMember>> {
  TeamMembersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teamMembersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamMembersHash();

  @$internal
  @override
  $FutureProviderElement<List<TeamMember>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TeamMember>> create(Ref ref) {
    return teamMembers(ref);
  }
}

String _$teamMembersHash() => r'9877d300714aeae7b7e5c573c10e999e89fb09b8';
