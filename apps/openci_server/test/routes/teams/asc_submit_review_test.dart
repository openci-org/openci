import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_server/asc/asc_service.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/secret/secret_crypter.dart';
import 'package:test/test.dart';

import '../../../routes/teams/[id]/asc/builds/submit-review.dart'
    as submit_review_route;

class MockAscService extends Mock implements AscService {}

class FakeAppDatabase extends Fake implements AppDatabase {}

class FakeSecretCrypter extends Fake implements SecretCrypter {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAppDatabase());
    registerFallbackValue(FakeSecretCrypter());
  });

  late AppDatabase db;
  late MockAscService mockAscService;
  late Map<String, String> testEnv;
  const encryptionKey = 'cTN0Nnc5eiRDJkYpSkBOY1FmVGZXblpyNHU3eCFBJUQ=';

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    mockAscService = MockAscService();
    await db
        .into(db.teams)
        .insert(
          DriftTeam(
            id: 'team-123',
            name: 'Test Team',
            installationIds: const [98765],
            aiEnabled: false,
            runNumber: 1,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          ),
        );

    testEnv = {
      'SECRET_ENCRYPTION_KEY': encryptionKey,
    };
  });

  tearDown(() async {
    await db.close();
  });

  group('POST /teams/[id]/asc/builds/submit-review', () {
    test('responds with 401 Unauthorized when uid is null', () async {
      final context = TestRequestContext(
        path: '/teams/team-123/asc/builds/submit-review',
        method: HttpMethod.post,
      );
      context.provide<AppDatabase>(db);
      context.provide<String?>(null);

      final response = await submit_review_route.onRequest(
        context.context,
        'team-123',
      );
      expect(response.statusCode, equals(HttpStatus.unauthorized));
    });

    test('responds with 403 Forbidden when user is not team member', () async {
      final context = TestRequestContext(
        path: '/teams/team-123/asc/builds/submit-review',
        method: HttpMethod.post,
      );
      context.provide<AppDatabase>(db);
      context.provide<String?>('stranger');

      final response = await submit_review_route.onRequest(
        context.context,
        'team-123',
      );
      expect(response.statusCode, equals(HttpStatus.forbidden));
    });

    test(
      'responds with 400 Bad Request when request body is missing parameters',
      () async {
        await db
            .into(db.teamMembers)
            .insert(
              TeamMembersCompanion.insert(
                teamId: 'team-123',
                userId: 'user-1',
              ),
            );

        final context = TestRequestContext(
          path: '/teams/team-123/asc/builds/submit-review',
          method: HttpMethod.post,
          body: '{"appId": "app-123"}',
        );
        context.provide<AppDatabase>(db);
        context.provide<String?>('user-1');
        context.provide<Map<String, String>>(testEnv);

        final response = await submit_review_route.onRequest(
          context.context,
          'team-123',
        );
        expect(response.statusCode, equals(HttpStatus.badRequest));
      },
    );

    test(
      'responds with 200 OK and returns appStoreVersionId on successful submission',
      () async {
        await db
            .into(db.teamMembers)
            .insert(
              TeamMembersCompanion.insert(
                teamId: 'team-123',
                userId: 'user-1',
              ),
            );

        when(
          () => mockAscService.submitForReview(
            any(),
            any(),
            appId: any(named: 'appId'),
            buildId: any(named: 'buildId'),
            versionString: any(named: 'versionString'),
            whatsNew: any(named: 'whatsNew'),
            platform: any(named: 'platform'),
            crypter: any(named: 'crypter'),
          ),
        ).thenAnswer((_) async => 'version-xyz-123');

        final context = TestRequestContext(
          path: '/teams/team-123/asc/builds/submit-review',
          method: HttpMethod.post,
          body:
              '{"appId": "app-123", "buildId": "build-456", "versionString": "1.0.0", "whatsNew": "bug fixes"}',
        );
        context.provide<AppDatabase>(db);
        context.provide<String?>('user-1');
        context.provide<Map<String, String>>(testEnv);
        context.provide<AscService>(mockAscService);

        final response = await submit_review_route.onRequest(
          context.context,
          'team-123',
        );
        expect(response.statusCode, equals(HttpStatus.ok));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isTrue);
        expect(body['appStoreVersionId'], equals('version-xyz-123'));
      },
    );
  });
}
