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
  late Map<String, dynamic> user;
  late Map<String, dynamic> installation;
  late List<Map<String, dynamic>> installations;
  late Map<String, dynamic> membership;
  late Future<http.Response> Function(http.Request) respond;
  late List<_TrackingClient> clients;
  late List<http.BaseRequest> requests;

  final membershipFailure = throwsA(
    isA<HttpException>().having(
      (error) => error.toString(),
      'safe error message',
      'HttpException: Failed to verify GitHub organization membership',
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
    user = {'id': 123, 'login': 'octocat'};
    installation = {
      'id': 456,
      'app_id': 42,
      'account': {'id': 789, 'type': 'Organization', 'login': 'acme'},
      'suspended_at': null,
    };
    installations = [installation];
    membership = {
      'state': 'active',
      'role': 'admin',
      'user': {'id': 123, 'login': 'octocat'},
      'organization': {'id': 789, 'login': 'acme'},
    };
    respond = (request) async {
      if (request.url.path.endsWith('/user')) return jsonResponse(user);
      if (request.url.path.endsWith('/user/installations')) {
        return jsonResponse({
          'total_count': installations.length,
          'installations': installations,
        });
      }
      return jsonResponse(membership);
    };
    clients = [];
    requests = [];
  });

  tearDown(() {
    for (final client in clients) {
      client.close();
    }
  });

  Future<GitHubInstallation?> verify({
    int installationId = 456,
    Duration membershipTimeout = const Duration(seconds: 10),
  }) => http.runWithClient(
    () => verifyGitHubInstallation(
      accessToken: 'private-user-token',
      installationId: installationId,
      environment: environment,
      membershipTimeout: membershipTimeout,
    ),
    () {
      final client = _TrackingClient(MockClient(respond), requests);
      clients.add(client);
      return client;
    },
  );

  test('allows the owner of a personal installation by user ID', () async {
    installation['account'] = {
      'id': 123,
      'type': 'User',
      'login': 'renamed-octocat',
    };

    final result = await verify();

    expect(result?.id, 456);
    expect(result?.accountId, 123);
    expect(requests.map((request) => request.url.path), [
      '/user',
      '/user/installations',
    ]);
    expect(clients.every((client) => client.closed), isTrue);
  });

  test(
    'allows an active organization admin with matching identities',
    () async {
      final result = await verify();

      expect(result?.id, 456);
      expect(result?.appId, 42);
      expect(result?.accountId, 789);
      expect(result?.accountType, 'Organization');
      expect(requests.map((request) => request.url.path), [
        '/user',
        '/user/installations',
        '/user/memberships/orgs/acme',
      ]);
      final request = requests.last as http.Request;
      expect(request.method, 'GET');
      expect(request.headers['Authorization'], 'Bearer private-user-token');
      expect(request.headers['Accept'], 'application/vnd.github.v3+json');
      expect(request.headers['X-GitHub-Api-Version'], '2022-11-28');
      expect(request.body, isEmpty);
      expect(request.followRedirects, isFalse);
      expect(clients.every((client) => client.closed), isTrue);
    },
  );

  test('uses the configured GHES endpoint for every request', () async {
    environment['GITHUB_API_BASE_URL'] =
        'https://github.example:8443/prefix/api/v3/';
    membership['url'] = 'https://other.example/steal';
    membership['organization_url'] = 'https://other.example/steal';

    expect(await verify(), isNotNull);

    expect(requests.map((request) => request.url.host).toSet(), {
      'github.example',
    });
    expect(
      requests.last.url.toString(),
      'https://github.example:8443/prefix/api/v3/user/memberships/orgs/acme',
    );
  });

  test('encodes the organization login as a single URL component', () async {
    installation['account']['login'] = 'acme/other?query#fragment';

    await verify();

    expect(
      requests.last.url.toString(),
      'https://api.github.com/user/memberships/orgs/acme%2Fother%3Fquery%23fragment',
    );
  });

  test(
    'denies a different personal owner even when the login matches',
    () async {
      installation['account'] = {
        'id': 999,
        'type': 'User',
        'login': 'octocat',
      };

      expect(await verify(), isNull);
      expect(requests, hasLength(2));
    },
  );

  test('denies an installation ID absent from the user list', () async {
    expect(await verify(installationId: 999), isNull);
    expect(requests, hasLength(2));
  });

  test('denies a user with no accessible installations', () async {
    installations = [];

    expect(await verify(), isNull);
    expect(requests, hasLength(2));
  });

  test(
    'verifies the selected installation instead of the first candidate',
    () async {
      installations.insert(0, {
        ...installation,
        'id': 999,
        'app_id': 888,
      });

      expect((await verify())?.id, 456);
    },
  );

  test('denies an installation belonging to another GitHub App', () async {
    installation['app_id'] = 999;

    expect(await verify(), isNull);
    expect(requests, hasLength(2));
  });

  test('denies a suspended installation before checking membership', () async {
    installation['suspended_at'] = '2026-10-16T00:00:00Z';

    expect(await verify(), isNull);
    expect(requests, hasLength(2));
  });

  test(
    'denies ordinary organization members with installation access',
    () async {
      membership['role'] = 'member';

      expect(await verify(), isNull);
    },
  );

  test('denies a pending admin invitation', () async {
    membership['state'] = 'pending';

    expect(await verify(), isNull);
  });

  test('requires an explicit active membership state', () async {
    membership.remove('state');

    expect(await verify(), isNull);
  });

  test('requires an explicit admin role', () async {
    membership['role'] = 'unknown';

    expect(await verify(), isNull);
  });

  test('denies a membership for a different organization ID', () async {
    membership['organization'] = {'id': 999, 'login': 'acme'};

    expect(await verify(), isNull);
  });

  test('denies a membership for a different user ID', () async {
    membership['user'] = {'id': 999, 'login': 'octocat'};

    expect(await verify(), isNull);
  });

  test(
    'rejects fractional organization IDs without numeric coercion',
    () async {
      membership['organization']['id'] = 789.0;

      expect(await verify(), isNull);
    },
  );

  test('rejects fractional user IDs without numeric coercion', () async {
    membership['user']['id'] = 123.0;

    expect(await verify(), isNull);
  });

  test('denies a membership without organization identity', () async {
    membership.remove('organization');

    expect(await verify(), isNull);
  });

  test('denies a membership without user identity', () async {
    membership.remove('user');

    expect(await verify(), isNull);
  });

  test('rechecks authority when admin membership is revoked', () async {
    expect(await verify(), isNotNull);
    membership['role'] = 'member';

    expect(await verify(), isNull);
    expect(requests, hasLength(6));
  });

  test(
    'rejects a blocked membership API without leaking its response',
    () async {
      final original = respond;
      respond = (request) async {
        if (request.url.path.contains('/memberships/')) {
          return http.Response(
            '{"message":"private-user-token and upstream detail"}',
            HttpStatus.forbidden,
            headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          );
        }
        return original(request);
      };

      await expectLater(verify(), membershipFailure);

      expect(clients.every((client) => client.closed), isTrue);
    },
  );

  test('rejects a membership that is no longer found', () async {
    final original = respond;
    respond = (request) async {
      if (request.url.path.contains('/memberships/')) {
        return http.Response('private detail', HttpStatus.notFound);
      }
      return original(request);
    };

    await expectLater(verify(), membershipFailure);
  });

  test('rejects membership redirects without forwarding the token', () async {
    final original = respond;
    respond = (request) async {
      if (request.url.path.contains('/memberships/')) {
        return http.Response(
          '',
          HttpStatus.temporaryRedirect,
          headers: {
            HttpHeaders.locationHeader: 'https://other.example/steal',
          },
        );
      }
      return original(request);
    };

    await expectLater(verify(), membershipFailure);

    expect(requests, hasLength(3));
    expect(requests.last.followRedirects, isFalse);
    expect(clients.every((client) => client.closed), isTrue);
  });

  test('rejects malformed membership JSON without leaking it', () async {
    final original = respond;
    respond = (request) async {
      if (request.url.path.contains('/memberships/')) {
        return http.Response('{"private-user-token', HttpStatus.ok);
      }
      return original(request);
    };

    await expectLater(verify(), membershipFailure);
  });

  test('rejects a non-object membership response', () async {
    final original = respond;
    respond = (request) async {
      if (request.url.path.contains('/memberships/')) return jsonResponse([]);
      return original(request);
    };

    await expectLater(verify(), membershipFailure);
  });

  test('hides transport errors and closes the membership client', () async {
    final original = respond;
    respond = (request) async {
      if (request.url.path.contains('/memberships/')) {
        throw http.ClientException('private-user-token and upstream detail');
      }
      return original(request);
    };

    await expectLater(verify(), membershipFailure);

    expect(clients.every((client) => client.closed), isTrue);
  });

  test('times out stalled membership requests and closes the client', () async {
    final pending = Completer<http.Response>();
    final original = respond;
    respond = (request) async {
      if (request.url.path.contains('/memberships/')) return pending.future;
      return original(request);
    };
    addTearDown(() => pending.complete(jsonResponse(membership)));

    await expectLater(
      verify(membershipTimeout: const Duration(milliseconds: 20)),
      membershipFailure,
    );

    expect(clients.every((client) => client.closed), isTrue);
  });

  test('stops verification if the user token is rejected', () async {
    respond = (_) async =>
        http.Response('private detail', HttpStatus.unauthorized);

    await expectLater(verify(), throwsA(isA<HttpException>()));

    expect(requests, hasLength(1));
    expect(clients.every((client) => client.closed), isTrue);
  });

  test(
    'stops verification if the installation list cannot be fetched',
    () async {
      final original = respond;
      respond = (request) async {
        if (request.url.path.endsWith('/installations')) {
          return http.Response('private detail', HttpStatus.serviceUnavailable);
        }
        return original(request);
      };

      await expectLater(verify(), throwsA(isA<HttpException>()));

      expect(requests, hasLength(2));
      expect(clients.every((client) => client.closed), isTrue);
    },
  );

  test('rejects a missing App ID before making requests', () async {
    environment.remove('GITHUB_APP_ID');

    await expectLater(verify(), throwsStateError);

    expect(requests, isEmpty);
  });

  test('rejects a non-numeric App ID before making requests', () async {
    environment['GITHUB_APP_ID'] = 'private-invalid-app-id';

    await expectLater(
      verify(),
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

  test('rejects a non-positive App ID before making requests', () async {
    environment['GITHUB_APP_ID'] = '0';

    await expectLater(verify(), throwsStateError);

    expect(requests, isEmpty);
  });

  test(
    'rejects a non-positive installation ID before making requests',
    () async {
      await expectLater(verify(installationId: 0), throwsArgumentError);

      expect(requests, isEmpty);
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
