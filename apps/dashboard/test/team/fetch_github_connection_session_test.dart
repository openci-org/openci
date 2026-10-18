import 'dart:convert';

import 'package:dashboard/team/fetch_github_connection_session.dart';
import 'package:dashboard/team/github_connection_context.dart';
import 'package:dashboard/team/parse_github_connection_return.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_shared/openci_shared.dart';

void main() {
  const context = GitHubConnectionContext(
    profileId: 'self-hosted',
    apiUrl: 'https://ci.example.test',
    userId: 'user-1',
    teamId: 'team-1',
  );
  const reference = 'private-reference';
  final session = GitHubConnectionSession(
    teamId: 'team-1',
    githubUserId: 123,
    expiresAt: DateTime.utc(2026, 10, 17, 12, 10),
  );
  late String apiUrl;
  late List<http.Request> requests;
  late Future<http.Response> Function(http.Request) respond;

  http.Response jsonResponse(Object? body, {int status = 200}) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

  setUp(() {
    apiUrl = context.apiUrl;
    requests = [];
    respond = (_) async => jsonResponse({
      'success': true,
      'session': session.toJson(),
    });
  });

  Future<GitHubConnectionSession> fetch() {
    final client = http.runWithClient(
      () => createOpenCIChopperClient(
        baseUrl: apiUrl,
        tokenProvider: () => 'firebase-id-token',
      ),
      () => MockClient((request) {
        requests.add(request);
        return respond(request);
      }),
    );
    addTearDown(client.dispose);
    return fetchGitHubConnectionSession(
      api: OpenCIApiService.create(client),
      initiatingContext: context,
      reference: reference,
    );
  }

  test(
    'fetches session metadata from the initiating server and team',
    () async {
      expect(await fetch(), session);

      final request = requests.single;
      expect(request.method, 'POST');
      expect(
        request.url,
        Uri.parse('https://ci.example.test/teams/team-1/github/session'),
      );
      expect(request.headers['Authorization'], 'Bearer firebase-id-token');
      expect(jsonDecode(request.body), {'reference': reference});
    },
  );

  test('does not send the reference to a different server', () async {
    apiUrl = 'https://other.example.test';

    await expectLater(fetch(), throwsA(GitHubConnectionReturnError.forbidden));
    expect(requests, isEmpty);
  });

  test('rejects a session response for another team', () async {
    respond = (_) async => jsonResponse({
      'success': true,
      'session': session.copyWith(teamId: 'team-2').toJson(),
    });

    await expectLater(fetch(), throwsA(GitHubConnectionReturnError.forbidden));
  });

  test('rejects an unauthenticated request', () async {
    respond = (_) async => jsonResponse(
      {'success': false, 'error': 'Authentication required'},
      status: 401,
    );

    await expectLater(fetch(), throwsA(GitHubConnectionReturnError.forbidden));
  });

  test('rejects an invalid or expired session', () async {
    respond = (_) async => jsonResponse(
      {'success': false, 'error': 'Invalid or expired session'},
      status: 403,
    );

    await expectLater(fetch(), throwsA(GitHubConnectionReturnError.forbidden));
  });

  test('does not expose server failure details', () async {
    respond = (_) async => jsonResponse({'error': reference}, status: 500);

    await expectLater(
      fetch(),
      throwsA(GitHubConnectionReturnError.connectionFailed),
    );
  });

  test('rejects a response whose success flag is false', () async {
    respond = (_) async => jsonResponse({
      'success': false,
      'session': session.toJson(),
    });

    await expectLater(
      fetch(),
      throwsA(GitHubConnectionReturnError.connectionFailed),
    );
  });

  test('rejects a response without session data', () async {
    respond = (_) async => jsonResponse(null);

    await expectLater(
      fetch(),
      throwsA(GitHubConnectionReturnError.connectionFailed),
    );
  });

  test('does not expose malformed response details', () async {
    respond = (_) async => http.Response(
      '{"private": "$reference"',
      200,
      headers: {'content-type': 'application/json'},
    );

    await expectLater(
      fetch(),
      throwsA(GitHubConnectionReturnError.connectionFailed),
    );
  });

  test('does not expose transport error details', () async {
    respond = (_) async => throw http.ClientException(reference);

    await expectLater(
      fetch(),
      throwsA(GitHubConnectionReturnError.connectionFailed),
    );
  });
}
