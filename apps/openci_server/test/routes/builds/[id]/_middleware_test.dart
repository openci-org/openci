import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:drift/native.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_server/auth/internal_api_key_validator.dart';
import 'package:openci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

import '../../../../routes/builds/[id]/_middleware.dart';

class MockRequestContext extends Mock implements RequestContext {}

class MockRequest extends Mock implements Request {}

void main() {
  late AppDatabase db;
  late MockRequestContext context;
  late MockRequest request;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    context = MockRequestContext();
    request = MockRequest();

    when(() => context.request).thenReturn(request);
    when(() => request.headers).thenReturn({});
    when(
      () => request.uri,
    ).thenReturn(Uri.parse('http://localhost/builds/job-123'));
    when(() => context.read<AppDatabase>()).thenReturn(db);
    when(() => context.read<InternalApiKeyValidator>()).thenReturn(
      const InternalApiKeyValidator.forTesting(
        environment: {'INTERNAL_API_KEY': 'test-internal-key'},
      ),
    );
    registerFallbackValue(
      () => DriftBuildJob(
        id: '',
        status: BuildJobStatus.QUEUED,
        owner: '',
        repo: '',
        workflowName: '',
        workflowFileName: 'ci.yml',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('provides the build job for an internal key without a UID', () async {
    final now = DateTime.now().toUtc();
    final job = DriftBuildJob(
      id: 'job-123',
      status: BuildJobStatus.QUEUED,
      owner: 'owner',
      repo: 'repo',
      workflowName: 'workflow',
      workflowFileName: 'ci.yml',
      teamId: 'team-xyz',
      createdAt: now,
      updatedAt: now,
    );
    await db.buildJobDao.insertBuildJob(job);

    when(() => context.read<String?>()).thenReturn(null);
    when(() => request.headers).thenReturn({
      'authorization': 'Bearer test-internal-key',
    });
    when(() => context.provide<DriftBuildJob>(any())).thenReturn(context);

    final handler = middleware((_) => Response());
    final response = await handler(context);
    expect(response.statusCode, equals(HttpStatus.ok));
    final providedJobs = verify(
      () => context.provide<DriftBuildJob>(captureAny()),
    ).captured;
    final provideJob = providedJobs.single as DriftBuildJob Function();
    expect(provideJob(), await db.buildJobDao.getBuildJob(job.id));
  });

  test(
    'rejects a request without a UID or internal key before database access',
    () async {
      when(() => context.read<String?>()).thenReturn(null);

      final handler = middleware((_) => fail('Handler must not run'));
      final response = await handler(context);

      expect(response.statusCode, equals(HttpStatus.unauthorized));
      verifyNever(() => context.read<AppDatabase>());
    },
  );

  test(
    'rejects an incorrect internal key without a UID before database access',
    () async {
      when(() => context.read<String?>()).thenReturn(null);
      when(() => request.headers).thenReturn({
        'authorization': 'Bearer incorrect-key',
      });

      final handler = middleware((_) => fail('Handler must not run'));
      final response = await handler(context);

      expect(response.statusCode, HttpStatus.unauthorized);
      verifyNever(() => context.read<AppDatabase>());
    },
  );

  test(
    'rejects an empty internal key without a UID before database access',
    () async {
      when(() => context.read<String?>()).thenReturn(null);
      when(() => request.headers).thenReturn({'authorization': 'Bearer '});

      final handler = middleware((_) => fail('Handler must not run'));
      final response = await handler(context);

      expect(response.statusCode, HttpStatus.unauthorized);
      verifyNever(() => context.read<AppDatabase>());
    },
  );

  test('returns 400 Bad Request when path segments are invalid', () async {
    when(() => context.read<String?>()).thenReturn('user-123');
    when(
      () => request.uri,
    ).thenReturn(Uri.parse('http://localhost/not-builds/123'));

    final handler = middleware((_) => Response());
    final response = await handler(context);

    expect(response.statusCode, equals(HttpStatus.badRequest));
  });

  test('returns 404 for a missing job with an internal key', () async {
    when(() => context.read<String?>()).thenReturn(null);
    when(() => request.headers).thenReturn({
      'authorization': 'Bearer test-internal-key',
    });
    when(
      () => request.uri,
    ).thenReturn(Uri.parse('http://localhost/builds/non-existent'));

    final handler = middleware((_) => Response());
    final response = await handler(context);

    expect(response.statusCode, equals(HttpStatus.notFound));
  });

  test('returns 403 for a job without a team with an internal key', () async {
    final now = DateTime.now().toUtc();
    final job = DriftBuildJob(
      id: 'job-no-team',
      status: BuildJobStatus.QUEUED,
      owner: 'owner',
      repo: 'repo',
      workflowName: 'workflow',
      workflowFileName: 'ci.yml',
      teamId: null,
      createdAt: now,
      updatedAt: now,
    );
    await db.buildJobDao.insertBuildJob(job);

    when(() => context.read<String?>()).thenReturn(null);
    when(() => request.headers).thenReturn({
      'authorization': 'Bearer test-internal-key',
    });
    when(
      () => request.uri,
    ).thenReturn(Uri.parse('http://localhost/builds/job-no-team'));

    final handler = middleware((_) => Response());
    final response = await handler(context);

    expect(response.statusCode, equals(HttpStatus.forbidden));
  });

  for (final uid in ['user-123', 'system-job-processor']) {
    test(
      'rejects non-member $uid without a valid internal key',
      () async {
        final now = DateTime.now().toUtc();
        final team = DriftTeam(
          id: 'team-xyz',
          name: 'Team XYZ',
          githubBaseUrl: null,
          installationIds: const [],
          runNumber: 1,
          aiEnabled: true,
          createdAt: now,
          updatedAt: now,
        );
        await db.teamDao.createTeamAndMember(team, 'some-other-user');

        final job = DriftBuildJob(
          id: 'job-xyz',
          status: BuildJobStatus.QUEUED,
          owner: 'owner',
          repo: 'repo',
          workflowName: 'workflow',
          workflowFileName: 'ci.yml',
          teamId: 'team-xyz',
          createdAt: now,
          updatedAt: now,
        );
        await db.buildJobDao.insertBuildJob(job);

        when(() => context.read<String?>()).thenReturn(uid);
        when(() => request.headers).thenReturn({
          'authorization': 'Bearer firebase-id-token',
        });
        when(
          () => request.uri,
        ).thenReturn(Uri.parse('http://localhost/builds/job-xyz'));

        final handler = middleware((_) => fail('Handler must not run'));
        final response = await handler(context);

        expect(response.statusCode, equals(HttpStatus.forbidden));
      },
    );

    test(
      'provides the build job for team member $uid without an internal key',
      () async {
        final now = DateTime.now().toUtc();
        final team = DriftTeam(
          id: 'team-xyz',
          name: 'Team XYZ',
          githubBaseUrl: null,
          installationIds: const [],
          runNumber: 1,
          aiEnabled: true,
          createdAt: now,
          updatedAt: now,
        );
        await db.teamDao.createTeamAndMember(team, uid);

        final job = DriftBuildJob(
          id: 'job-xyz',
          status: BuildJobStatus.QUEUED,
          owner: 'owner',
          repo: 'repo',
          workflowName: 'workflow',
          workflowFileName: 'ci.yml',
          teamId: 'team-xyz',
          createdAt: now,
          updatedAt: now,
        );
        await db.buildJobDao.insertBuildJob(job);

        when(() => context.read<String?>()).thenReturn(uid);
        when(() => request.headers).thenReturn({
          'authorization': 'Bearer firebase-id-token',
        });
        when(
          () => request.uri,
        ).thenReturn(Uri.parse('http://localhost/builds/job-xyz'));
        when(() => context.provide<DriftBuildJob>(any())).thenReturn(context);

        var nextCalled = false;
        final handler = middleware((ctx) {
          nextCalled = true;
          return Response();
        });

        final response = await handler(context);
        expect(response.statusCode, equals(HttpStatus.ok));
        expect(nextCalled, isTrue);
        verify(() => context.provide<DriftBuildJob>(any())).called(1);
      },
    );
  }

  for (final path in ['/builds/commits', '/builds/commits/stream']) {
    test(
      'requires a Firebase UID for $path even with a valid internal key',
      () async {
        when(() => context.read<String?>()).thenReturn(null);
        when(() => request.uri).thenReturn(Uri.parse('http://localhost$path'));
        when(() => request.headers).thenReturn({
          'authorization': 'Bearer test-internal-key',
        });

        final handler = middleware((_) => fail('Handler must not run'));
        final response = await handler(context);

        expect(response.statusCode, HttpStatus.unauthorized);
        verifyNever(() => context.read<AppDatabase>());
      },
    );

    test('delegates $path to its own handler for a Firebase user', () async {
      when(() => context.read<String?>()).thenReturn('user-123');
      when(() => request.uri).thenReturn(Uri.parse('http://localhost$path'));

      var nextCalled = false;
      final handler = middleware((_) {
        nextCalled = true;
        return Response();
      });
      final response = await handler(context);

      expect(response.statusCode, HttpStatus.ok);
      expect(nextCalled, isTrue);
      verifyNever(() => context.read<AppDatabase>());
    });
  }
}
