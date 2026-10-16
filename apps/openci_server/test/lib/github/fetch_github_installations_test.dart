import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_server/github/fetch_github_installations.dart';
import 'package:test/test.dart';

void main() {
  late Map<String, String> environment;
  late List<http.Response> responses;
  late _TrackingClient client;
  final fetchFailure = throwsA(
    isA<HttpException>().having(
      (error) => error.toString(),
      'safe error message',
      'HttpException: Failed to fetch GitHub installations',
    ),
  );

  Map<String, dynamic> installation(int id) => {
    'id': id,
    'app_id': 42,
    'account': {'id': 1000 + id, 'type': 'Organization', 'login': 'org-$id'},
    'suspended_at': null,
  };

  http.Response page(
    List<Object?> installations, {
    int? totalCount,
    Map<String, String> headers = const {},
  }) => http.Response(
    jsonEncode({
      'total_count': totalCount ?? installations.length,
      'installations': installations,
    }),
    HttpStatus.ok,
    headers: {HttpHeaders.contentTypeHeader: 'application/json', ...headers},
  );

  List<Map<String, dynamic>> firstPage() => List.generate(
    100,
    (index) => installation(index + 1),
  );

  setUp(() {
    environment = {'GITHUB_API_BASE_URL': 'https://api.github.com'};
    responses = [
      page([installation(1)]),
    ];
    var index = 0;
    client = _TrackingClient(MockClient((_) async => responses[index++]));
  });

  tearDown(() => client.close());

  Future<List<GitHubInstallation>> fetch({
    String accessToken = 'private-user-token',
    Duration timeout = const Duration(seconds: 10),
  }) => http.runWithClient(
    () => fetchGitHubInstallations(
      accessToken: accessToken,
      environment: environment,
      timeout: timeout,
    ),
    () => client,
  );

  test(
    'returns installation and account metadata using a bearer token',
    () async {
      final result = await fetch();

      final item = result.single;
      expect(item.id, 1);
      expect(item.appId, 42);
      expect(item.accountId, 1001);
      expect(item.accountType, 'Organization');
      expect(item.accountLogin, 'org-1');
      expect(item.suspendedAt, isNull);
      final request = client.requests.single as http.Request;
      expect(request.method, 'GET');
      expect(request.url.path, '/user/installations');
      expect(request.url.queryParameters, {'per_page': '100', 'page': '1'});
      expect(request.headers['Authorization'], 'Bearer private-user-token');
      expect(request.headers['Accept'], 'application/vnd.github.v3+json');
      expect(request.headers['X-GitHub-Api-Version'], '2022-11-28');
      expect(request.body, isEmpty);
      expect(request.followRedirects, isFalse);
      expect(client.closed, isTrue);
    },
  );

  test('returns an empty list when the user has no installations', () async {
    responses = [page([])];

    expect(await fetch(), isEmpty);
    expect(client.requests, hasLength(1));
    expect(client.closed, isTrue);
  });

  test(
    'preserves a suspended personal installation for later checks',
    () async {
      final item = installation(1);
      item['account'] = {'id': 123, 'type': 'User', 'login': 'octocat'};
      item['suspended_at'] = '2026-10-16T12:00:00+09:00';
      responses = [
        page([item]),
      ];

      final result = (await fetch()).single;

      expect(result.accountId, 123);
      expect(result.accountType, 'User');
      expect(result.accountLogin, 'octocat');
      expect(result.suspendedAt, DateTime.utc(2026, 10, 16, 3));
    },
  );

  test('keeps all pages on the configured GHES endpoint', () async {
    environment['GITHUB_API_BASE_URL'] =
        ' https://github.example:8443/prefix/api/v3/// ';
    responses = [
      page(
        firstPage(),
        totalCount: 101,
        headers: {'link': '<https://other.example/steal?page=2>; rel="next"'},
      ),
      page(
        [installation(101)],
        totalCount: 101,
        headers: {
          'link':
              '<https://github.example:8443/prefix/api/v3/user/installations?page=1>; rel="prev", '
              '<https://github.example:8443/prefix/api/v3/user/installations?page=1>; rel="first"',
        },
      ),
    ];

    final result = await fetch();

    expect(
      result.map((item) => item.id),
      List.generate(101, (index) => index + 1),
    );
    expect(client.requests, hasLength(2));
    expect(
      client.requests.last.url.toString(),
      'https://github.example:8443/prefix/api/v3/user/installations?per_page=100&page=2',
    );
    expect(client.requests.first.url.host, 'github.example');
    expect(
      client.requests.last.headers['Authorization'],
      'Bearer private-user-token',
    );
    expect(client.closed, isTrue);
  });

  test('returns all 1000 installations at the acquisition limit', () async {
    responses = List.generate(
      10,
      (pageIndex) => page(
        List.generate(
          100,
          (index) => installation(pageIndex * 100 + index + 1),
        ),
        totalCount: 1000,
      ),
    );

    final result = await fetch();

    expect(result, hasLength(1000));
    expect(result.last.id, 1000);
    expect(client.requests, hasLength(10));
    expect(client.requests.last.url.queryParameters['page'], '10');
  });

  test(
    'rejects more than 1000 installations without returning a partial list',
    () async {
      responses = [page(firstPage(), totalCount: 1001)];

      await expectLater(fetch(), fetchFailure);

      expect(client.requests, hasLength(1));
      expect(client.closed, isTrue);
    },
  );

  test('rejects duplicate installations in one page', () async {
    responses = [
      page([installation(1), installation(1)]),
    ];

    await expectLater(fetch(), fetchFailure);
  });

  test('rejects duplicate installations across pages', () async {
    responses = [
      page(firstPage(), totalCount: 101),
      page([installation(1)], totalCount: 101),
    ];

    await expectLater(fetch(), fetchFailure);

    expect(client.requests, hasLength(2));
  });

  test('rejects a count that changes between pages', () async {
    responses = [
      page(firstPage(), totalCount: 101),
      page([installation(101)], totalCount: 102),
    ];

    await expectLater(fetch(), fetchFailure);
  });

  test(
    'rejects a short first page when more installations are expected',
    () async {
      responses = [
        page([installation(1)], totalCount: 101),
      ];

      await expectLater(fetch(), fetchFailure);

      expect(client.requests, hasLength(1));
    },
  );

  test('rejects a truncated final page', () async {
    responses = [
      page(firstPage(), totalCount: 102),
      page([installation(101)], totalCount: 102),
    ];

    await expectLater(fetch(), fetchFailure);
  });

  test('rejects more items than the declared total', () async {
    responses = [
      page([installation(1), installation(2)], totalCount: 1),
    ];

    await expectLater(fetch(), fetchFailure);
  });

  test('rejects a page larger than the requested page size', () async {
    responses = [page(List.generate(101, (index) => installation(index + 1)))];

    await expectLater(fetch(), fetchFailure);
  });

  test('rejects a next link after the declared final page', () async {
    responses = [
      page(
        [installation(1)],
        headers: {
          'link':
              '<https://api.github.com/user/installations?page=2>; rel="next"',
        },
      ),
    ];

    await expectLater(fetch(), fetchFailure);

    expect(client.requests, hasLength(1));
  });

  test('rejects a malformed pagination header', () async {
    responses = [
      page([installation(1)], headers: {'link': 'invalid-link'}),
    ];

    await expectLater(fetch(), fetchFailure);
  });

  test('discards earlier pages when a later GitHub request fails', () async {
    responses = [
      page(firstPage(), totalCount: 101),
      http.Response(
        '{"message":"private-user-token and private-upstream-detail"}',
        HttpStatus.serviceUnavailable,
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      ),
    ];

    await expectLater(fetch(), fetchFailure);

    expect(client.requests, hasLength(2));
    expect(client.closed, isTrue);
  });

  test(
    'rejects unauthorized responses without leaking their contents',
    () async {
      responses = [
        http.Response('private-user-token', HttpStatus.unauthorized),
      ];

      await expectLater(fetch(), fetchFailure);

      expect(client.closed, isTrue);
    },
  );

  test('stops when the rate limit is exhausted before the next page', () async {
    responses = [
      page(
        firstPage(),
        totalCount: 101,
        headers: {
          'x-ratelimit-limit': '5000',
          'x-ratelimit-remaining': '0',
          'x-ratelimit-reset':
              '${DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600}',
        },
      ),
    ];

    await expectLater(
      fetch().timeout(const Duration(seconds: 1)),
      fetchFailure,
    );

    expect(client.requests, hasLength(1));
    expect(client.closed, isTrue);
  });

  test('rejects malformed JSON without leaking its contents', () async {
    responses = [http.Response('{"private-token', HttpStatus.ok)];

    await expectLater(fetch(), fetchFailure);
  });

  test('rejects a non-object response', () async {
    responses = [http.Response('[]', HttpStatus.ok)];

    await expectLater(fetch(), fetchFailure);
  });

  test('rejects a total count that is not an integer', () async {
    responses = [
      http.Response('{"total_count":0.5,"installations":[]}', HttpStatus.ok),
    ];

    await expectLater(fetch(), fetchFailure);
  });

  test('rejects a response without an installations list', () async {
    responses = [http.Response('{"total_count":0}', HttpStatus.ok)];

    await expectLater(fetch(), fetchFailure);
  });

  test('rejects a non-object installation', () async {
    responses = [
      page([null]),
    ];

    await expectLater(fetch(), fetchFailure);
  });

  test('rejects a fractional installation ID', () async {
    final item = installation(1)..['id'] = 1.5;
    responses = [
      page([item]),
    ];

    await expectLater(fetch(), fetchFailure);
  });

  test('rejects a missing App ID', () async {
    final item = installation(1)..remove('app_id');
    responses = [
      page([item]),
    ];

    await expectLater(fetch(), fetchFailure);
  });

  test('rejects a non-integer account ID', () async {
    final item = installation(1);
    item['account'] = {'id': '1001', 'type': 'Organization', 'login': 'org-1'};
    responses = [
      page([item]),
    ];

    await expectLater(fetch(), fetchFailure);
  });

  test('rejects an installation without its account', () async {
    final item = installation(1)..remove('account');
    responses = [
      page([item]),
    ];

    await expectLater(fetch(), fetchFailure);
  });

  test('rejects an unsupported account type', () async {
    final item = installation(1);
    item['account'] = {'id': 1001, 'type': 'Unknown', 'login': 'org-1'};
    responses = [
      page([item]),
    ];

    await expectLater(fetch(), fetchFailure);
  });

  test('rejects a blank account login', () async {
    final item = installation(1);
    item['account'] = {'id': 1001, 'type': 'Organization', 'login': ' '};
    responses = [
      page([item]),
    ];

    await expectLater(fetch(), fetchFailure);
  });

  test('rejects missing suspension information', () async {
    final item = installation(1)..remove('suspended_at');
    responses = [
      page([item]),
    ];

    await expectLater(fetch(), fetchFailure);
  });

  test('rejects an invalid suspension timestamp', () async {
    final item = installation(1)..['suspended_at'] = 'invalid-date';
    responses = [
      page([item]),
    ];

    await expectLater(fetch(), fetchFailure);
  });

  test('rejects redirects without forwarding the token', () async {
    responses = [
      http.Response(
        '',
        HttpStatus.temporaryRedirect,
        headers: {HttpHeaders.locationHeader: 'https://other.example/steal'},
      ),
    ];

    await expectLater(fetch(), fetchFailure);

    expect(client.requests, hasLength(1));
    expect(client.requests.single.followRedirects, isFalse);
    expect(client.closed, isTrue);
  });

  test('hides transport errors and closes the client', () async {
    client = _TrackingClient(
      MockClient((_) async {
        throw http.ClientException(
          'private-user-token and private-upstream-detail',
        );
      }),
    );

    await expectLater(fetch(), fetchFailure);

    expect(client.closed, isTrue);
  });

  test('times out a stalled request and closes the client', () async {
    final pending = Completer<http.Response>();
    client = _TrackingClient(MockClient((_) => pending.future));
    addTearDown(() => pending.complete(page([])));

    await expectLater(
      fetch(timeout: const Duration(milliseconds: 20)),
      fetchFailure,
    );

    expect(client.closed, isTrue);
  });

  test('times out when the response body stalls', () async {
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

  test('shares the timeout across all pages', () async {
    final secondPage = Completer<http.Response>();
    Timer? secondPageTimer;
    var index = 0;
    client = _TrackingClient(
      MockClient((_) async {
        if (index++ == 0) {
          secondPageTimer = Timer(const Duration(milliseconds: 250), () {
            secondPage.complete(page([installation(101)], totalCount: 101));
          });
          await Future<void>.delayed(const Duration(milliseconds: 140));
          return page(firstPage(), totalCount: 101);
        }
        return secondPage.future;
      }),
    );
    addTearDown(() {
      secondPageTimer?.cancel();
      if (!secondPage.isCompleted) {
        secondPage.complete(page([installation(101)], totalCount: 101));
      }
    });

    await expectLater(
      fetch(timeout: const Duration(milliseconds: 200)),
      fetchFailure,
    );

    expect(client.requests.length, lessThanOrEqualTo(2));
    expect(client.closed, isTrue);
  });

  test(
    'rejects invalid operator configuration before sending the token',
    () async {
      environment['GITHUB_API_BASE_URL'] =
          'https://user:private@api.github.com';

      await expectLater(fetch(), throwsStateError);

      expect(client.requests, isEmpty);
    },
  );

  test('rejects an invalid access token before sending a request', () async {
    await expectLater(
      fetch(accessToken: 'private\nInjected: header'),
      throwsArgumentError,
    );

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
