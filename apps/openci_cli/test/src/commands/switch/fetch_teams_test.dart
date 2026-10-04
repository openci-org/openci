import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:genuineci_cli/src/commands/switch/fetch_teams.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

void main() {
  const token = 'private-team-token';
  late MockClientHandler handler;

  Map<String, dynamic> team(String id, String name) => {
    'id': id,
    'name': name,
    'members': ['user-1'],
    'createdAt': '2026-10-01T00:00:00.000Z',
    'updatedAt': '2026-10-01T00:00:00.000Z',
  };

  http.Response response(Object? body, {int status = 200}) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

  setUp(() {
    handler = (_) async => response([
      team('team-z', 'Beta'),
      team('team-b', 'Alpha'),
      team('team-a', 'Alpha'),
      team('team-ja', '日本語'),
    ]);
  });

  Future<List<Team>> fetch() => http.runWithClient(() async {
    final client = createOpenCIChopperClient(
      baseUrl: 'https://ci.example.com/proxy/',
      tokenProvider: () => token,
      services: [OpenCIApiService.create()],
    );
    try {
      return await fetchTeams(client.getService<OpenCIApiService>());
    } finally {
      client.dispose();
    }
  }, () => MockClient(handler));

  test('fetches typed teams sorted by name, then ID', () async {
    final requests = <http.Request>[];
    final respond = handler;
    handler = (request) async {
      requests.add(request);
      return respond(request);
    };

    final teams = await fetch();

    expect(teams.map((team) => team.id), [
      'team-a',
      'team-b',
      'team-z',
      'team-ja',
    ]);
    expect(teams.first.members, ['user-1']);
    expect(teams.first.createdAt, DateTime.utc(2026, 10, 1));
    final request = requests.single;
    expect(request.method, 'GET');
    expect(request.url.toString(), 'https://ci.example.com/proxy/teams');
    expect(request.headers['authorization'], 'Bearer $token');
    expect(request.body, isEmpty);
  });

  test('returns an empty list for a user without teams', () async {
    handler = (_) async => response([]);

    expect(await fetch(), isEmpty);
  });

  for (final status in [302, 401, 403, 500, 503]) {
    test('rejects HTTP $status before reading candidates', () async {
      handler = (_) async => http.Response('private-response-body', status);

      await expectLater(
        fetch(),
        throwsA(
          isA<TeamsHttpException>().having(
            (error) => error.statusCode,
            'statusCode',
            status,
          ),
        ),
      );
    });
  }

  test('rejects HTTP 204 without a response body', () async {
    handler = (_) async => http.Response('', 204);

    await expectLater(
      fetch(),
      throwsA(
        anyOf(
          isA<TeamsHttpException>(),
          isA<FormatException>(),
          isA<TypeError>(),
        ),
      ),
    );
  });

  for (final id in ['', ' ', '\n\t']) {
    test('rejects a blank team ID: ${jsonEncode(id)}', () async {
      handler = (_) async =>
          response([team('valid', 'Alpha'), team(id, 'Beta')]);

      await expectLater(fetch(), throwsA(isA<FormatException>()));
    });
  }

  for (final (label, body) in <(String, Object?)>[
    ('null response', null),
    ('object response', {'teams': []}),
    ('single team instead of a list', team('team-1', 'Alpha')),
    ('null candidate', [null]),
    ('non-object candidate', ['team-1']),
    (
      'missing ID',
      [
        {...team('team-1', 'Alpha')}..remove('id'),
      ],
    ),
    (
      'null ID',
      [
        {...team('team-1', 'Alpha'), 'id': null},
      ],
    ),
    (
      'non-string ID',
      [
        {...team('team-1', 'Alpha'), 'id': 42},
      ],
    ),
    (
      'invalid name',
      [
        {...team('team-1', 'Alpha'), 'name': null},
      ],
    ),
    (
      'invalid members',
      [
        {
          ...team('team-1', 'Alpha'),
          'members': [42],
        },
      ],
    ),
    (
      'missing timestamp',
      [
        {...team('team-1', 'Alpha')}..remove('createdAt'),
      ],
    ),
    (
      'invalid candidate after a valid one',
      [
        team('team-1', 'Alpha'),
        {'id': 'team-2'},
      ],
    ),
  ]) {
    test('rejects $label without returning partial candidates', () async {
      handler = (_) async => response(body);

      await expectLater(
        fetch(),
        throwsA(anyOf(isA<FormatException>(), isA<TypeError>())),
      );
    });
  }

  test('rejects malformed JSON', () async {
    handler = (_) async => http.Response(
      '{private-response-body',
      200,
      headers: {'content-type': 'application/json'},
    );

    await expectLater(
      fetch(),
      throwsA(anyOf(isA<FormatException>(), isA<TypeError>())),
    );
  });
}
