import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_server/auth/internal_api_key_validator.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/github_connection_table.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

import '../../../../../routes/webhooks/_middleware.dart' as webhooks;
import '../../../../../routes/webhooks/tasks/[id]/changed-files.dart' as route;
import '../../../../helpers/github_app_test_key.dart';

const _base = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _head = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

void main() {
  late AppDatabase db;
  late Directory directory;
  late Map<String, String> environment;
  late List<http.Request> requests;
  final connection = DriftGitHubConnection(
    id: 'connection-1',
    teamId: 'team-1',
    githubApiBaseUrl: 'https://api.github.test',
    githubAppId: 42,
    installationId: 42,
    accountId: 100,
    accountType: GitHubAccountType.organization,
    accountLogin: 'openci-org',
    verifiedByUserId: 'user-1',
    verifiedByGitHubUserId: 200,
    verifiedAt: DateTime.utc(2026),
    status: GitHubConnectionStatus.active,
  );

  setUp(() async {
    requests = [];
    db = AppDatabase(
      NativeDatabase.memory(
        setup: (database) => database.execute('PRAGMA foreign_keys = ON'),
      ),
    );
    await db.teamDao.createTeamAndMember(
      DriftTeam(
        id: 'team-1',
        name: 'OpenCI',
        installationIds: const [42, 12345678],
        aiEnabled: false,
        runNumber: 1,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
      'user-1',
    );
    await db.into(db.gitHubConnections).insert(connection);
    directory = await Directory.systemTemp.createTemp('changed-files-route-');
    final key = await File(
      '${directory.path}/key.pem',
    ).writeAsString(testRsaPrivateKey);
    environment = {
      'GITHUB_API_BASE_URL': 'https://api.github.test',
      'GITHUB_APP_ID': '42',
      'GITHUB_PRIVATE_KEY_PATH': key.path,
    };
  });
  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });

  Future<Response> request({
    HttpMethod method = HttpMethod.get,
    String? token = 'test-internal-key',
    bool provideDatabase = true,
    Future<http.Response> Function(http.Request)? handle,
  }) async {
    final client = MockClient((request) async {
      requests.add(request);
      return handle == null ? _githubResponse(request) : await handle(request);
    });
    addTearDown(client.close);
    final context = TestRequestContext(
      path: '/webhooks/tasks/task-1/changed-files',
      method: method,
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );
    if (provideDatabase) context.provide<AppDatabase>(db);
    context.provide<http.Client>(client);
    context.provide<Map<String, String>>(environment);
    context.provide<String?>('user-1');
    context.provide<InternalApiKeyValidator>(
      const InternalApiKeyValidator(
        environment: {'INTERNAL_API_KEY': 'test-internal-key'},
      ),
    );
    return webhooks.middleware((context) => route.onRequest(context, 'task-1'))(
      context.context,
    );
  }

  Future<void> insertTask({
    String? payload,
    String eventType = 'push',
    Map<String, dynamic> payloadOverrides = const {},
  }) async {
    final now = DateTime.now().toUtc();
    await db.webhookTaskDao.insertWebhookTask(
      DriftWebhookTask(
        id: 'task-1',
        deliveryId: 'delivery-1',
        eventType: eventType,
        payload:
            payload ??
            jsonEncode({
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
              ...payloadOverrides,
            }),
        status: 'processing',
        retryCount: 0,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  group('GET /webhooks/tasks/[id]/changed-files', () {
    for (final token in [null, '', 'wrong-key', 'firebase-token']) {
      test('rejects "$token" before accessing the database', () async {
        final response = await request(token: token, provideDatabase: false);
        expect(response.statusCode, HttpStatus.unauthorized);
        expect(requests, isEmpty);
      });
    }

    test('rejects methods other than GET', () async {
      final response = await request(
        method: HttpMethod.post,
        provideDatabase: false,
      );
      expect(response.statusCode, HttpStatus.methodNotAllowed);
      expect(requests, isEmpty);
    });

    test('returns 404 for a missing task', () async {
      final response = await request();
      expect(response.statusCode, HttpStatus.notFound);
      expect(requests, isEmpty);
    });

    test(
      'returns the stored webhook diff without changing task state',
      () async {
        await insertTask();
        final before = await db.webhookTaskDao.getWebhookTask('task-1');
        final response = await request();
        expect(response.statusCode, HttpStatus.ok);
        final result = ChangedFilesResult.fromJson(
          await response.json() as Map<String, dynamic>,
        );
        expect(result.isComplete, isTrue);
        expect(result.paths, ['lib/main.dart']);
        expect(result.baseSha, _base);
        expect(result.headSha, _head);
        expect(await db.webhookTaskDao.getWebhookTask('task-1'), before);
        expect(requests.map((request) => request.url.toString()), [
          'https://api.github.test/repos/openci-org/openci/installation',
          'https://api.github.test/app/installations/42/access_tokens',
          'https://api.github.test/repos/openci-org/openci/compare/$_base...$_head',
        ]);
        expect(requests.map((request) => request.method), [
          'GET',
          'POST',
          'GET',
        ]);
        expect(requests[0].headers['Authorization'], startsWith('Bearer ey'));
        expect(requests[1].headers['Authorization'], startsWith('Bearer ey'));
        expect(
          requests[2].headers['Authorization'],
          'Bearer installation-token',
        );
      },
    );

    test(
      'fetches a pull request diff through the verified connection',
      () async {
        await insertTask(
          eventType: 'pull_request',
          payloadOverrides: {
            'number': 7,
            'pull_request': {
              'base': {'sha': _base},
              'head': {'sha': _head},
            },
          },
        );

        final response = await request();

        expect(response.statusCode, HttpStatus.ok);
        final result = ChangedFilesResult.fromJson(
          await response.json() as Map<String, dynamic>,
        );
        expect(result.isComplete, isTrue);
        expect(result.paths, ['lib/main.dart']);
        expect(requests.map((request) => request.url.path), [
          '/repos/openci-org/openci/installation',
          '/app/installations/42/access_tokens',
          '/repos/openci-org/openci/pulls/7',
          '/repos/openci-org/openci/pulls/7/files',
          '/repos/openci-org/openci/pulls/7',
        ]);
      },
    );

    test(
      'rejects legacy installation IDs without a verified connection',
      () async {
        await db.delete(db.gitHubConnections).go();
        await insertTask();

        final response = await request();

        expect(response.statusCode, HttpStatus.forbidden);
        expect(await response.json(), {'success': false, 'error': 'Forbidden'});
        expect(requests, isEmpty);
      },
    );

    test('rejects the former dummy installation ID', () async {
      await insertTask(
        payloadOverrides: {
          'installation': {'id': 12345678},
        },
      );

      final response = await request();

      expect(response.statusCode, HttpStatus.forbidden);
      expect(requests, isEmpty);
    });

    test('rejects a suspended connection before contacting GitHub', () async {
      await db
          .update(db.gitHubConnections)
          .replace(
            connection.copyWith(status: GitHubConnectionStatus.suspended),
          );
      await insertTask();

      final response = await request();

      expect(response.statusCode, HttpStatus.forbidden);
      expect(requests, isEmpty);
    });

    test('rejects a removed connection before contacting GitHub', () async {
      await db
          .update(db.gitHubConnections)
          .replace(
            connection.copyWith(status: GitHubConnectionStatus.removed),
          );
      await insertTask();

      final response = await request();

      expect(response.statusCode, HttpStatus.forbidden);
      expect(requests, isEmpty);
    });

    test('rejects a connection for another GitHub host', () async {
      await db
          .update(db.gitHubConnections)
          .replace(
            connection.copyWith(githubApiBaseUrl: 'https://other.github.test'),
          );
      await insertTask();

      final response = await request();

      expect(response.statusCode, HttpStatus.forbidden);
      expect(requests, isEmpty);
    });

    test('rejects a connection for another GitHub App', () async {
      await db
          .update(db.gitHubConnections)
          .replace(
            connection.copyWith(githubAppId: 99),
          );
      await insertTask();

      final response = await request();

      expect(response.statusCode, HttpStatus.forbidden);
      expect(requests, isEmpty);
    });

    test('rejects a connection belonging to a deleted team', () async {
      await db.teamDao.deleteTeam('team-1');
      await insertTask();

      final response = await request();

      expect(response.statusCode, HttpStatus.forbidden);
      expect(requests, isEmpty);
    });

    test(
      'rejects a repository installation mismatch before issuing a token',
      () async {
        await insertTask();

        final response = await request(
          handle: (_) async => http.Response('{"id":99}', HttpStatus.ok),
        );

        expect(response.statusCode, HttpStatus.forbidden);
        expect(await response.json(), {'success': false, 'error': 'Forbidden'});
        expect(requests, hasLength(1));
        expect(
          requests.single.url.path,
          '/repos/openci-org/openci/installation',
        );
      },
    );

    test(
      'uses the same normalized GHES URL for validation and diff requests',
      () async {
        environment['GITHUB_API_BASE_URL'] =
            ' https://github.enterprise.test:8443/api/v3/// ';
        environment['GITHUB_APP_ID'] = ' 42 ';
        await db
            .update(db.gitHubConnections)
            .replace(
              connection.copyWith(
                githubApiBaseUrl: 'https://github.enterprise.test:8443/api/v3',
              ),
            );
        await insertTask();

        final response = await request();

        expect(response.statusCode, HttpStatus.ok);
        expect(requests.map((request) => request.url.toString()), [
          'https://github.enterprise.test:8443/api/v3/repos/openci-org/openci/installation',
          'https://github.enterprise.test:8443/api/v3/app/installations/42/access_tokens',
          'https://github.enterprise.test:8443/api/v3/repos/openci-org/openci/compare/$_base...$_head',
        ]);
      },
    );

    test('returns a generic error for a malformed stored payload', () async {
      await insertTask(payload: 'not-json');

      final response = await request();

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(await response.json(), {
        'success': false,
        'error': 'Internal server error',
      });
      expect(requests, isEmpty);
    });

    test(
      'rejects missing installation metadata without contacting GitHub',
      () async {
        await insertTask(payloadOverrides: {'installation': null});

        final response = await request();

        expect(response.statusCode, HttpStatus.internalServerError);
        expect(requests, isEmpty);
      },
    );

    test(
      'rejects a nonpositive installation ID without contacting GitHub',
      () async {
        await insertTask(
          payloadOverrides: {
            'installation': {'id': 0},
          },
        );

        final response = await request();

        expect(response.statusCode, HttpStatus.internalServerError);
        expect(requests, isEmpty);
      },
    );

    test(
      'rejects missing repository metadata without contacting GitHub',
      () async {
        await insertTask(payloadOverrides: {'repository': null});

        final response = await request();

        expect(response.statusCode, HttpStatus.internalServerError);
        expect(requests, isEmpty);
      },
    );

    test(
      'rejects missing operator configuration without contacting GitHub',
      () async {
        await insertTask();
        environment.remove('GITHUB_API_BASE_URL');

        final response = await request();

        expect(response.statusCode, HttpStatus.internalServerError);
        expect(requests, isEmpty);
      },
    );

    test(
      'rejects an invalid operator App ID without contacting GitHub',
      () async {
        await insertTask();
        environment['GITHUB_APP_ID'] = '0x2a';

        final response = await request();

        expect(response.statusCode, HttpStatus.internalServerError);
        expect(requests, isEmpty);
      },
    );

    test('fails if connection lookup in the database is unavailable', () async {
      await insertTask();
      await db.customStatement('DROP TABLE github_connections');

      final response = await request();

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(await response.json(), {
        'success': false,
        'error': 'Internal server error',
      });
      expect(requests, isEmpty);
    });

    test('fails if GitHub denies repository installation lookup', () async {
      await insertTask();

      final response = await request(
        handle: (_) async => http.Response('private GitHub error', 403),
      );

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(await response.json(), {
        'success': false,
        'error': 'Internal server error',
      });
      expect(requests, hasLength(1));
    });

    test('fails if GitHub no longer has the repository installation', () async {
      await insertTask();

      final response = await request(
        handle: (_) async => http.Response('not found', 404),
      );

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(requests, hasLength(1));
    });

    test('fails on a malformed repository installation response', () async {
      await insertTask();

      final response = await request(
        handle: (_) async => http.Response('{"id":null}', 200),
      );

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(requests, hasLength(1));
    });

    test(
      'fails if GitHub denies token issuance without requesting files',
      () async {
        await insertTask();
        final before = await db.webhookTaskDao.getWebhookTask('task-1');

        final response = await request(
          handle: (request) async {
            if (request.method == 'POST') {
              return http.Response('private token error', 403);
            }
            return _githubResponse(request);
          },
        );

        expect(response.statusCode, HttpStatus.internalServerError);
        expect(await response.json(), {
          'success': false,
          'error': 'Internal server error',
        });
        expect(requests, hasLength(2));
        expect(await db.webhookTaskDao.getWebhookTask('task-1'), before);
      },
    );

    test('fails if GitHub returns an empty installation token', () async {
      await insertTask();

      final response = await request(
        handle: (request) async {
          if (request.method == 'POST') {
            return http.Response('{"token":""}', 201);
          }
          return _githubResponse(request);
        },
      );

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(requests, hasLength(2));
    });

    test('fails if GitHub denies access to changed files', () async {
      await insertTask();

      final response = await request(
        handle: (request) async {
          if (request.url.path.contains('/compare/')) {
            return http.Response('private repository error', 403);
          }
          return _githubResponse(request);
        },
      );

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(await response.json(), {
        'success': false,
        'error': 'Internal server error',
      });
      expect(requests, hasLength(3));
    });

    test('fails on a malformed GitHub diff response', () async {
      await insertTask();

      final response = await request(
        handle: (request) async {
          if (request.url.path.contains('/compare/')) {
            return http.Response('not-json', 200);
          }
          return _githubResponse(request);
        },
      );

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(requests, hasLength(3));
    });

    test(
      'does not return a successful fallback after a GitHub timeout',
      () async {
        await insertTask();

        final response = await request(
          handle: (request) async {
            if (request.url.path.contains('/compare/')) {
              throw TimeoutException('private timeout detail');
            }
            return _githubResponse(request);
          },
        );

        expect(response.statusCode, HttpStatus.internalServerError);
        expect(await response.json(), {
          'success': false,
          'error': 'Internal server error',
        });
      },
    );

    test('preserves an indeterminate diff for a verified new branch', () async {
      await insertTask(payloadOverrides: {'created': true, 'before': '0' * 40});

      final response = await request();

      expect(response.statusCode, HttpStatus.ok);
      final result = ChangedFilesResult.fromJson(
        await response.json() as Map<String, dynamic>,
      );
      expect(result.isComplete, isFalse);
      expect(result.paths, isEmpty);
      expect(result.reason, 'new_branch');
      expect(requests, hasLength(1));
    });
  });
}

http.Response _githubResponse(http.Request request) {
  if (request.method == 'GET' && request.url.path.endsWith('/installation')) {
    return http.Response('{"id":42}', HttpStatus.ok);
  }
  if (request.method == 'POST' &&
      request.url.path.endsWith('/app/installations/42/access_tokens')) {
    return http.Response('{"token":"installation-token"}', HttpStatus.created);
  }
  if (request.method == 'GET' &&
      request.url.path.endsWith('/compare/$_base...$_head')) {
    return http.Response(
      jsonEncode({
        'base_commit': {'sha': _base},
        'merge_base_commit': {'sha': _base},
        'status': 'ahead',
        'commits': [
          {'sha': _head},
        ],
        'files': [
          {'filename': 'lib/main.dart', 'status': 'modified'},
        ],
      }),
      HttpStatus.ok,
    );
  }
  if (request.method == 'GET' && request.url.path.endsWith('/pulls/7')) {
    return http.Response(
      jsonEncode({
        'base': {'sha': _base},
        'head': {'sha': _head},
        'changed_files': 1,
        'updated_at': '2026-01-01T00:00:00Z',
      }),
      HttpStatus.ok,
    );
  }
  if (request.method == 'GET' && request.url.path.endsWith('/pulls/7/files')) {
    return http.Response(
      jsonEncode([
        {'filename': 'lib/main.dart', 'status': 'modified'},
      ]),
      HttpStatus.ok,
    );
  }
  throw StateError(
    'Unexpected GitHub request: ${request.method} ${request.url}',
  );
}
