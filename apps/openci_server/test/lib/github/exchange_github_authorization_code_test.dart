import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_server/github/exchange_github_authorization_code.dart';
import 'package:test/test.dart';

void main() {
  late Map<String, String> environment;
  late _TrackingClient client;
  final exchangeFailure = throwsA(
    isA<HttpException>().having(
      (error) => error.toString(),
      'safe error message',
      'HttpException: Failed to exchange GitHub authorization code',
    ),
  );

  setUp(() {
    environment = {
      'GITHUB_API_BASE_URL': 'https://api.github.com',
      'GITHUB_APP_CLIENT_ID': 'Iv1.test-client',
      'GITHUB_APP_CLIENT_SECRET': 'test-client-secret',
      'GITHUB_OAUTH_REDIRECT_URI': 'https://openci.example/github/callback',
    };
    client = _TrackingClient(
      MockClient(
        (_) async => http.Response(
          '{"access_token":"ghu_test-token","token_type":"bearer"}',
          HttpStatus.ok,
        ),
      ),
    );
  });

  tearDown(() => client.close());

  Future<String> exchange({
    String code = 'authorization-code',
    String codeVerifier = 'saved-code-verifier',
    Duration timeout = const Duration(seconds: 10),
  }) {
    return http.runWithClient(
      () => exchangeGitHubAuthorizationCode(
        code: code,
        codeVerifier: codeVerifier,
        environment: environment,
        timeout: timeout,
      ),
      () => client,
    );
  }

  test('exchanges the code and PKCE verifier using a form POST', () async {
    final token = await exchange(code: 'code+with&reserved=characters');

    expect(token, 'ghu_test-token');
    final request = client.requests.single as http.Request;
    expect(request.method, 'POST');
    expect(
      request.url.toString(),
      'https://github.com/login/oauth/access_token',
    );
    expect(request.url.hasQuery, isFalse);
    expect(request.followRedirects, isFalse);
    expect(request.headers['Accept'], 'application/json');
    expect(
      request.headers[HttpHeaders.contentTypeHeader],
      startsWith('application/x-www-form-urlencoded'),
    );
    expect(request.bodyFields, {
      'client_id': 'Iv1.test-client',
      'client_secret': 'test-client-secret',
      'redirect_uri': 'https://openci.example/github/callback',
      'code': 'code+with&reserved=characters',
      'code_verifier': 'saved-code-verifier',
    });
    expect(client.closed, isTrue);
  });

  test('uses the configured GHES host, port, and path prefix', () async {
    environment['GITHUB_API_BASE_URL'] =
        'https://github.example.com:8443/github/api/v3/';

    await exchange();

    expect(
      client.requests.single.url.toString(),
      'https://github.example.com:8443/github/login/oauth/access_token',
    );
  });

  test(
    'rejects an OAuth error in a 200 response without exposing its body',
    () async {
      client = _TrackingClient(
        MockClient(
          (_) async => http.Response(
            '{"error":"bad_verification_code","error_description":"private-detail",'
            '"access_token":"private-token","token_type":"bearer"}',
            HttpStatus.ok,
          ),
        ),
      );

      await expectLater(exchange(), exchangeFailure);

      expect(client.requests, hasLength(1));
      expect(client.closed, isTrue);
    },
  );

  test('rejects an HTTP error without exposing its body', () async {
    client = _TrackingClient(
      MockClient(
        (_) async => http.Response(
          'private upstream credentials',
          HttpStatus.unauthorized,
        ),
      ),
    );

    await expectLater(exchange(), exchangeFailure);
  });

  test('rejects redirects without retrying the exchange', () async {
    client = _TrackingClient(
      MockClient(
        (_) async => http.Response(
          '{"access_token":"private-token","token_type":"bearer"}',
          HttpStatus.temporaryRedirect,
          headers: {HttpHeaders.locationHeader: 'https://other.example/token'},
        ),
      ),
    );

    await expectLater(exchange(), exchangeFailure);

    expect(client.requests, hasLength(1));
    expect(client.requests.single.followRedirects, isFalse);
    expect(client.closed, isTrue);
  });

  test('rejects malformed JSON without exposing its contents', () async {
    client = _TrackingClient(
      MockClient(
        (_) async => http.Response(
          '{"access_token":"private-token',
          HttpStatus.ok,
        ),
      ),
    );

    await expectLater(exchange(), exchangeFailure);
  });

  test('rejects a non-object response', () async {
    client = _TrackingClient(
      MockClient(
        (_) async => http.Response(
          '["private-token"]',
          HttpStatus.ok,
        ),
      ),
    );

    await expectLater(exchange(), exchangeFailure);
  });

  test('rejects a missing access token', () async {
    client = _TrackingClient(
      MockClient(
        (_) async => http.Response(
          '{"token_type":"bearer"}',
          HttpStatus.ok,
        ),
      ),
    );

    await expectLater(exchange(), exchangeFailure);
  });

  test('rejects a non-string access token', () async {
    client = _TrackingClient(
      MockClient(
        (_) async => http.Response(
          '{"access_token":123,"token_type":"bearer"}',
          HttpStatus.ok,
        ),
      ),
    );

    await expectLater(exchange(), exchangeFailure);
  });

  test('rejects an empty access token', () async {
    client = _TrackingClient(
      MockClient(
        (_) async => http.Response(
          '{"access_token":"","token_type":"bearer"}',
          HttpStatus.ok,
        ),
      ),
    );

    await expectLater(exchange(), exchangeFailure);
  });

  test('rejects whitespace inside an access token', () async {
    client = _TrackingClient(
      MockClient(
        (_) async => http.Response(
          '{"access_token":"private token","token_type":"bearer"}',
          HttpStatus.ok,
        ),
      ),
    );

    await expectLater(exchange(), exchangeFailure);
  });

  test('rejects a non-bearer token type', () async {
    client = _TrackingClient(
      MockClient(
        (_) async => http.Response(
          '{"access_token":"private-token","token_type":"mac"}',
          HttpStatus.ok,
        ),
      ),
    );

    await expectLater(exchange(), exchangeFailure);
  });

  test('hides transport error details and closes the client', () async {
    client = _TrackingClient(
      MockClient((_) async {
        throw http.ClientException('private code, verifier, and client secret');
      }),
    );

    await expectLater(exchange(), exchangeFailure);

    expect(client.closed, isTrue);
  });

  test('times out a stalled request and closes the client', () async {
    final pending = Completer<http.Response>();
    client = _TrackingClient(MockClient((_) => pending.future));
    addTearDown(
      () => pending.complete(http.Response('', HttpStatus.badGateway)),
    );

    await expectLater(
      exchange(timeout: const Duration(milliseconds: 20)),
      exchangeFailure,
    );

    expect(client.closed, isTrue);
  });

  test('also times out when only the response body stalls', () async {
    final body = StreamController<List<int>>();
    addTearDown(body.close);
    client = _TrackingClient(
      MockClient.streaming((_, _) async {
        return http.StreamedResponse(body.stream, HttpStatus.ok);
      }),
    );

    await expectLater(
      exchange(timeout: const Duration(milliseconds: 20)),
      exchangeFailure,
    );

    expect(client.closed, isTrue);
  });

  test('rejects a missing client secret before sending a request', () async {
    environment.remove('GITHUB_APP_CLIENT_SECRET');

    await expectLater(exchange(), throwsStateError);

    expect(client.requests, isEmpty);
  });

  test('rejects a missing client ID before sending a request', () async {
    environment.remove('GITHUB_APP_CLIENT_ID');

    await expectLater(exchange(), throwsStateError);

    expect(client.requests, isEmpty);
  });

  test('rejects a missing callback URL before sending a request', () async {
    environment.remove('GITHUB_OAUTH_REDIRECT_URI');

    await expectLater(exchange(), throwsStateError);

    expect(client.requests, isEmpty);
  });

  test('rejects a callback URL containing a fragment', () async {
    environment['GITHUB_OAUTH_REDIRECT_URI'] =
        'https://openci.example/github/callback#fragment';

    await expectLater(exchange(), throwsStateError);

    expect(client.requests, isEmpty);
  });

  test(
    'rejects an invalid GitHub base URL before sending credentials',
    () async {
      environment['GITHUB_API_BASE_URL'] =
          'https://api.github.com?unexpected=value';

      await expectLater(exchange(), throwsStateError);

      expect(client.requests, isEmpty);
    },
  );

  test('rejects a blank code before sending a request', () async {
    await expectLater(exchange(code: ' '), throwsArgumentError);

    expect(client.requests, isEmpty);
  });

  test('rejects a blank verifier before sending a request', () async {
    await expectLater(exchange(codeVerifier: ' '), throwsArgumentError);

    expect(client.requests, isEmpty);
  });
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
