// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_members_bottom_sheet.dart';

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

String _$teamMembersHash() => r'091ba220b653ff780a4965844844ab9fb7aea51f';
