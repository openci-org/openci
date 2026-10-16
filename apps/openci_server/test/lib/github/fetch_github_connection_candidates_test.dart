import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_server/github/fetch_github_installations.dart';
import 'package:openci_server/github/verify_github_installation.dart';
import 'package:test/test.dart';

void main() {
  late Map<String, String> environment;
  late Map<String, dynamic> personalInstallation;
  late Map<String, dynamic> organizationInstallation;
  late List<Map<String, dynamic>> installations;
  late Map<String, Map<String, dynamic>> memberships;
  late Future<http.Response> Function(http.Request) respond;
  late List<_TrackingClient> clients;
  late List<http.BaseRequest> requests;

  final membershipFailure = throwsA(
    isA<HttpException>().having(
      (error) => error.message,
      'safe error message',
      'Failed to verify GitHub organization membership',
    ),
  );

  http.Response jsonResponse(Object? data) => http.Response(
    jsonEncode(data),
    HttpStatus.ok,
    headers: {HttpHeaders.contentTypeHeader: 'application/json'},
  );

  setUp(() {
    environment = {
      'GITHUB_APP_ID': '42',
      'GITHUB_API_BASE_URL': 'https://api.github.com',
    };
    personalInstallation = {
      'id': 100,
      'app_id': 42,
      'account': {'id': 123, 'type': 'User', 'login': 'octocat'},
      'suspended_at': null,
    };
    organizationInstallation = {
      'id': 200,
      'app_id': 42,
      'account': {'id': 789, 'type': 'Organization', 'login': 'acme'},
      'suspended_at': null,
    };
    installations = [personalInstallation, organizationInstallation];
    memberships = {
      'acme': {
        'state': 'active',
        'role': 'admin',
        'user': {'id': 123},
        'organization': {'id': 789},
      },
    };
    respond = (request) async {
      if (request.url.path.endsWith('/user')) {
        return jsonResponse({'id': 123, 'login': 'octocat'});
      }
      if (request.url.path.endsWith('/user/installations')) {
        return jsonResponse({
          'total_count': installations.length,
          'installations': installations,
        });
      }
      final membership = memberships[request.url.pathSegments.last];
      if (request.url.path.contains('/user/memberships/orgs/') &&
          membership != null) {
        return jsonResponse(membership);
      }
      fail('Unexpected GitHub request: ${request.url}');
    };
    clients = [];
    requests = [];
  });

  tearDown(() {
    for (final client in clients) {
      client.close();
    }
  });

  Future<List<GitHubInstallation>> fetch({
    Duration membershipTimeout = const Duration(seconds: 10),
  }) => http.runWithClient(
    () => fetchGitHubConnectionCandidates(
      accessToken: 'private-user-token',
      environment: environment,
      membershipTimeout: membershipTimeout,
    ),
    () {
      final client = _TrackingClient(MockClient(respond), requests);
      clients.add(client);
      return client;
    },
  );

  test('returns eligible personal and organization installations', () async {
    installations.add({
      ...organizationInstallation,
      'id': 300,
      'account': {'id': 987, 'type': 'Organization', 'login': 'other-org'},
    });
    memberships['other-org'] = {
      'state': 'active',
      'role': 'admin',
      'user': {'id': 123},
      'organization': {'id': 987},
    };

    final candidates = await fetch();

    expect(candidates.map((candidate) => candidate.id), [100, 200, 300]);
    expect(candidates.map((candidate) => candidate.accountLogin), [
      'octocat',
      'acme',
      'other-org',
    ]);
    expect(candidates.map((candidate) => candidate.accountType), [
      'User',
      'Organization',
      'Organization',
    ]);
    expect(requests.map((request) => request.url.path), [
      '/user',
      '/user/installations',
      '/user/memberships/orgs/acme',
      '/user/memberships/orgs/other-org',
    ]);
    expect(() => candidates.clear(), throwsUnsupportedError);
    expect(clients.every((client) => client.closed), isTrue);
  });

  test(
    'filters other owners, other apps, and suspended installations',
    () async {
      installations.add({
        ...personalInstallation,
        'id': 301,
        'account': {'id': 999, 'type': 'User', 'login': 'octocat'},
      });
      installations.add({
        ...organizationInstallation,
        'id': 302,
        'app_id': 999,
      });
      installations.add({
        ...organizationInstallation,
        'id': 303,
        'suspended_at': '2026-10-16T00:00:00Z',
      });

      final candidates = await fetch();

      expect(candidates.map((candidate) => candidate.id), [100, 200]);
      expect(requests, hasLength(3));
    },
  );

  test(
    'filters an organization where the user is an ordinary member',
    () async {
      memberships['acme']!['role'] = 'member';

      final candidates = await fetch();

      expect(candidates.map((candidate) => candidate.id), [100]);
    },
  );

  test('filters a pending organization admin invitation', () async {
    memberships['acme']!['state'] = 'pending';

    final candidates = await fetch();

    expect(candidates.map((candidate) => candidate.id), [100]);
  });

  test('requires the organization membership to belong to this user', () async {
    memberships['acme']!['user'] = {'id': 999};

    final candidates = await fetch();

    expect(candidates.map((candidate) => candidate.id), [100]);
  });

  test(
    'requires the membership to match the installation organization',
    () async {
      memberships['acme']!['organization'] = {'id': 999};

      final candidates = await fetch();

      expect(candidates.map((candidate) => candidate.id), [100]);
    },
  );

  test('returns an empty list when no installations are accessible', () async {
    installations = [];

    expect(await fetch(), isEmpty);
    expect(requests, hasLength(2));
  });

  test('returns an empty list when all installations are ineligible', () async {
    personalInstallation['account']['id'] = 999;
    memberships['acme']!['role'] = 'member';

    expect(await fetch(), isEmpty);
  });

  test('fetches current authority again on each call', () async {
    expect((await fetch()).map((candidate) => candidate.id), [100, 200]);
    memberships['acme']!['role'] = 'member';

    expect((await fetch()).map((candidate) => candidate.id), [100]);
    expect(requests, hasLength(6));
  });

  test('uses only the operator GitHub API endpoint for all candidates', () async {
    environment['GITHUB_API_BASE_URL'] =
        'https://github.example:8443/prefix/api/v3/';
    organizationInstallation['url'] = 'https://attacker.example/steal';

    expect((await fetch()).map((candidate) => candidate.id), [100, 200]);

    expect(requests.map((request) => request.url.toString()), [
      'https://github.example:8443/prefix/api/v3/user',
      'https://github.example:8443/prefix/api/v3/user/installations?per_page=100&page=1',
      'https://github.example:8443/prefix/api/v3/user/memberships/orgs/acme',
    ]);
    expect(
      requests.every(
        (request) =>
            request.headers[HttpHeaders.authorizationHeader] ==
            'Bearer private-user-token',
      ),
      isTrue,
    );
    expect(requests.every((request) => !request.followRedirects), isTrue);
    expect(clients.every((client) => client.closed), isTrue);
  });

  test('rejects invalid App configuration before making requests', () async {
    environment['GITHUB_APP_ID'] = 'private-invalid-app-id';

    await expectLater(
      fetch(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'safe error message',
          'GITHUB_APP_ID must be a positive integer',
        ),
      ),
    );
    expect(requests, isEmpty);
  });

  test(
    'stops when GitHub rejects the user token without exposing it',
    () async {
      respond = (_) async =>
          http.Response('private-user-token', HttpStatus.unauthorized);

      await expectLater(
        fetch(),
        throwsA(
          isA<HttpException>().having(
            (error) => error.message,
            'safe error message',
            'Failed to fetch GitHub user',
          ),
        ),
      );
      expect(requests, hasLength(1));
      expect(clients.every((client) => client.closed), isTrue);
    },
  );

  test('stops if the installation list cannot be fetched', () async {
    final original = respond;
    respond = (request) async {
      if (request.url.path.endsWith('/installations')) {
        return http.Response(
          'private-user-token',
          HttpStatus.serviceUnavailable,
        );
      }
      return original(request);
    };

    await expectLater(
      fetch(),
      throwsA(
        isA<HttpException>().having(
          (error) => error.message,
          'safe error message',
          'Failed to fetch GitHub installations',
        ),
      ),
    );
    expect(requests, hasLength(2));
    expect(clients.every((client) => client.closed), isTrue);
  });

  test(
    'does not return partial candidates when membership is blocked',
    () async {
      final original = respond;
      respond = (request) async {
        if (request.url.path.contains('/memberships/')) {
          return http.Response('private-user-token', HttpStatus.forbidden);
        }
        return original(request);
      };

      await expectLater(fetch(), membershipFailure);
      expect(clients.every((client) => client.closed), isTrue);
    },
  );

  test(
    'does not return partial candidates for malformed membership JSON',
    () async {
      final original = respond;
      respond = (request) async {
        if (request.url.path.contains('/memberships/')) {
          return http.Response('{"private-user-token', HttpStatus.ok);
        }
        return original(request);
      };

      await expectLater(fetch(), membershipFailure);
      expect(clients.every((client) => client.closed), isTrue);
    },
  );

  test(
    'times out stalled verification without returning partial candidates',
    () async {
      final pending = Completer<http.Response>();
      final original = respond;
      respond = (request) async {
        if (request.url.path.contains('/memberships/')) return pending.future;
        return original(request);
      };
      addTearDown(() => pending.complete(jsonResponse(memberships['acme'])));

      await expectLater(
        fetch(membershipTimeout: const Duration(milliseconds: 20)),
        membershipFailure,
      );

      expect(clients.every((client) => client.closed), isTrue);
    },
  );
}

class _TrackingClient extends http.BaseClient {
  _TrackingClient(this._inner, this.requests);

  final http.Client _inner;
  final List<http.BaseRequest> requests;
  bool closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    requests.add(request);
    return _inner.send(request);
  }

  @override
  void close() {
    closed = true;
    _inner.close();
  }
}
