import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:genuineci_server/auth/internal_api_key_validator.dart';
import 'package:genuineci_server/database.dart';
import 'package:genuineci_server/team/team_dao.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../../../helpers/database_failure_checks.dart';
import '../../../../../helpers/github_app_test_key.dart';
import '../../../../../../routes/teams/[id]/repositories/[repo]/genuine-ci-files.dart'
    as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

class _MockAppDatabase extends Mock implements AppDatabase {}

class _MockTeamDao extends Mock implements TeamDao {}

void main() {
  group('GET /teams/[id]/repositories/[repo]/genuine-ci-files', () {
    late RequestContext context;
    late Request request;
    late AppDatabase db;
    late TeamDao teamDao;

    setUp(() {
      context = _MockRequestContext();
      request = _MockRequest();
      db = _MockAppDatabase();
      teamDao = _MockTeamDao();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.get);
      when(() => request.headers).thenReturn({});
      when(() => context.read<InternalApiKeyValidator>()).thenReturn(
        const InternalApiKeyValidator.forTesting(
          environment: {'INTERNAL_API_KEY': 'test-internal-key'},
        ),
      );
      when(() => context.read<AppDatabase>()).thenReturn(db);
      when(() => db.teamDao).thenReturn(teamDao);
      final client = MockClient(
        (_) async => fail('GitHub must not be contacted'),
      );
      addTearDown(client.close);
      when(() => context.read<http.Client>()).thenReturn(client);
      when(() => request.uri).thenReturn(
        Uri.parse(
          'http://localhost/teams/team123/repositories/my-repo/genuine-ci-files?ref=main',
        ),
      );
    });

    for (final (description, token) in [
      ('missing key', null),
      ('empty key', ''),
      ('incorrect key', 'incorrect-key'),
    ]) {
      test(
        'rejects a $description without a UID before database access',
        () async {
          when(() => context.read<String?>()).thenReturn(null);
          when(() => request.headers).thenReturn({
            if (token != null) 'authorization': 'Bearer $token',
          });

          final response = await route.onRequest(context, 'team123', 'my-repo');

          expect(response.statusCode, HttpStatus.unauthorized);
          verifyNever(() => context.read<AppDatabase>());
          verifyNever(() => context.read<http.Client>());
        },
      );
    }

    for (final uid in ['user-1', 'system-job-processor']) {
      test('rejects non-member $uid before contacting GitHub', () async {
        when(() => context.read<String?>()).thenReturn(uid);
        when(() => request.headers).thenReturn({
          'authorization': 'Bearer firebase-id-token',
        });
        when(
          () => teamDao.isTeamMember(uid, 'team123'),
        ).thenAnswer((_) async => false);

        final response = await route.onRequest(context, 'team123', 'my-repo');

        expect(response.statusCode, HttpStatus.forbidden);
        verifyNever(() => context.read<http.Client>());
      });
    }
  });

  group('GenuineCI file retrieval', () {
    late AppDatabase db;
    late Directory tempDirectory;
    late Map<String, String> environment;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      final now = DateTime.now().toUtc();
      await db
          .into(db.teams)
          .insert(
            DriftTeam(
              id: 'team-123',
              name: 'A display name that is not the GitHub owner',
              installationIds: const [111111, 998877],
              aiEnabled: false,
              runNumber: 1,
              createdAt: now,
              updatedAt: now,
            ),
          );

      tempDirectory = Directory.systemTemp.createTempSync(
        'genuine-ci-files-test-',
      );
      final privateKeyFile = File(
        p.join(tempDirectory.path, 'private-key.pem'),
      )..writeAsStringSync(testRsaPrivateKey);
      environment = {
        'GITHUB_APP_ID': '12345',
        'GITHUB_PRIVATE_KEY_PATH': privateKeyFile.path,
        'GITHUB_API_BASE_URL': 'https://api.github.test',
      };
    });

    tearDown(() async {
      await db.close();
      tempDirectory.deleteSync(recursive: true);
    });

    test('uses owner and installation with a key and no UID', () async {
      final client = MockClient((request) async {
        if (request.method == 'POST') {
          expect(
            request.url.path,
            '/app/installations/998877/access_tokens',
          );
          return http.Response(
            jsonEncode({'token': 'installation-token'}),
            HttpStatus.created,
          );
        }

        expect(request.method, 'GET');
        expect(
          request.url.path,
          '/repos/openci-org/openci/contents/openci',
        );
        expect(request.url.queryParameters['ref'], 'commit-sha-123');
        return http.Response('[]', HttpStatus.ok);
      });
      addTearDown(client.close);
      final context = _requestContext(
        db: db,
        path:
            '/teams/team-123/repositories/openci/genuine-ci-files'
            '?ref=commit-sha-123&owner=openci-org&installationId=998877',
        environment: environment,
        client: client,
      );

      final response = await route.onRequest(
        context.context,
        'team-123',
        'openci',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(await response.json(), isEmpty);
    });

    for (final uid in ['user-1', 'system-job-processor']) {
      test('allows team member $uid without an internal key', () async {
        await db.teamDao.addTeamMember('team-123', uid);
        final client = MockClient((request) async {
          if (request.method == 'POST') {
            return http.Response(
              jsonEncode({'token': 'installation-token'}),
              HttpStatus.created,
            );
          }
          return http.Response('[]', HttpStatus.ok);
        });
        addTearDown(client.close);
        final context = _requestContext(
          db: db,
          path:
              '/teams/team-123/repositories/openci/genuine-ci-files'
              '?ref=commit-sha-123&owner=openci-org&installationId=998877',
          environment: environment,
          client: client,
          uid: uid,
          headers: {'Authorization': 'Bearer firebase-id-token'},
        );

        final response = await route.onRequest(
          context.context,
          'team-123',
          'openci',
        );

        expect(response.statusCode, HttpStatus.ok);
        expect(await response.json(), isEmpty);
      });
    }

    for (final (scenario, status, message) in [
      ('missing team', HttpStatus.notFound, 'Team not found'),
      (
        'no installation',
        HttpStatus.badRequest,
        'GitHub App is not installed for this team',
      ),
      ('invalid installation', HttpStatus.badRequest, 'Invalid installationId'),
    ]) {
      test('rejects $scenario before contacting GitHub', () async {
        if (scenario == 'missing team') {
          await db.delete(db.teams).go();
        } else if (scenario == 'no installation') {
          await db
              .update(db.teams)
              .write(const TeamsCompanion(installationIds: Value([])));
        }
        final client = MockClient(
          (_) async => fail('GitHub must not be contacted'),
        );
        addTearDown(client.close);
        final context = _requestContext(
          db: db,
          path:
              '/teams/team-123/repositories/openci/genuine-ci-files?owner=openci-org&installationId=not-a-number',
          environment: environment,
          client: client,
        );
        final response = await route.onRequest(
          context.context,
          'team-123',
          'openci',
        );
        expect(response.statusCode, status);
        expect(await response.json(), {'success': false, 'error': message});
      });
    }

    test('requires owner', () async {
      final context = _requestContext(
        db: db,
        path:
            '/teams/team-123/repositories/openci/genuine-ci-files'
            '?ref=commit-sha-123&installationId=998877',
        environment: environment,
      );

      final response = await route.onRequest(
        context.context,
        'team-123',
        'openci',
      );

      expect(response.statusCode, HttpStatus.badRequest);
      expect(await response.json(), {
        'success': false,
        'error': 'owner is required',
      });
    });

    test('requires installation ID', () async {
      final context = _requestContext(
        db: db,
        path:
            '/teams/team-123/repositories/openci/genuine-ci-files'
            '?ref=commit-sha-123&owner=openci-org',
        environment: environment,
      );

      final response = await route.onRequest(
        context.context,
        'team-123',
        'openci',
      );

      expect(response.statusCode, HttpStatus.badRequest);
      expect(await response.json(), {
        'success': false,
        'error': 'installationId is required',
      });
    });

    test('rejects an installation ID that is not linked to the team', () async {
      final context = _requestContext(
        db: db,
        path:
            '/teams/team-123/repositories/openci/genuine-ci-files'
            '?ref=commit-sha-123&owner=openci-org&installationId=123456',
        environment: environment,
      );

      final response = await route.onRequest(
        context.context,
        'team-123',
        'openci',
      );

      expect(response.statusCode, HttpStatus.badRequest);
      expect(await response.json(), {
        'success': false,
        'error': 'Installation is not associated with this team',
      });
    });
  });

  testDatabaseFailures([
    DatabaseFailureEndpoint(
      '/teams/team-1/repositories/repo/genuine-ci-files',
      HttpMethod.get,
      (c) => route.onRequest(c, 'team-1', 'repo'),
      configure: (context) {
        context.provide<InternalApiKeyValidator>(
          const InternalApiKeyValidator.forTesting(
            environment: {'INTERNAL_API_KEY': 'test-internal-key'},
          ),
        );
      },
    ),
  ]);
}

TestRequestContext _requestContext({
  required AppDatabase db,
  required String path,
  required Map<String, String> environment,
  http.Client? client,
  String? uid,
  Map<String, String> headers = const {
    'Authorization': 'Bearer test-internal-key',
  },
}) {
  final context =
      TestRequestContext(
          path: path,
          method: HttpMethod.get,
          headers: headers,
        )
        ..provide<AppDatabase>(db)
        ..provide<String?>(uid)
        ..provide<InternalApiKeyValidator>(
          const InternalApiKeyValidator.forTesting(
            environment: {'INTERNAL_API_KEY': 'test-internal-key'},
          ),
        )
        ..provide<Map<String, String>>(environment);
  final githubClient =
      client ??
      MockClient(
        (_) async => fail('GitHub must not be contacted'),
      );
  if (client == null) addTearDown(githubClient.close);
  context.provide<http.Client>(githubClient);
  return context;
}
