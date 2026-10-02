import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_server/github/changed_files.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

import '../../helpers/github_app_test_key.dart';

const _base = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _head = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _other = 'cccccccccccccccccccccccccccccccccccccccc';

void main() {
  late Map<String, String> environment;
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('changed-files-test-');
    final key = await File('${directory.path}/key.pem').writeAsString(
      testRsaPrivateKey,
    );
    environment = {
      'GITHUB_API_BASE_URL': 'https://github.enterprise.test/api/v3/',
      'GITHUB_APP_ID': '42',
      'GITHUB_PRIVATE_KEY_PATH': key.path,
    };
  });
  tearDown(() => directory.delete(recursive: true));

  Future<ChangedFilesResult> fetch({
    String eventType = 'push',
    Map<String, dynamic>? payload,
    required Future<http.Response> Function(http.Request) handle,
    Future<http.Response> Function()? authenticate,
    Duration timeout = const Duration(seconds: 30),
  }) {
    final client = MockClient((request) async {
      expect(request.url.origin, 'https://github.enterprise.test');
      expect(request.headers['Accept'], 'application/vnd.github+json');
      expect(request.headers['X-GitHub-Api-Version'], '2022-11-28');
      if (request.method == 'POST') {
        expect(request.url.path, '/api/v3/app/installations/42/access_tokens');
        expect(request.headers['Authorization'], startsWith('Bearer ey'));
        return authenticate == null
            ? _json({'token': 'installation-token'}, status: 201)
            : authenticate();
      }
      expect(request.method, 'GET');
      expect(request.headers['Authorization'], 'Bearer installation-token');
      expect(request.url.path, startsWith('/api/v3/repos/openci-org/openci/'));
      return handle(request);
    });
    addTearDown(client.close);
    return fetchChangedFiles(
      eventType: eventType,
      payload: jsonEncode(payload ?? _pushPayload()),
      environment: environment,
      client: client,
      timeout: timeout,
    );
  }

  group('pull request files', () {
    test(
      'paginates the whole PR and deduplicates renamed/deleted paths',
      () async {
        final pages = <String?>[];
        var snapshots = 0;
        final result = await fetch(
          eventType: 'pull_request',
          payload: _prPayload(),
          handle: (request) async {
            if (!request.url.path.endsWith('/files')) {
              snapshots++;
              return _json(_snapshot(102));
            }
            expect(request.url.queryParameters['per_page'], '100');
            final page = request.url.queryParameters['page'];
            pages.add(page);
            return _json(
              page == '1'
                  ? _files(100)
                  : [
                      _file('lib/deleted.dart', status: 'removed'),
                      _file(
                        'lib/new.dart',
                        status: 'renamed',
                        previous: 'lib/file0.dart',
                      ),
                    ],
            );
          },
        );

        expect(result.isComplete, isTrue);
        expect(result.reason, isNull);
        expect(result.baseSha, _base);
        expect(result.headSha, _head);
        expect(result.paths, hasLength(102));
        expect(result.paths, containsAll(['lib/deleted.dart', 'lib/new.dart']));
        expect(
          result.paths.where((path) => path == 'lib/file0.dart'),
          hasLength(1),
        );
        expect(pages, ['1', '2']);
        expect(snapshots, 3);
      },
    );

    test('an empty PR is complete after verifying its snapshot', () async {
      var snapshots = 0;
      final result = await fetch(
        eventType: 'pull_request',
        payload: _prPayload(),
        handle: (request) async {
          if (request.url.path.endsWith('/files')) return _json([]);
          snapshots++;
          return _json(_snapshot(0));
        },
      );
      expect(result.isComplete, isTrue);
      expect(result.paths, isEmpty);
      expect(snapshots, 2);
    });

    test('fetches all 2,999 files below the PR limit', () async {
      final pages = <int>[];
      final result = await fetch(
        eventType: 'pull_request',
        payload: _prPayload(),
        handle: (request) async {
          if (!request.url.path.endsWith('/files')) {
            return _json(_snapshot(2999));
          }
          final page = int.parse(request.url.queryParameters['page']!);
          pages.add(page);
          return _json(_files(page == 30 ? 99 : 100, offset: (page - 1) * 100));
        },
      );
      expect(result.isComplete, isTrue);
      expect(result.paths, hasLength(2999));
      expect(pages, List.generate(30, (index) => index + 1));
    });

    for (final count in [3000, 3001]) {
      test(
        '$count PR files is indeterminate without downloading pages',
        () async {
          final result = await fetch(
            eventType: 'pull_request',
            payload: _prPayload(),
            handle: (request) async {
              expect(request.url.path.endsWith('/files'), isFalse);
              return _json(_snapshot(count));
            },
          );
          _expectIncomplete(result, 'file_limit');
        },
      );
    }

    for (final field in ['base', 'head']) {
      test('rejects an initial PR $field SHA mismatch', () async {
        final result = await fetch(
          eventType: 'pull_request',
          payload: _prPayload(),
          handle: (request) async {
            expect(request.url.path.endsWith('/files'), isFalse);
            return _json({
              ..._snapshot(1),
              field: {'sha': _other},
            });
          },
        );
        _expectIncomplete(result, 'sha_mismatch');
      });

      test('rejects a PR $field update during pagination', () async {
        var snapshots = 0;
        final result = await fetch(
          eventType: 'pull_request',
          payload: _prPayload(),
          handle: (request) async {
            if (request.url.path.endsWith('/files')) {
              expect(request.url.queryParameters['page'], '1');
              return _json(_files(100));
            }
            snapshots++;
            return _json({
              ..._snapshot(101),
              if (snapshots > 1) field: {'sha': _other},
            });
          },
        );
        _expectIncomplete(result, 'sha_mismatch');
      });
    }

    for (final field in ['changed_files', 'updated_at']) {
      test('detects a changed PR $field after fetching files', () async {
        var snapshots = 0;
        final result = await fetch(
          eventType: 'pull_request',
          payload: _prPayload(),
          handle: (request) async {
            if (request.url.path.endsWith('/files')) return _json(_files(1));
            snapshots++;
            return _json({
              ..._snapshot(1),
              if (snapshots > 1)
                field: field == 'changed_files' ? 2 : 'updated',
            });
          },
        );
        _expectIncomplete(result, 'pull_request_updated');
      });
    }

    test('rejects a short page even when the SHAs are unchanged', () async {
      final result = await fetch(
        eventType: 'pull_request',
        payload: _prPayload(),
        handle: (request) async => _json(
          request.url.path.endsWith('/files') ? _files(1) : _snapshot(2),
        ),
      );
      _expectIncomplete(result, 'truncated_response');
    });

    test('rejects duplicate filenames across PR pages', () async {
      final result = await fetch(
        eventType: 'pull_request',
        payload: _prPayload(),
        handle: (request) async {
          if (!request.url.path.endsWith('/files')) {
            return _json(_snapshot(101));
          }
          return _json(
            _files(request.url.queryParameters['page'] == '1' ? 100 : 1),
          );
        },
      );
      _expectIncomplete(result, 'truncated_response');
    });

    test('rejects an unexpected next page link', () async {
      final result = await fetch(
        eventType: 'pull_request',
        payload: _prPayload(),
        handle: (request) async => request.url.path.endsWith('/files')
            ? _json(
                _files(1),
                headers: {'link': '<https://example.test>; rel="next"'},
              )
            : _json(_snapshot(1)),
      );
      _expectIncomplete(result, 'truncated_response');
    });

    test('discards files if a later page fails', () async {
      final result = await fetch(
        eventType: 'pull_request',
        payload: _prPayload(),
        handle: (request) async {
          if (!request.url.path.endsWith('/files')) {
            return _json(_snapshot(101));
          }
          return request.url.queryParameters['page'] == '1'
              ? _json(_files(100))
              : _json({'message': 'rate limited'}, status: 429);
        },
      );
      _expectIncomplete(result, 'github_http_429');
    });
  });

  group('push comparison', () {
    test('identical before/after SHAs need no GitHub requests', () async {
      final client = MockClient((_) async => fail('Unexpected GitHub request'));
      addTearDown(client.close);
      final result = await fetchChangedFiles(
        eventType: 'push',
        payload: jsonEncode({..._pushPayload(), 'after': _base}),
        environment: environment,
        client: client,
      );
      expect(result.isComplete, isTrue);
      expect(result.paths, isEmpty);
    });

    test(
      'uses before/after rather than head_commit and includes deletes/renames',
      () async {
        final result = await fetch(
          payload: {
            ..._pushPayload(),
            'head_commit': {'id': _other},
          },
          handle: (request) async {
            expect(
              request.url.path,
              '/api/v3/repos/openci-org/openci/compare/$_base...$_head',
            );
            expect(request.url.hasQuery, isFalse);
            return _json(
              _comparison(
                files: [
                  _file('lib/current.dart'),
                  _file('lib/deleted.dart', status: 'removed'),
                  _file(
                    'lib/new.dart',
                    status: 'renamed',
                    previous: 'lib/old.dart',
                  ),
                ],
              ),
            );
          },
        );
        expect(result.isComplete, isTrue);
        expect(result.paths, [
          'lib/current.dart',
          'lib/deleted.dart',
          'lib/new.dart',
          'lib/old.dart',
        ]);
        expect(result.baseSha, _base);
        expect(result.headSha, _head);
      },
    );

    test('a push with no net file changes is complete', () async {
      final result = await fetch(
        handle: (_) async => _json(_comparison(files: [])),
      );
      expect(result.isComplete, isTrue);
      expect(result.paths, isEmpty);
    });

    test('verifies the final head with a capped list of 250 commits', () async {
      final result = await fetch(
        handle: (_) async => _json({
          ..._comparison(),
          'total_commits': 500,
          'commits': List.generate(
            250,
            (index) => {'sha': index == 249 ? _head : _other},
          ),
        }),
      );
      expect(result.isComplete, isTrue);
    });

    for (final (name, patch, reason) in [
      ('created branch', {'created': true}, 'new_branch'),
      ('zero before SHA', {'before': '0' * 40}, 'new_branch'),
      ('force push', {'forced': true}, 'force_push'),
      (
        'deleted branch',
        {'deleted': true, 'after': '0' * 40},
        'branch_deleted',
      ),
      ('missing before SHA', {'before': null}, 'invalid_webhook'),
      ('mutable head reference', {'after': 'main'}, 'invalid_webhook'),
      ('missing forced flag', {'forced': null}, 'invalid_webhook'),
    ]) {
      test('$name is indeterminate without any GitHub request', () async {
        final client = MockClient(
          (_) async => fail('Unexpected GitHub request'),
        );
        addTearDown(client.close);
        final result = await fetchChangedFiles(
          eventType: 'push',
          payload: jsonEncode({..._pushPayload(), ...patch}),
          environment: environment,
          client: client,
        );
        _expectIncomplete(result, reason);
      });
    }

    for (final count in [299, 300, 301]) {
      test('handles the comparison file limit at $count files', () async {
        final result = await fetch(
          handle: (_) async => _json(_comparison(files: _files(count))),
        );
        if (count < 300) {
          expect(result.isComplete, isTrue);
          expect(result.paths, hasLength(count));
        } else {
          _expectIncomplete(result, 'file_limit');
        }
      });
    }

    for (final (name, patch, reason) in [
      (
        'base mismatch',
        {
          'base_commit': {'sha': _other},
        },
        'sha_mismatch',
      ),
      (
        'head mismatch',
        {
          'commits': [
            {'sha': _other},
          ],
        },
        'sha_mismatch',
      ),
      ('missing commits', {'commits': []}, 'sha_mismatch'),
      (
        'missing head SHA',
        {
          'commits': [{}],
        },
        'sha_mismatch',
      ),
      ('diverged', {'status': 'diverged'}, 'non_fast_forward'),
      ('behind', {'status': 'behind'}, 'non_fast_forward'),
      (
        'merge base mismatch',
        {
          'merge_base_commit': {'sha': _other},
        },
        'non_fast_forward',
      ),
      ('missing files', {'files': null}, 'invalid_response'),
    ]) {
      test('rejects a $name response', () async {
        final result = await fetch(
          handle: (_) async => _json({..._comparison(), ...patch}),
        );
        _expectIncomplete(result, reason);
      });
    }
  });

  group('indeterminate responses', () {
    for (final status in [401, 403, 404, 429, 500, 503]) {
      test('HTTP $status never returns a complete empty list', () async {
        final result = await fetch(
          handle: (_) async => _json({'message': 'error'}, status: status),
        );
        _expectIncomplete(result, 'github_http_$status');
      });
    }

    test(
      'authentication failure is indeterminate without exposing response data',
      () async {
        final result = await fetch(
          authenticate: () async =>
              _json({'message': 'sensitive-data'}, status: 403),
          handle: (_) async => fail('Unexpected file request'),
        );
        _expectIncomplete(result, 'github_authentication_failed');
        expect(jsonEncode(result.toJson()), isNot(contains('sensitive-data')));
      },
    );

    for (final stage in ['authentication', 'files']) {
      test('bounds a stalled $stage request', () async {
        final stalled = Completer<http.Response>();
        final result = await fetch(
          authenticate: stage == 'authentication' ? () => stalled.future : null,
          handle: (_) => stalled.future,
          timeout: const Duration(milliseconds: 20),
        );
        _expectIncomplete(result, 'github_timeout');
      });
    }

    test('connection errors are indeterminate', () async {
      final result = await fetch(
        handle: (_) async => throw http.ClientException('offline'),
      );
      _expectIncomplete(result, 'github_unavailable');
    });

    for (final files in [
      [_file('lib/new.dart', status: 'renamed')],
      [_file('/absolute.dart')],
      [_file('../outside.dart')],
      [_file('lib/file.dart', status: 'unknown')],
      [
        {'filename': 'lib/file.dart'},
      ],
      [null],
    ]) {
      test('rejects malformed file records: $files', () async {
        final result = await fetch(
          handle: (_) async => _json(_comparison(files: files)),
        );
        _expectIncomplete(result, 'invalid_response');
      });
    }

    test('malformed JSON from GitHub is indeterminate', () async {
      final result = await fetch(
        handle: (_) async => http.Response('not-json', 200),
      );
      _expectIncomplete(result, 'invalid_response');
    });

    test('malformed authentication data is indeterminate', () async {
      final result = await fetch(
        authenticate: () async => _json({'token': null}, status: 201),
        handle: (_) async => fail('Unexpected file request'),
      );
      _expectIncomplete(result, 'invalid_response');
    });

    test('an empty installation token is indeterminate', () async {
      final result = await fetch(
        authenticate: () async => _json({'token': ''}, status: 201),
        handle: (_) async => fail('Unexpected file request'),
      );
      _expectIncomplete(result, 'invalid_response');
    });

    test('missing GitHub configuration is indeterminate', () async {
      environment.clear();
      final result = await fetch(
        handle: (_) async => fail('Unexpected file request'),
      );
      _expectIncomplete(result, 'github_not_configured');
    });
  });
}

Map<String, dynamic> _pushPayload() => {
  'repository': {
    'owner': {'login': 'openci-org'},
    'name': 'openci',
  },
  'installation': {'id': 42},
  'before': _base,
  'after': _head,
  'created': false,
  'deleted': false,
  'forced': false,
};

Map<String, dynamic> _prPayload() => {
  ..._pushPayload(),
  'number': 7,
  'pull_request': {
    'base': {'sha': _base},
    'head': {'sha': _head},
    'changed_files': 1,
  },
};

Map<String, dynamic> _snapshot(int count) => {
  'base': {'sha': _base},
  'head': {'sha': _head},
  'changed_files': count,
  'updated_at': '2026-10-03T00:00:00Z',
};

Map<String, dynamic> _comparison({List? files}) => {
  'base_commit': {'sha': _base},
  'merge_base_commit': {'sha': _base},
  'status': 'ahead',
  'commits': [
    {'sha': _head},
  ],
  'files': files ?? _files(1),
};

Map<String, dynamic> _file(
  String name, {
  String status = 'modified',
  String? previous,
}) => {
  'filename': name,
  'status': status,
  'previous_filename': ?previous,
};

List<Map<String, dynamic>> _files(int count, {int offset = 0}) =>
    List.generate(count, (index) => _file('lib/file${offset + index}.dart'));

http.Response _json(
  Object data, {
  int status = 200,
  Map<String, String>? headers,
}) => http.Response(
  jsonEncode(data),
  status,
  headers: {
    'content-type': 'application/json',
    ...?headers,
  },
);

void _expectIncomplete(ChangedFilesResult result, String reason) {
  expect(result.isComplete, isFalse);
  expect(result.paths, isEmpty);
  expect(result.reason, reason);
}
