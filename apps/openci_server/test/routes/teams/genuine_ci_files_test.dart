import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/team/team_dao.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../helpers/github_app_test_key.dart';
import '../../../routes/teams/[id]/repositories/[repo]/genuine-ci-files.dart'
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
      when(() => context.read<AppDatabase>()).thenReturn(db);
      when(() => db.teamDao).thenReturn(teamDao);
      when(() => request.uri).thenReturn(
        Uri.parse(
          'http://localhost/teams/team123/repositories/my-repo/genuine-ci-files?ref=main',
        ),
      );
    });

    test('returns 401 Unauthorized when user is not authenticated', () async {
      when(() => context.read<String?>()).thenReturn(null);

      final response = await route.onRequest(context, 'team123', 'my-repo');

      expect(response.statusCode, equals(HttpStatus.unauthorized));
    });

    test('returns 403 Forbidden when user is not a team member', () async {
      when(() => context.read<String?>()).thenReturn('user-1');
      when(
        () => teamDao.isTeamMember('user-1', 'team123'),
      ).thenAnswer((_) async => false);

      final response = await route.onRequest(context, 'team123', 'my-repo');

      expect(response.statusCode, equals(HttpStatus.forbidden));
    });
  });

  group('GenuineCI file request parameters', () {
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

    test('uses the requested owner and installation ID', () async {
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
          '/repos/openci-org/openci/contents/genuine_ci',
        );
        expect(request.url.queryParameters['ref'], 'commit-sha-123');
        return http.Response('[]', HttpStatus.ok);
      });
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
}

TestRequestContext _requestContext({
  required AppDatabase db,
  required String path,
  required Map<String, String> environment,
  http.Client? client,
}) {
  final context = TestRequestContext(path: path, method: HttpMethod.get)
    ..provide<AppDatabase>(db)
    ..provide<String?>('system-job-processor')
    ..provide<Map<String, String>>(environment);
  if (client != null) {
    context.provide<http.Client>(client);
  }
  return context;
}
