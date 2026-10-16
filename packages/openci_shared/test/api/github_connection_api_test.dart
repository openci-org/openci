import 'dart:convert';

import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

void main() {
  late List<http.Request> requests;
  late Object responseBody;
  late int statusCode;
  late String? token;
  late ChopperClient client;
  late OpenCIApiService api;

  setUp(() {
    requests = [];
    responseBody = {};
    statusCode = 200;
    token = 'firebase-id-token';
    client = http.runWithClient(
      () => createOpenCIChopperClient(
        baseUrl: 'https://api.openci.test',
        tokenProvider: () async => token,
        services: [OpenCIApiService.create()],
      ),
      () => MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode(responseBody),
          statusCode,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    api = client.getService<OpenCIApiService>();
  });

  tearDown(() => client.dispose());

  void expectPost(String endpoint) {
    final request = requests.single;
    expect(request.method, 'POST');
    expect(
      request.url,
      Uri.parse('https://api.openci.test/teams/team-1/github/$endpoint'),
    );
    expect(request.headers['Authorization'], 'Bearer firebase-id-token');
    expect(request.headers['content-type'], 'application/json');
    expect(jsonDecode(request.body), {'reference': 'private-reference'});
  }

  test(
    'reads typed session metadata with the reference only in the body',
    () async {
      responseBody = {
        'success': true,
        'session': {
          'teamId': 'team-1',
          'githubUserId': 123,
          'expiresAt': '2026-10-16T12:10:00.000Z',
        },
      };

      final response = await api.getGitHubConnectionSession(
        'team-1',
        'private-reference',
      );

      expectPost('session');
      expect(response.isSuccessful, isTrue);
      expect(response.body!.success, isTrue);
      expect(response.body!.session.teamId, 'team-1');
      expect(response.body!.session.githubUserId, 123);
      expect(
        response.body!.session.expiresAt,
        DateTime.utc(2026, 10, 16, 12, 10),
      );
      expect(response.body!.toJson(), responseBody);
    },
  );

  test('reads typed personal and organization candidates', () async {
    responseBody = {
      'success': true,
      'candidates': [
        {
          'installationId': 100,
          'accountLogin': 'octocat',
          'accountType': 'User',
        },
        {
          'installationId': 200,
          'accountLogin': 'acme',
          'accountType': 'Organization',
        },
      ],
    };

    final response = await api.getGitHubConnectionCandidates(
      'team-1',
      'private-reference',
    );

    expectPost('candidates');
    expect(response.isSuccessful, isTrue);
    expect(response.body!.success, isTrue);
    expect(response.body!.candidates.first.installationId, 100);
    expect(response.body!.candidates.last.accountType, 'Organization');
    expect(response.body!.toJson(), responseBody);
  });

  test(
    'represents no eligible candidates as a successful empty list',
    () async {
      responseBody = {'success': true, 'candidates': []};

      final response = await api.getGitHubConnectionCandidates(
        'team-1',
        'private-reference',
      );

      expect(response.isSuccessful, isTrue);
      expect(response.body!.candidates, isEmpty);
    },
  );

  test(
    'preserves OpenCI authentication failure when the ID token is missing',
    () async {
      token = null;
      statusCode = 401;
      responseBody = {'success': false, 'error': 'Authentication required'};

      final response = await api.getGitHubConnectionSession(
        'team-1',
        'private-reference',
      );

      expect(requests.single.headers, isNot(contains('Authorization')));
      expect(response.statusCode, 401);
      expect(response.body, isNull);
      expect(jsonDecode(response.error as String), responseBody);
    },
  );

  test('preserves an invalid or expired session response', () async {
    statusCode = 403;
    responseBody = {
      'success': false,
      'error': 'Invalid or expired GitHub connection session',
    };

    final response = await api.getGitHubConnectionSession(
      'team-1',
      'private-reference',
    );

    expectPost('session');
    expect(response.statusCode, 403);
    expect(response.body, isNull);
    expect(jsonDecode(response.error as String), responseBody);
  });

  test('preserves the GitHub reauthorization code', () async {
    statusCode = 409;
    responseBody = {
      'success': false,
      'error': 'GitHub reauthorization required',
      'code': 'github_reauthorization_required',
    };

    final response = await api.getGitHubConnectionCandidates(
      'team-1',
      'private-reference',
    );

    expectPost('candidates');
    expect(response.statusCode, 409);
    expect(response.body, isNull);
    expect(jsonDecode(response.error as String), responseBody);
  });

  test('preserves the GitHub permissions code', () async {
    statusCode = 403;
    responseBody = {
      'success': false,
      'error': 'GitHub permissions required',
      'code': 'github_permissions_required',
    };

    final response = await api.getGitHubConnectionCandidates(
      'team-1',
      'private-reference',
    );

    expect(response.statusCode, 403);
    expect(response.body, isNull);
    expect(jsonDecode(response.error as String), responseBody);
  });

  test('preserves the temporary GitHub failure code', () async {
    statusCode = 502;
    responseBody = {
      'success': false,
      'error': 'Failed to fetch GitHub connection candidates',
      'code': 'github_unavailable',
    };

    final response = await api.getGitHubConnectionCandidates(
      'team-1',
      'private-reference',
    );

    expect(response.statusCode, 502);
    expect(response.body, isNull);
    expect(jsonDecode(response.error as String), responseBody);
  });
}
