import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:drift/native.dart';
import 'package:mocktail/mocktail.dart';
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
    when(() => context.read<AppDatabase>()).thenReturn(db);
    when(() => context.read<Map<String, String>>()).thenReturn({
      'ALLOWED_WORKER_UIDS': 'worker-123',
    });
    registerFallbackValue(
      () => DriftBuildJob(
        id: '',
        status: BuildJobStatus.QUEUED,
        owner: '',
        repo: '',
        workflowName: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('throws StateError when ALLOWED_WORKER_UIDS is missing', () async {
    final now = DateTime.now().toUtc();
    final job = DriftBuildJob(
      id: 'job-123',
      status: BuildJobStatus.QUEUED,
      owner: 'owner',
      repo: 'repo',
      workflowName: 'workflow',
      teamId: 'team-xyz',
      createdAt: now,
      updatedAt: now,
    );
    await db.buildJobDao.insertBuildJob(job);

    when(() => context.read<String?>()).thenReturn('user-123');
    when(
      () => request.uri,
    ).thenReturn(Uri.parse('http://localhost/builds/job-123'));
    when(() => context.read<Map<String, String>>()).thenReturn({});

    final handler = middleware((_) => Response());
    expect(handler(context), throwsStateError);
  });

  test('returns 401 Unauthorized when uid is null', () async {
    when(() => context.read<String?>()).thenReturn(null);

    final handler = middleware((_) => Response());
    final response = await handler(context);

    expect(response.statusCode, equals(HttpStatus.unauthorized));
  });

  test('returns 400 Bad Request when path segments are invalid', () async {
    when(() => context.read<String?>()).thenReturn('user-123');
    when(
      () => request.uri,
    ).thenReturn(Uri.parse('http://localhost/not-builds/123'));

    final handler = middleware((_) => Response());
    final response = await handler(context);

    expect(response.statusCode, equals(HttpStatus.badRequest));
  });

  test('returns 404 Not Found when build job does not exist', () async {
    when(() => context.read<String?>()).thenReturn('user-123');
    when(
      () => request.uri,
    ).thenReturn(Uri.parse('http://localhost/builds/non-existent'));

    final handler = middleware((_) => Response());
    final response = await handler(context);

    expect(response.statusCode, equals(HttpStatus.notFound));
  });

  test('returns 403 Forbidden when teamId is null', () async {
    final now = DateTime.now().toUtc();
    final job = DriftBuildJob(
      id: 'job-no-team',
      status: BuildJobStatus.QUEUED,
      owner: 'owner',
      repo: 'repo',
      workflowName: 'workflow',
      teamId: null,
      createdAt: now,
      updatedAt: now,
    );
    await db.buildJobDao.insertBuildJob(job);

    when(() => context.read<String?>()).thenReturn('user-123');
    when(
      () => request.uri,
    ).thenReturn(Uri.parse('http://localhost/builds/job-no-team'));

    final handler = middleware((_) => Response());
    final response = await handler(context);

    expect(response.statusCode, equals(HttpStatus.forbidden));
  });

  test(
    'returns 403 Forbidden when user is not member and not in allowed workers',
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
        teamId: 'team-xyz',
        createdAt: now,
        updatedAt: now,
      );
      await db.buildJobDao.insertBuildJob(job);

      when(() => context.read<String?>()).thenReturn('user-123');
      when(
        () => request.uri,
      ).thenReturn(Uri.parse('http://localhost/builds/job-xyz'));

      final handler = middleware((_) => Response());
      final response = await handler(context);

      expect(response.statusCode, equals(HttpStatus.forbidden));
    },
  );

  test('provides DriftBuildJob when authorized as team member', () async {
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
    await db.teamDao.createTeamAndMember(team, 'user-123');

    final job = DriftBuildJob(
      id: 'job-xyz',
      status: BuildJobStatus.QUEUED,
      owner: 'owner',
      repo: 'repo',
      workflowName: 'workflow',
      teamId: 'team-xyz',
      createdAt: now,
      updatedAt: now,
    );
    await db.buildJobDao.insertBuildJob(job);

    when(() => context.read<String?>()).thenReturn('user-123');
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
  });
}
