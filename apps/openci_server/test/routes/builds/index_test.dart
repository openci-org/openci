import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_server/auth/internal_api_key_validator.dart';
import 'package:openci_server/build_job/build_job_mapper.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/github_connection_table.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

import '../../helpers/database_failure_checks.dart';
import '../../helpers/github_app_test_key.dart';
import '../../../routes/builds/index.dart' as route;

class MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(
      NativeDatabase.memory(
        setup: (database) => database.execute('PRAGMA foreign_keys = ON'),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('POST /builds', () {
    test(
      'rejects a missing key before parsing the body or accessing the database',
      () async {
        final mockDb = MockAppDatabase();
        final context = TestRequestContext(
          path: '/builds',
          method: HttpMethod.post,
          body: 'not-a-json',
        );

        context.provide<AppDatabase>(mockDb);
        context.provide<String?>(null);
        context.provide<InternalApiKeyValidator>(
          const InternalApiKeyValidator(
            environment: {'INTERNAL_API_KEY': 'test-internal-key'},
          ),
        );

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.unauthorized));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Authentication required'));
        verifyZeroInteractions(mockDb);
        verifyNever(() => context.context.read<AppDatabase>());
      },
    );

    test(
      'rejects an incorrect key before parsing the body or accessing the database',
      () async {
        final mockDb = MockAppDatabase();
        final context = TestRequestContext(
          path: '/builds',
          method: HttpMethod.post,
          headers: {'Authorization': 'Bearer incorrect-key'},
          body: 'not-a-json',
        );
        context.provide<AppDatabase>(mockDb);
        context.provide<String?>('system-job-processor');
        context.provide<InternalApiKeyValidator>(
          const InternalApiKeyValidator(
            environment: {'INTERNAL_API_KEY': 'test-internal-key'},
          ),
        );

        final response = await route.onRequest(context.context);

        expect(response.statusCode, HttpStatus.unauthorized);
        verifyZeroInteractions(mockDb);
        verifyNever(() => context.context.read<AppDatabase>());
      },
    );

    test(
      'responds with 400 Bad Request when body is invalid JSON',
      () async {
        final context = TestRequestContext(
          path: '/builds',
          method: HttpMethod.post,
          body: 'not-a-json',
          headers: {'Authorization': 'Bearer test-internal-key'},
        );

        context.provide<AppDatabase>(db);
        context.provide<InternalApiKeyValidator>(
          const InternalApiKeyValidator(
            environment: {'INTERNAL_API_KEY': 'test-internal-key'},
          ),
        );

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.badRequest));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], contains('Invalid JSON'));
      },
    );

    test(
      'responds with 400 Bad Request when body is not a JSON object',
      () async {
        final context = TestRequestContext(
          path: '/builds',
          method: HttpMethod.post,
          body: '"just a string"',
          headers: {'Authorization': 'Bearer test-internal-key'},
        );

        context.provide<AppDatabase>(db);
        context.provide<InternalApiKeyValidator>(
          const InternalApiKeyValidator(
            environment: {'INTERNAL_API_KEY': 'test-internal-key'},
          ),
        );

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.badRequest));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], contains('Body must be a JSON object'));
      },
    );

    test(
      'responds with 400 Bad Request when payload structure is invalid (missing required fields)',
      () async {
        final context = TestRequestContext(
          path: '/builds',
          method: HttpMethod.post,
          body: '{"invalid": "field"}',
          headers: {'Authorization': 'Bearer test-internal-key'},
        );

        context.provide<AppDatabase>(db);
        context.provide<InternalApiKeyValidator>(
          const InternalApiKeyValidator(
            environment: {'INTERNAL_API_KEY': 'test-internal-key'},
          ),
        );

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.badRequest));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], contains('Invalid payload structure'));
      },
    );

    test(
      'rejects the former internal UID without a valid key',
      () async {
        final payload = {
          'id': 'job-123',
          'status': 'QUEUED',
          'owner': 'owner',
          'repo': 'repo',
          'workflowName': 'workflow',
          'workflowFileName': 'ci.yml',
          'teamId': null,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        };

        final context = TestRequestContext(
          path: '/builds',
          method: HttpMethod.post,
          body: jsonEncode(payload),
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('system-job-processor');
        context.provide<InternalApiKeyValidator>(
          const InternalApiKeyValidator(
            environment: {'INTERNAL_API_KEY': 'test-internal-key'},
          ),
        );

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.unauthorized));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Authentication required'));
        expect(await db.buildJobDao.getBuildJob('job-123'), isNull);
      },
    );

    test(
      'rejects a team member without a valid internal key',
      () async {
        final team = DriftTeam(
          id: 'team-xyz',
          name: 'Team XYZ',
          installationIds: const [],
          runNumber: 1,
          aiEnabled: true,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );

        await db.teamDao.createTeamAndMember(team, 'user-123');

        final payload = {
          'id': 'job-123',
          'status': 'QUEUED',
          'owner': 'owner',
          'repo': 'repo',
          'workflowName': 'workflow',
          'workflowFileName': 'ci.yml',
          'teamId': 'team-xyz',
          'createdAt': DateTime.now().toUtc().toIso8601String(),
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        };

        final context = TestRequestContext(
          path: '/builds',
          method: HttpMethod.post,
          body: jsonEncode(payload),
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');
        context.provide<InternalApiKeyValidator>(
          const InternalApiKeyValidator(
            environment: {'INTERNAL_API_KEY': 'test-internal-key'},
          ),
        );

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.unauthorized));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Authentication required'));
        expect(await db.buildJobDao.getBuildJob('job-123'), isNull);
      },
    );

    group('verified GitHub connections', () {
      late Directory tempDir;
      late Map<String, String> environment;
      late List<http.Request> githubRequests;

      final job = BuildJob(
        id: 'job-123',
        status: BuildJobStatus.QUEUED,
        owner: 'owner',
        repo: 'repo',
        workflowName: 'workflow',
        workflowFileName: 'ci.dart',
        teamId: 'team-xyz',
        githubBaseUrl: 'https://untrusted.example',
        commitSha: 'commit-sha',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      final connection = DriftGitHubConnection(
        id: 'connection-1',
        teamId: 'team-xyz',
        githubApiBaseUrl: 'https://api.github.com',
        githubAppId: 123456,
        installationId: 54321,
        accountId: 42,
        accountType: GitHubAccountType.organization,
        accountLogin: 'owner',
        verifiedByUserId: 'user-123',
        verifiedByGitHubUserId: 100,
        verifiedAt: DateTime.utc(2026),
        status: GitHubConnectionStatus.active,
      );

      setUp(() async {
        await db.teamDao.createTeamAndMember(
          DriftTeam(
            id: 'team-xyz',
            name: 'Team XYZ',
            installationIds: const [],
            runNumber: 1,
            aiEnabled: true,
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
          'user-123',
        );
        await db.into(db.gitHubConnections).insert(connection);
        tempDir = await Directory.systemTemp.createTemp('register_build_test_');
        final keyFile = File('${tempDir.path}/key.pem');
        await keyFile.writeAsString(testRsaPrivateKey);
        environment = {
          'GITHUB_APP_ID': '123456',
          'GITHUB_PRIVATE_KEY_PATH': keyFile.path,
          'GITHUB_API_BASE_URL': 'https://api.github.com',
        };
        githubRequests = [];
      });

      tearDown(() => tempDir.delete(recursive: true));

      Future<Response> post({
        Map<String, dynamic>? payload,
        http.Response Function(http.Request)? respond,
      }) async {
        final client = MockClient((request) async {
          githubRequests.add(request);
          return respond != null
              ? respond(request)
              : http.Response(jsonEncode({'id': 54321}), 200);
        });
        addTearDown(client.close);
        final context = TestRequestContext(
          path: '/builds',
          method: HttpMethod.post,
          body: jsonEncode(payload ?? job.toJson()),
          headers: {'Authorization': 'Bearer test-internal-key'},
        );
        context.provide<AppDatabase>(db);
        context.provide<Map<String, String>>(environment);
        context.provide<http.Client>(client);
        context.provide<InternalApiKeyValidator>(
          const InternalApiKeyValidator(
            environment: {'INTERNAL_API_KEY': 'test-internal-key'},
          ),
        );

        final response = await route.onRequest(context.context);

        verifyNever(() => context.context.read<String?>());
        return response;
      }

      Future<void> expectFailure(Response response) async {
        expect(response.statusCode, HttpStatus.internalServerError);
        expect(await response.json(), {
          'success': false,
          'error': 'Internal server error',
        });
        expect(await db.select(db.buildJobs).get(), isEmpty);
      }

      Future<void> expectConnectionRejected(
        DriftGitHubConnection rejectedConnection,
      ) async {
        await db.update(db.gitHubConnections).replace(rejectedConnection);

        final response = await post();

        expect(response.statusCode, HttpStatus.forbidden);
        expect(await response.json(), {'success': false, 'error': 'Forbidden'});
        expect(await db.select(db.buildJobs).get(), isEmpty);
        expect(githubRequests, isEmpty);
      }

      test(
        'saves the verified repository installation with an internal key and no UID',
        () async {
          final response = await post();

          expect(response.statusCode, HttpStatus.ok);
          expect(await response.json(), {'success': true, 'id': job.id});
          final inserted = (await db.buildJobDao.getBuildJob(job.id))!;
          expect(inserted.installationId, '54321');
          expect(inserted.checkRunId, isNull);
          expect(inserted.githubBaseUrl, 'https://github.com');
          expect(
            inserted.toShared().toJson(),
            job.copyWith(githubBaseUrl: 'https://github.com').toJson(),
          );
          expect(githubRequests, hasLength(1));
          expect(githubRequests.single.method, 'GET');
          expect(
            githubRequests.single.url.toString(),
            'https://api.github.com/repos/owner/repo/installation',
          );
        },
      );

      test('ignores caller supplied installation and check IDs', () async {
        final response = await post(
          payload: {
            ...job.toJson(),
            'installationId': '98765',
            'checkRunId': '99999',
          },
        );

        expect(response.statusCode, HttpStatus.ok);
        final inserted = (await db.buildJobDao.getBuildJob(job.id))!;
        expect(inserted.installationId, '54321');
        expect(inserted.checkRunId, isNull);
      });

      test(
        'selects the repository installation among multiple verified connections',
        () async {
          await db
              .into(db.gitHubConnections)
              .insert(
                connection.copyWith(id: 'connection-2', installationId: 65432),
              );

          final response = await post(
            respond: (_) => http.Response(jsonEncode({'id': 65432}), 200),
          );

          expect(response.statusCode, HttpStatus.ok);
          expect(
            (await db.buildJobDao.getBuildJob(job.id))!.installationId,
            '65432',
          );
          expect(githubRequests, hasLength(1));
        },
      );

      test('requires a team before contacting GitHub', () async {
        final response = await post(
          payload: job.copyWith(teamId: null).toJson(),
        );

        expect(response.statusCode, HttpStatus.badRequest);
        expect(await response.json(), {
          'success': false,
          'error': 'teamId is required',
        });
        expect(await db.select(db.buildJobs).get(), isEmpty);
        expect(githubRequests, isEmpty);
      });

      test('rejects an empty team before contacting GitHub', () async {
        final response = await post(payload: job.copyWith(teamId: '').toJson());

        expect(response.statusCode, HttpStatus.badRequest);
        expect(await db.select(db.buildJobs).get(), isEmpty);
        expect(githubRequests, isEmpty);
      });

      test('rejects a nonexistent team before contacting GitHub', () async {
        final response = await post(
          payload: job.copyWith(teamId: 'missing-team').toJson(),
        );

        expect(response.statusCode, HttpStatus.forbidden);
        expect(await db.select(db.buildJobs).get(), isEmpty);
        expect(githubRequests, isEmpty);
      });

      test('legacy team IDs cannot authorize registration', () async {
        await db.delete(db.gitHubConnections).go();
        final team = (await db.teamDao.getTeam('team-xyz'))!;
        await db.teamDao.updateTeam(team.copyWith(installationIds: [54321]));

        final response = await post();

        expect(response.statusCode, HttpStatus.forbidden);
        expect(await response.json(), {'success': false, 'error': 'Forbidden'});
        expect(await db.select(db.buildJobs).get(), isEmpty);
        expect(githubRequests, isEmpty);
      });

      test('rejects a connection owned by another team', () async {
        final team = (await db.teamDao.getTeam('team-xyz'))!;
        await db.into(db.teams).insert(team.copyWith(id: 'other-team'));

        await expectConnectionRejected(
          connection.copyWith(teamId: 'other-team'),
        );
      });

      test('rejects suspended connections', () async {
        await expectConnectionRejected(
          connection.copyWith(status: GitHubConnectionStatus.suspended),
        );
      });

      test('rejects removed connections', () async {
        await expectConnectionRejected(
          connection.copyWith(status: GitHubConnectionStatus.removed),
        );
      });

      test('rejects a connection for another GitHub API host', () async {
        await expectConnectionRejected(
          connection.copyWith(
            githubApiBaseUrl: 'https://github.example/api/v3',
          ),
        );
      });

      test('rejects a connection for another GitHub App', () async {
        await expectConnectionRejected(connection.copyWith(githubAppId: 42));
      });

      test(
        'rejects an installation mismatch without falling back to supplied IDs',
        () async {
          final response = await post(
            payload: {...job.toJson(), 'installationId': '54321'},
            respond: (_) => http.Response(jsonEncode({'id': 65432}), 200),
          );

          expect(response.statusCode, HttpStatus.forbidden);
          expect(await response.json(), {
            'success': false,
            'error': 'Forbidden',
          });
          expect(await db.select(db.buildJobs).get(), isEmpty);
          expect(githubRequests, hasLength(1));
          expect(githubRequests.single.method, 'GET');
        },
      );

      test('does not insert when GitHub refuses repository access', () async {
        final response = await post(
          respond: (_) => http.Response('private permission detail', 403),
        );

        await expectFailure(response);
        expect(githubRequests, hasLength(1));
      });

      test(
        'does not insert when GitHub returns an invalid installation ID',
        () async {
          final response = await post(
            respond: (_) => http.Response(jsonEncode({'id': 0}), 200),
          );

          await expectFailure(response);
          expect(githubRequests, hasLength(1));
        },
      );

      test('does not insert when GitHub transport fails', () async {
        final response = await post(
          respond: (_) =>
              throw const SocketException('private transport detail'),
        );

        await expectFailure(response);
        expect(githubRequests, hasLength(1));
      });

      test(
        'does not insert or contact GitHub when connection lookup fails',
        () async {
          await db.customStatement('DROP TABLE github_connections');

          await expectFailure(await post());
          expect(githubRequests, isEmpty);
        },
      );

      test('reports an insert failure after repository verification', () async {
        await db.customStatement('''CREATE TRIGGER reject_build_job
          BEFORE INSERT ON build_jobs
          BEGIN
            SELECT RAISE(FAIL, 'private database insert detail');
          END''');

        await expectFailure(await post());
        expect(githubRequests, hasLength(1));
      });

      test('does not insert when the App ID is missing', () async {
        environment.remove('GITHUB_APP_ID');

        await expectFailure(await post());
        expect(githubRequests, isEmpty);
      });

      test('does not insert when the API URL is missing', () async {
        environment.remove('GITHUB_API_BASE_URL');

        await expectFailure(await post());
        expect(githubRequests, isEmpty);
      });

      test(
        'normalizes the operator URL for verification and repository cloning',
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

          final response = await post();

          expect(response.statusCode, HttpStatus.ok);
          final inserted = (await db.buildJobDao.getBuildJob(job.id))!;
          expect(inserted.installationId, '54321');
          expect(inserted.githubBaseUrl, 'https://github.example:8443');
          expect(githubRequests, hasLength(1));
          expect(
            githubRequests.single.url.toString(),
            'https://github.example:8443/api/v3/repos/owner/repo/installation',
          );
        },
      );
    });
  });

  group('GET /builds', () {
    test('requires a Firebase UID even with a valid internal key', () async {
      final context = TestRequestContext(
        path: '/builds?teamId=team-xyz',
        method: HttpMethod.get,
        headers: {'Authorization': 'Bearer test-internal-key'},
      );
      context.provide<AppDatabase>(db);
      context.provide<String?>(null);
      context.provide<InternalApiKeyValidator>(
        const InternalApiKeyValidator(
          environment: {'INTERNAL_API_KEY': 'test-internal-key'},
        ),
      );

      final response = await route.onRequest(context.context);

      expect(response.statusCode, HttpStatus.unauthorized);
    });

    test('responds with 401 Unauthorized when uid is null', () async {
      final context = TestRequestContext(
        path: '/builds?teamId=team-xyz',
        method: HttpMethod.get,
      );

      context.provide<AppDatabase>(db);
      context.provide<String?>(null);

      final response = await route.onRequest(context.context);

      expect(response.statusCode, equals(HttpStatus.unauthorized));
    });

    test(
      'responds with 400 Bad Request when teamId parameter is missing',
      () async {
        final context = TestRequestContext(
          path: '/builds',
          method: HttpMethod.get,
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.badRequest));
        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], contains('Missing teamId parameter'));
      },
    );

    test(
      'responds with 403 Forbidden when user is not a member of the team',
      () async {
        final team = DriftTeam(
          id: 'team-xyz',
          name: 'Team XYZ',
          installationIds: const [],
          runNumber: 1,
          aiEnabled: true,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );

        await db.teamDao.createTeamAndMember(team, 'user-abc');

        final context = TestRequestContext(
          path: '/builds?teamId=team-xyz',
          method: HttpMethod.get,
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.forbidden));
      },
    );

    test('responds with 200 OK and returns build jobs for the team', () async {
      final team = DriftTeam(
        id: 'team-xyz',
        name: 'Team XYZ',
        installationIds: const [],
        runNumber: 1,
        aiEnabled: true,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );

      await db.teamDao.createTeamAndMember(team, 'user-123');

      final now = DateTime.now().toUtc();
      final job1 = DriftBuildJob(
        id: 'job-1',
        status: BuildJobStatus.QUEUED,
        owner: 'owner',
        repo: 'repo',
        workflowName: 'workflow',
        workflowFileName: 'ci.yml',
        teamId: 'team-xyz',
        hasIpa: false,
        createdAt: now,
        updatedAt: now,
      );
      final job2 = DriftBuildJob(
        id: 'job-2',
        status: BuildJobStatus.SUCCESS,
        owner: 'owner',
        repo: 'repo',
        workflowName: 'workflow',
        workflowFileName: 'ci.yml',
        teamId: 'team-xyz',
        hasIpa: true,
        createdAt: now.add(const Duration(seconds: 1)),
        updatedAt: now.add(const Duration(seconds: 1)),
      );
      final jobOther = DriftBuildJob(
        id: 'job-other',
        status: BuildJobStatus.QUEUED,
        owner: 'owner',
        repo: 'repo',
        workflowName: 'workflow',
        workflowFileName: 'ci.yml',
        teamId: 'team-other',
        hasIpa: false,
        createdAt: now,
        updatedAt: now,
      );

      await db.buildJobDao.insertBuildJob(job1);
      await db.buildJobDao.insertBuildJob(job2);
      await db.buildJobDao.insertBuildJob(jobOther);

      // Query all jobs for team-xyz
      final contextAll = TestRequestContext(
        path: '/builds?teamId=team-xyz',
        method: HttpMethod.get,
      );
      contextAll.provide<AppDatabase>(db);
      contextAll.provide<String?>('user-123');

      final responseAll = await route.onRequest(contextAll.context);
      expect(responseAll.statusCode, equals(HttpStatus.ok));
      final bodyAll = await responseAll.json() as Map<String, dynamic>;
      expect(bodyAll['success'], isTrue);
      final listAll = bodyAll['buildJobs'] as List<dynamic>;
      expect(listAll, hasLength(2));
      expect(
        listAll[0]['id'],
        equals('job-2'),
      ); // ordered descending by createdAt
      expect(listAll[1]['id'], equals('job-1'));

      // Query jobs with hasIpa=true
      final contextIpa = TestRequestContext(
        path: '/builds?teamId=team-xyz&hasIpa=true',
        method: HttpMethod.get,
      );
      contextIpa.provide<AppDatabase>(db);
      contextIpa.provide<String?>('user-123');

      final responseIpa = await route.onRequest(contextIpa.context);
      expect(responseIpa.statusCode, equals(HttpStatus.ok));
      final bodyIpa = await responseIpa.json() as Map<String, dynamic>;
      final listIpa = bodyIpa['buildJobs'] as List<dynamic>;
      expect(listIpa, hasLength(1));
      expect(listIpa[0]['id'], equals('job-2'));
    });

    test(
      'responds with 400 Bad Request when hasIpa parameter is invalid',
      () async {
        final team = DriftTeam(
          id: 'team-xyz',
          name: 'Team XYZ',
          installationIds: const [],
          runNumber: 1,
          aiEnabled: true,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );

        await db.teamDao.createTeamAndMember(team, 'user-123');

        final context = TestRequestContext(
          path: '/builds?teamId=team-xyz&hasIpa=invalid',
          method: HttpMethod.get,
        );
        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');

        final response = await route.onRequest(context.context);
        expect(response.statusCode, equals(HttpStatus.badRequest));
        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], contains('Invalid hasIpa parameter'));
      },
    );

    test(
      'responds with 400 Bad Request when limit parameter is invalid',
      () async {
        final team = DriftTeam(
          id: 'team-xyz',
          name: 'Team XYZ',
          installationIds: const [],
          runNumber: 1,
          aiEnabled: true,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );

        await db.teamDao.createTeamAndMember(team, 'user-123');

        // Test with non-integer limit
        final contextInvalidString = TestRequestContext(
          path: '/builds?teamId=team-xyz&limit=abc',
          method: HttpMethod.get,
        );
        contextInvalidString.provide<AppDatabase>(db);
        contextInvalidString.provide<String?>('user-123');

        final responseInvalidString = await route.onRequest(
          contextInvalidString.context,
        );
        expect(responseInvalidString.statusCode, equals(HttpStatus.badRequest));
        final bodyInvalidString =
            await responseInvalidString.json() as Map<String, dynamic>;
        expect(bodyInvalidString['error'], contains('Invalid limit parameter'));

        // Test with limit < 1
        final contextZero = TestRequestContext(
          path: '/builds?teamId=team-xyz&limit=0',
          method: HttpMethod.get,
        );
        contextZero.provide<AppDatabase>(db);
        contextZero.provide<String?>('user-123');

        final responseZero = await route.onRequest(contextZero.context);
        expect(responseZero.statusCode, equals(HttpStatus.badRequest));

        // Test with limit > 200
        final contextTooLarge = TestRequestContext(
          path: '/builds?teamId=team-xyz&limit=201',
          method: HttpMethod.get,
        );
        contextTooLarge.provide<AppDatabase>(db);
        contextTooLarge.provide<String?>('user-123');

        final responseTooLarge = await route.onRequest(contextTooLarge.context);
        expect(responseTooLarge.statusCode, equals(HttpStatus.badRequest));
      },
    );
  });

  testDatabaseFailures([
    DatabaseFailureEndpoint(
      '/builds?teamId=team-1',
      HttpMethod.get,
      route.onRequest,
    ),
    DatabaseFailureEndpoint(
      '/builds',
      HttpMethod.post,
      route.onRequest,
      body: jsonEncode(databaseFailureJob.toShared().toJson()),
      headers: {'Authorization': 'Bearer test-internal-key'},
      configure: (context) {
        context.provide<Map<String, String>>({
          'GITHUB_API_BASE_URL': 'https://api.github.com',
          'GITHUB_APP_ID': '123456',
        });
        context.provide<InternalApiKeyValidator>(
          const InternalApiKeyValidator(
            environment: {'INTERNAL_API_KEY': 'test-internal-key'},
          ),
        );
      },
    ),
  ]);
}
