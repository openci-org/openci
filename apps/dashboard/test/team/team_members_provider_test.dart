import 'dart:async';

import 'package:dashboard/team/team_members_api.dart';
import 'package:dashboard/team/team_members_bottom_sheet.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Api extends Fake implements TeamMembersApi {
  Future<List<Map<String, dynamic>>> Function(String) load = (_) async => [];
  final requests = <String>[];
  @override
  Future<List<Map<String, dynamic>>> members(String teamId) {
    requests.add(teamId);
    return load(teamId);
  }
}

Team team(String id) => Team(
  id: id,
  name: id,
  members: const ['user'],
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  late ProviderContainer container;
  late Completer<Team> selected;
  late _Api api;
  setUp(() {
    selected = Completer<Team>();
    api = _Api();
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        selectedTeamProvider.overrideWith((ref) => selected.future),
        teamMembersApiProvider.overrideWith((ref) async => api),
      ],
    );
    container.listen(teamMembersProvider, (_, _) {});
  });

  test('loads FSC member profiles and keeps missing Auth accounts', () async {
    api.load = (_) async => [
      {
        'uid': 'user',
        'email': 'user@example.test',
        'displayName': 'User',
        'photoURL': 'https://example.test/avatar',
      },
      {'uid': 'deleted-user'},
    ];
    selected.complete(team('team-1'));
    await container.read(selectedTeamProvider.future);
    final members = await container.read(teamMembersProvider.future);
    expect(api.requests, ['team-1']);
    expect(members.first.email, 'user@example.test');
    expect(members.last.uid, 'deleted-user');
    expect(members.last.email, isNull);
  });

  test('does not request profiles while the team is loading', () async {
    expect(await container.read(teamMembersProvider.future), isEmpty);
    expect(api.requests, isEmpty);
  });

  test('clears the previous result when the selected team changes', () async {
    final old = Completer<List<Map<String, dynamic>>>();
    api.load = (id) => id == 'old'
        ? old.future
        : Future.value([
            {'uid': 'current'},
          ]);
    selected.complete(team('old'));
    await container.read(selectedTeamProvider.future);
    await container.pump();
    selected = Completer<Team>()..complete(team('new'));
    container.invalidate(selectedTeamProvider);
    await container.read(selectedTeamProvider.future);
    expect(
      (await container.read(teamMembersProvider.future)).single.uid,
      'current',
    );
    old.complete([
      {'uid': 'old-private-profile'},
    ]);
    await container.pump();
    expect(
      (await container.read(teamMembersProvider.future)).single.uid,
      'current',
    );
  });

  test('does not turn permission errors into an empty member list', () async {
    api.load = (_) => Future.error(StateError('Team access denied'));
    selected.complete(team('team-1'));
    await container.read(selectedTeamProvider.future);
    await expectLater(
      container.read(teamMembersProvider.future),
      throwsStateError,
    );
  });
}
