import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_server/auth/internal_api_key_validator.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/github_connection_table.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

import '../../../../routes/builds/[id]/_middleware.dart' as build;
import '../../../../routes/builds/[id]/token.dart' as route;
import '../../../helpers/github_app_test_key.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late Map<String, String> environment;
  late List<http.Request> githubRequests;

  final job = DriftBuildJob(
    id: 'job-1',
    teamId: 'team-1',
    owner: 'owner',
    repo: 'repo',
    installationId: '54321',
    githubBaseUrl: 'https://untrusted.example',
    status: BuildJobStatus.IN_PROGRESS,
    workflowName: 'CI',
    workflowFileName: 'ci.dart',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
  final connection = DriftGitHubConnection(
    id: 'connection-1',
    teamId: 'team-1',
    githubApiBaseUrl: 'https://api.github.com',
    githubAppId: 123456,
    installationId: 54321,
    accountId: 42,
    accountType: GitHubAccountType.organization,
    accountLogin: 'owner',
    verifiedByUserId: 'member-1',
    verifiedByGitHubUserId: 100,
    verifiedAt: DateTime.utc(2026),
    status: GitHubConnectionStatus.active,
  );

  setUp(() async {
    db = AppDatabase(
      NativeDatabase.memory(
        setup: (database) => database.execute('PRAGMA foreign_keys = ON'),
      ),
    );
    await db.teamDao.createTeamAndMember(
      DriftTeam(
        id: 'team-1',
        name: 'OpenCI',
        installationIds: const [98765],
        aiEnabled: false,
        runNumber: 1,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
      'member-1',
    );
    await db.buildJobDao.insertBuildJob(job);
    await db.into(db.gitHubConnections).insert(connection);

    tempDir = await Directory.systemTemp.createTemp('job_token_test_');
    final keyFile = File('${tempDir.path}/key.pem');
    await keyFile.writeAsString(testRsaPrivateKey);
    environment = {
      'GITHUB_APP_ID': '123456',
      'GITHUB_PRIVATE_KEY_PATH': keyFile.path,
      'GITHUB_API_BASE_URL': 'https://api.github.com',
    };
    githubRequests = [];
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  Future<http.Response> get({
    String? uid,
    String? bearerToken = 'test-internal-key',
    String method = 'GET',
    http.Response Function(http.Request)? respond,
  }) async {
    final githubClient = MockClient((request) async {
      githubRequests.add(request);
      if (respond != null) return respond(request);
      return switch (request.url.path) {
        '/repos/owner/repo/installation' => http.Response(
          jsonEncode({'id': 54321}),
          200,
        ),
        '/app/installations/54321/access_tokens' => http.Response(
          jsonEncode({'token': 'test-installation-token'}),
          200,
        ),
        _ => http.Response('Unexpected GitHub request', 500),
      };
    });
    addTearDown(githubClient.close);

    final handler =
        ((RequestContext context) => route.onRequest(context, 'job-1'))
            .use(build.middleware)
            .use(provider<AppDatabase>((_) => db))
            .use(provider<String?>((_) => uid))
            .use(provider<Map<String, String>>((_) => environment))
            .use(provider<http.Client>((_) => githubClient))
            .use(
              provider<InternalApiKeyValidator>(
                (_) => const InternalApiKeyValidator(
                  environment: {'INTERNAL_API_KEY': 'test-internal-key'},
                ),
              ),
            );
    final server = await serve(handler, InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final client = http.Client();
    addTearDown(client.close);
    final request = http.Request(
      method,
      Uri(
        scheme: 'http',
        host: server.address.address,
        port: server.port,
        path: '/builds/job-1/token',
      ),
    );
    if (bearerToken != null) {
      request.headers[HttpHeaders.authorizationHeader] = 'Bearer $bearerToken';
    }
    return http.Response.fromStream(await client.send(request));
  }

  Future<void> expectConnectionRejected(
    DriftGitHubConnection rejectedConnection,
  ) async {
    await db.update(db.gitHubConnections).replace(rejectedConnection);

    final response = await get();

    expect(response.statusCode, HttpStatus.forbidden);
    expect(jsonDecode(response.body), {'success': false, 'error': 'Forbidden'});
    expect(githubRequests, isEmpty);
  }

  test(
    'an internal key gets a token through a new verified connection',
    () async {
      final team = (await db.teamDao.getTeam('team-1'))!;
      await db.teamDao.updateTeam(team.copyWith(installationIds: []));

      final response = await get();

      expect(response.statusCode, HttpStatus.ok);
      expect(jsonDecode(response.body), {'token': 'test-installation-token'});
      expect(response.headers[HttpHeaders.cacheControlHeader], 'no-store');
      expect(githubRequests.map((request) => request.url.toString()), [
        'https://api.github.com/repos/owner/repo/installation',
        'https://api.github.com/app/installations/54321/access_tokens',
      ]);
      expect(githubRequests.map((request) => request.method), ['GET', 'POST']);
    },
  );

  test('a team member can get a token without an internal key', () async {
    final response = await get(uid: 'member-1', bearerToken: null);

    expect(response.statusCode, HttpStatus.ok);
    expect(jsonDecode(response.body), {'token': 'test-installation-token'});
  });

  test('rejects an unauthenticated caller before contacting GitHub', () async {
    final response = await get(bearerToken: null);

    expect(response.statusCode, HttpStatus.unauthorized);
    expect(githubRequests, isEmpty);
  });

  test('rejects a non-member before contacting GitHub', () async {
    final response = await get(uid: 'other-user', bearerToken: null);

    expect(response.statusCode, HttpStatus.forbidden);
    expect(githubRequests, isEmpty);
  });

  test('rejects unsupported methods', () async {
    final response = await get(method: 'POST');

    expect(response.statusCode, HttpStatus.methodNotAllowed);
    expect(githubRequests, isEmpty);
  });

  test('rejects a job without an installation ID', () async {
    await db.buildJobDao.updateBuildJob(
      job.copyWith(installationId: const Value(null)),
    );

    final response = await get();

    expect(response.statusCode, HttpStatus.badRequest);
    expect(githubRequests, isEmpty);
  });

  test('rejects an invalid installation ID before contacting GitHub', () async {
    await db.buildJobDao.updateBuildJob(
      job.copyWith(installationId: const Value('../other')),
    );

    final response = await get();

    expect(response.statusCode, HttpStatus.badRequest);
    expect(githubRequests, isEmpty);
  });

  test(
    'rejects a stored job that only has a legacy team installation ID',
    () async {
      await db.buildJobDao.updateBuildJob(
        job.copyWith(installationId: const Value('98765')),
      );

      final response = await get();

      expect(response.statusCode, HttpStatus.forbidden);
      expect(githubRequests, isEmpty);
    },
  );

  test('rejects a stored job when its connection no longer exists', () async {
    await db.delete(db.gitHubConnections).go();

    final response = await get();

    expect(response.statusCode, HttpStatus.forbidden);
    expect(githubRequests, isEmpty);
  });

  test('rejects a connection belonging to another team', () async {
    final team = (await db.teamDao.getTeam('team-1'))!;
    await db.into(db.teams).insert(team.copyWith(id: 'other-team'));

    await expectConnectionRejected(connection.copyWith(teamId: 'other-team'));
  });

  test('rejects a suspended connection', () async {
    await expectConnectionRejected(
      connection.copyWith(status: GitHubConnectionStatus.suspended),
    );
  });

  test('rejects a removed connection', () async {
    await expectConnectionRejected(
      connection.copyWith(status: GitHubConnectionStatus.removed),
    );
  });

  test('rejects a connection for another GitHub API host', () async {
    await expectConnectionRejected(
      connection.copyWith(githubApiBaseUrl: 'https://github.example/api/v3'),
    );
  });

  test('rejects a connection for another GitHub App', () async {
    await expectConnectionRejected(connection.copyWith(githubAppId: 42));
  });

  test('rejects a repository that belongs to another installation', () async {
    final response = await get(
      respond: (_) => http.Response(jsonEncode({'id': 99999}), 200),
    );

    expect(response.statusCode, HttpStatus.forbidden);
    expect(jsonDecode(response.body), {'success': false, 'error': 'Forbidden'});
    expect(githubRequests, hasLength(1));
    expect(githubRequests.single.method, 'GET');
    expect(githubRequests.single.url.path, '/repos/owner/repo/installation');
  });

  test(
    'fails without issuing a token when GitHub denies repository access',
    () async {
      final response = await get(
        respond: (_) => http.Response('private permission detail', 403),
      );

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(jsonDecode(response.body), {
        'success': false,
        'error': 'Internal server error',
      });
      expect(githubRequests, hasLength(1));
      expect(githubRequests.single.url.path, '/repos/owner/repo/installation');
    },
  );

  test(
    'does not return a dummy token when GitHub refuses token issuance',
    () async {
      await db.buildJobDao.updateBuildJob(
        job.copyWith(installationId: const Value('12345678')),
      );
      await db
          .update(db.gitHubConnections)
          .replace(
            connection.copyWith(installationId: 12345678),
          );

      final response = await get(
        respond: (request) => request.method == 'GET'
            ? http.Response(jsonEncode({'id': 12345678}), 200)
            : http.Response('private token failure', 403),
      );

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(jsonDecode(response.body), {
        'success': false,
        'error': 'Internal server error',
      });
      expect(githubRequests.map((request) => request.url.path), [
        '/repos/owner/repo/installation',
        '/app/installations/12345678/access_tokens',
      ]);
    },
  );

  test(
    'does not return a dummy token when the private key is missing',
    () async {
      environment.remove('GITHUB_PRIVATE_KEY_PATH');

      final response = await get();

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(jsonDecode(response.body), {
        'success': false,
        'error': 'Internal server error',
      });
      expect(githubRequests, isEmpty);
    },
  );

  test('rejects an empty token returned by GitHub', () async {
    final response = await get(
      respond: (request) => request.method == 'GET'
          ? http.Response(jsonEncode({'id': 54321}), 200)
          : http.Response(jsonEncode({'token': ''}), 200),
    );

    expect(response.statusCode, HttpStatus.internalServerError);
    expect(jsonDecode(response.body), {
      'success': false,
      'error': 'Internal server error',
    });
    expect(githubRequests, hasLength(2));
  });

  test(
    'reports a connection database failure without contacting GitHub',
    () async {
      await db.customStatement('DROP TABLE github_connections');

      final response = await get();

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(jsonDecode(response.body), {
        'success': false,
        'error': 'Internal server error',
      });
      expect(githubRequests, isEmpty);
    },
  );

  test(
    'uses the normalized operator API URL for lookup and token issuance',
    () async {
      environment['GITHUB_API_BASE_URL'] =
          ' https://github.example:8443/api/v3/// ';
      await db
          .update(db.gitHubConnections)
          .replace(
            connection.copyWith(
              githubApiBaseUrl: 'https://github.example:8443/api/v3',
            ),
          );

      final response = await get(
        respond: (request) => request.method == 'GET'
            ? http.Response(jsonEncode({'id': 54321}), 200)
            : http.Response(jsonEncode({'token': 'ghes-test-token'}), 200),
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(jsonDecode(response.body), {'token': 'ghes-test-token'});
      expect(githubRequests.map((request) => request.url.toString()), [
        'https://github.example:8443/api/v3/repos/owner/repo/installation',
        'https://github.example:8443/api/v3/app/installations/54321/access_tokens',
      ]);
    },
  );
}
