import 'dart:async';
import 'dart:convert';

import 'package:dashboard/api/openci_api_client.dart';
import 'package:dashboard/team/team_members_bottom_sheet.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_shared/openci_shared.dart';

void main() {
  late ProviderContainer container;
  late Completer<Team> selectedTeam;
  late List<http.Request> requests;
  late http.Response response;

  http.Response jsonResponse(Map<String, dynamic> body) => http.Response(
    jsonEncode(body),
    200,
    headers: {'content-type': 'application/json'},
  );

  setUp(() {
    selectedTeam = Completer<Team>();
    requests = [];
    response = jsonResponse({'members': []});
    final client = http.runWithClient(
      () => createOpenCIChopperClient(
        baseUrl: 'https://api.example.com',
        tokenProvider: () => 'api-client-token',
      ),
      () => MockClient((request) async {
        requests.add(request);
        return response;
      }),
    );
    addTearDown(client.dispose);
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        selectedTeamProvider.overrideWith((ref) => selectedTeam.future),
        openciApiServiceProvider.overrideWith(
          (ref) async => OpenCIApiService.create(client),
        ),
      ],
    );
    container.listen(selectedTeamProvider, (_, _) {});
  });

  Future<List<TeamMember>> loadMembers() async {
    selectedTeam.complete(
      Team(
        id: 'team-123',
        name: 'Test team',
        members: const ['user-123'],
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    );
    await container.read(selectedTeamProvider.future);
    return container.read(teamMembersProvider.future);
  }

  test('loads members using the shared API URL and token', () async {
    response = jsonResponse({
      'members': [
        {
          'uid': 'user-123',
          'email': 'user@example.com',
          'displayName': 'Test user',
          'photoURL': 'https://example.com/avatar.png',
        },
        {'uid': 'user-456'},
      ],
    });

    final members = await loadMembers();

    expect(requests, hasLength(1));
    expect(requests.single.method, 'GET');
    expect(
      requests.single.url.toString(),
      'https://api.example.com/teams/team-123/members',
    );
    expect(requests.single.headers['Authorization'], 'Bearer api-client-token');
    expect(members.map((member) => member.uid), ['user-123', 'user-456']);
    expect(members.first.email, 'user@example.com');
    expect(members.first.displayName, 'Test user');
    expect(members.first.photoURL, 'https://example.com/avatar.png');
    expect(members.last.email, isNull);
    expect(members.last.displayName, isNull);
    expect(members.last.photoURL, isNull);
  });

  for (final body in <Map<String, dynamic>>[
    {'members': []},
    {},
  ]) {
    test('returns an empty list for $body', () async {
      response = jsonResponse(body);
      expect(await loadMembers(), isEmpty);
    });
  }

  test('preserves the status and response body when the API fails', () async {
    response = http.Response('Team lookup failed', 500);
    await expectLater(
      loadMembers(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Failed to fetch team members: 500 Team lookup failed',
        ),
      ),
    );
  });

  test('does not request members while the selected team is loading', () async {
    expect(await container.read(teamMembersProvider.future), isEmpty);
    expect(requests, isEmpty);
  });
}
