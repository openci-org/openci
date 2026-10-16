import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_server/github/fetch_github_user.dart';
import 'package:test/test.dart';

void main() {
  late Map<String, String> environment;
  late http.Response response;
  late _TrackingClient client;
  final fetchFailure = throwsA(
    isA<HttpException>().having(
      (error) => error.toString(),
      'safe error message',
      'HttpException: Failed to fetch GitHub user',
    ),
  );

  setUp(() {
    environment = {'GITHUB_API_BASE_URL': 'https://api.github.com'};
    response = http.Response(
      '{"id":123,"login":"octocat","email":"private@example.com"}',
      HttpStatus.ok,
    );
    client = _TrackingClient(MockClient((_) async => response));
  });

  tearDown(() => client.close());

  Future<GitHubUser> fetch({
    String accessToken = 'ghu_private-token',
    Duration timeout = const Duration(seconds: 10),
  }) {
    return http.runWithClient(
      () => fetchGitHubUser(
        accessToken: accessToken,
        environment: environment,
        timeout: timeout,
      ),
      () => client,
    );
  }

  test('fetches the authenticated user with a bearer token', () async {
    final user = await fetch();

    expect(user.id, 123);
    expect(user.login, 'octocat');
    final request = client.requests.single as http.Request;
    expect(request.method, 'GET');
    expect(request.url.toString(), 'https://api.github.com/user');
    expect(request.url.hasQuery, isFalse);
    expect(request.body, isEmpty);
    expect(request.headers['Authorization'], 'Bearer ghu_private-token');
    expect(request.headers['Accept'], 'application/vnd.github.v3+json');
    expect(request.headers['X-GitHub-Api-Version'], '2022-11-28');
    expect(request.headers['User-Agent'], 'github.dart');
    expect(request.followRedirects, isFalse);
    expect(client.closed, isTrue);
  });

  test('preserves the configured GHES host, port, and REST path', () async {
    environment['GITHUB_API_BASE_URL'] =
        'https://github.example:8443/github/api/v3/';

    await fetch();

    expect(
      client.requests.single.url.toString(),
      'https://github.example:8443/github/api/v3/user',
    );
  });

  test('removes trailing slashes from the configured API root', () async {
    environment['GITHUB_API_BASE_URL'] = ' https://api.github.com/// ';

    await fetch();

    expect(
      client.requests.single.url.toString(),
      'https://api.github.com/user',
    );
  });

  test('rejects 401 without exposing the response body', () async {
    response = http.Response(
      'private upstream detail',
      HttpStatus.unauthorized,
    );

    await expectLater(fetch(), fetchFailure);

    expect(client.closed, isTrue);
  });

  test('rejects 403 without exposing the response body', () async {
    response = http.Response('private upstream detail', HttpStatus.forbidden);

    await expectLater(fetch(), fetchFailure);

    expect(client.closed, isTrue);
  });

  test(
    'hides GitHub package error messages containing private details',
    () async {
      response = http.Response(
        '{"message":"private upstream detail"}',
        HttpStatus.badGateway,
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      );

      await expectLater(fetch(), fetchFailure);

      expect(client.closed, isTrue);
    },
  );

  test('rejects redirects without forwarding the token', () async {
    response = http.Response(
      '{"id":123,"login":"octocat"}',
      HttpStatus.temporaryRedirect,
      headers: {HttpHeaders.locationHeader: 'https://other.example/user'},
    );

    await expectLater(fetch(), fetchFailure);

    expect(client.requests, hasLength(1));
    expect(client.requests.single.followRedirects, isFalse);
    expect(client.closed, isTrue);
  });

  test('rejects malformed JSON without exposing its contents', () async {
    response = http.Response('{"private-token', HttpStatus.ok);

    await expectLater(fetch(), fetchFailure);

    expect(client.closed, isTrue);
  });

  test('rejects a non-object response', () async {
    response = http.Response('[{"id":123,"login":"octocat"}]', HttpStatus.ok);

    await expectLater(fetch(), fetchFailure);
  });

  test('rejects a missing user ID', () async {
    response = http.Response('{"login":"octocat"}', HttpStatus.ok);

    await expectLater(fetch(), fetchFailure);
  });

  test('rejects a user ID that is not an integer', () async {
    response = http.Response('{"id":"123","login":"octocat"}', HttpStatus.ok);

    await expectLater(fetch(), fetchFailure);
  });

  test('rejects a fractional user ID without truncating it', () async {
    response = http.Response('{"id":123.5,"login":"octocat"}', HttpStatus.ok);

    await expectLater(fetch(), fetchFailure);
  });

  test('rejects a non-positive user ID', () async {
    response = http.Response('{"id":0,"login":"octocat"}', HttpStatus.ok);

    await expectLater(fetch(), fetchFailure);
  });

  test('rejects a missing login', () async {
    response = http.Response('{"id":123}', HttpStatus.ok);

    await expectLater(fetch(), fetchFailure);
  });

  test('rejects a login that is not a string', () async {
    response = http.Response('{"id":123,"login":456}', HttpStatus.ok);

    await expectLater(fetch(), fetchFailure);
  });

  test('rejects a blank login', () async {
    response = http.Response('{"id":123,"login":" "}', HttpStatus.ok);

    await expectLater(fetch(), fetchFailure);
  });

  test('hides transport error details and closes the client', () async {
    client = _TrackingClient(
      MockClient((_) async {
        throw http.ClientException('private token and transport detail');
      }),
    );

    await expectLater(fetch(), fetchFailure);

    expect(client.closed, isTrue);
  });

  test('times out a stalled request and closes the client', () async {
    final pending = Completer<http.Response>();
    client = _TrackingClient(MockClient((_) => pending.future));
    addTearDown(() => pending.complete(response));

    await expectLater(
      fetch(timeout: const Duration(milliseconds: 20)),
      fetchFailure,
    );

    expect(client.closed, isTrue);
  });

  test('also times out when the response body stalls', () async {
    final body = StreamController<List<int>>();
    addTearDown(body.close);
    client = _TrackingClient(
      MockClient.streaming((_, _) async {
        return http.StreamedResponse(body.stream, HttpStatus.ok);
      }),
    );

    await expectLater(
      fetch(timeout: const Duration(milliseconds: 20)),
      fetchFailure,
    );

    expect(client.closed, isTrue);
  });

  test('rejects a missing API URL before sending the token', () async {
    environment.remove('GITHUB_API_BASE_URL');

    await expectLater(fetch(), throwsStateError);

    expect(client.requests, isEmpty);
  });

  test('rejects an API URL containing credentials', () async {
    environment['GITHUB_API_BASE_URL'] = 'https://user:private@api.github.com';

    await expectLater(fetch(), throwsStateError);

    expect(client.requests, isEmpty);
  });

  test('rejects an API URL containing a query', () async {
    environment['GITHUB_API_BASE_URL'] = 'https://api.github.com?token=private';

    await expectLater(fetch(), throwsStateError);

    expect(client.requests, isEmpty);
  });

  test('rejects an API URL containing a fragment', () async {
    environment['GITHUB_API_BASE_URL'] = 'https://api.github.com#fragment';

    await expectLater(fetch(), throwsStateError);

    expect(client.requests, isEmpty);
  });

  test('rejects a relative API URL', () async {
    environment['GITHUB_API_BASE_URL'] = '/api/v3';

    await expectLater(fetch(), throwsStateError);

    expect(client.requests, isEmpty);
  });

  test('rejects an unsupported API URL scheme', () async {
    environment['GITHUB_API_BASE_URL'] = 'ftp://github.example/api/v3';

    await expectLater(fetch(), throwsStateError);

    expect(client.requests, isEmpty);
  });

  test('rejects an empty token before sending a request', () async {
    await expectLater(fetch(accessToken: ''), throwsArgumentError);

    expect(client.requests, isEmpty);
  });

  test(
    'rejects whitespace inside the token before sending a request',
    () async {
      await expectLater(
        fetch(accessToken: 'private-token\r\nInjected: header'),
        throwsArgumentError,
      );

      expect(client.requests, isEmpty);
    },
  );
}

class _TrackingClient extends http.BaseClient {
  _TrackingClient(this._inner);

  final http.Client _inner;
  final requests = <http.BaseRequest>[];
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
