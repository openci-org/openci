import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_server/asc/asc_service.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/secret/secret_crypter.dart';
import 'package:test/test.dart';

import '../../../routes/teams/[id]/asc/builds/[buildId]/submit-testflight.dart'
    as submit_testflight_route;

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

  group('POST /teams/[id]/asc/builds/[buildId]/submit-testflight', () {
    test('responds with 401 Unauthorized when uid is null', () async {
      final context = TestRequestContext(
        path: '/teams/team-123/asc/builds/build-abc/submit-testflight',
        method: HttpMethod.post,
      );
      context.provide<AppDatabase>(db);
      context.provide<String?>(null);

      final response = await submit_testflight_route.onRequest(
        context.context,
        'team-123',
        'build-abc',
      );
      expect(response.statusCode, equals(HttpStatus.unauthorized));
    });

    test('responds with 403 Forbidden when user is not team member', () async {
      final context = TestRequestContext(
        path: '/teams/team-123/asc/builds/build-abc/submit-testflight',
        method: HttpMethod.post,
      );
      context.provide<AppDatabase>(db);
      context.provide<String?>('stranger');

      final response = await submit_testflight_route.onRequest(
        context.context,
        'team-123',
        'build-abc',
      );
      expect(response.statusCode, equals(HttpStatus.forbidden));
    });

    test(
      'responds with 200 OK and returns betaGroupName on successful submission',
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
          () => mockAscService.submitToTestFlight(any(), any(), any(), any()),
        ).thenAnswer((_) async => 'External Testers');

        final context = TestRequestContext(
          path: '/teams/team-123/asc/builds/build-abc/submit-testflight',
          method: HttpMethod.post,
        );
        context.provide<AppDatabase>(db);
        context.provide<String?>('user-1');
        context.provide<Map<String, String>>(testEnv);
        context.provide<AscService>(mockAscService);

        final response = await submit_testflight_route.onRequest(
          context.context,
          'team-123',
          'build-abc',
        );
        expect(response.statusCode, equals(HttpStatus.ok));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isTrue);
        expect(body['betaGroupName'], equals('External Testers'));
      },
    );
  });
}
