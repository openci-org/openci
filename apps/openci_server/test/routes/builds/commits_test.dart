import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:openci_server/build_job/build_job_mapper.dart';
import 'package:openci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

import '../../../routes/builds/commits/index.dart' as route;

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('GET /builds/commits', () {
    test(
      'responds with 401 Unauthorized when uid is null',
      () async {
        final context = TestRequestContext(
          path: '/builds/commits',
          method: HttpMethod.get,
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>(null);

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.unauthorized));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Authentication required'));
      },
    );

    test(
      'responds with 400 Bad Request when teamId parameter is missing',
      () async {
        final context = TestRequestContext(
          path: '/builds/commits',
          method: HttpMethod.get,
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.badRequest));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Missing teamId parameter'));
      },
    );

    test(
      'responds with 403 Forbidden when user is not a member of the team',
      () async {
        final context = TestRequestContext(
          path: '/builds/commits?teamId=team-123',
          method: HttpMethod.get,
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.forbidden));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Forbidden'));
      },
    );

    test(
      'returns structured CicdCommitGroup list sorted by dependency stages and includes commitMessage',
      () async {
        final team = DriftTeam(
          id: 'team-123',
          name: 'My Team',
          githubBaseUrl: null,
          installationIds: const [],
          runNumber: 1,
          aiEnabled: true,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );
        await db.teamDao.createTeamAndMember(team, 'user-123');

        final now = DateTime.now().toUtc();
        final jobs = [
          BuildJob(
            id: 'id-c',
            status: BuildJobStatus.QUEUED,
            owner: 'org',
            repo: 'repo',
            workflowName: 'my-wf',
            workflowFileName: 'my-wf.yaml',
            commitSha: 'sha-123',
            commitMessage: 'feat: implement new api endpoint',
            branch: 'main',
            teamId: 'team-123',
            jobKey: 'job-c',
            needs: const ['job-b'],
            createdAt: now,
            updatedAt: now,
          ),
          BuildJob(
            id: 'id-a',
            status: BuildJobStatus.SUCCESS,
            owner: 'org',
            repo: 'repo',
            workflowName: 'my-wf',
            workflowFileName: 'my-wf.yaml',
            commitSha: 'sha-123',
            commitMessage: 'feat: implement new api endpoint',
            branch: 'main',
            teamId: 'team-123',
            jobKey: 'job-a',
            needs: const [],
            createdAt: now.subtract(const Duration(minutes: 2)),
            updatedAt: now.subtract(const Duration(minutes: 1)),
          ),
          BuildJob(
            id: 'id-b',
            status: BuildJobStatus.SUCCESS,
            owner: 'org',
            repo: 'repo',
            workflowName: 'my-wf',
            workflowFileName: 'my-wf.yaml',
            commitSha: 'sha-123',
            commitMessage: 'feat: implement new api endpoint',
            branch: 'main',
            teamId: 'team-123',
            jobKey: 'job-b',
            needs: const ['job-a'],
            createdAt: now.subtract(const Duration(minutes: 1)),
            updatedAt: now,
          ),
        ];

        for (final job in jobs) {
          await db.buildJobDao.insertBuildJob(job.toDrift());
        }

        final context = TestRequestContext(
          path: '/builds/commits?teamId=team-123',
          method: HttpMethod.get,
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');

        final response = await route.onRequest(context.context);

        expect(response.statusCode, equals(HttpStatus.ok));

        final bodyList = await response.json() as List<dynamic>;
        expect(bodyList.length, equals(1));

        final group = CicdCommitGroup.fromJson(
          Map<String, dynamic>.from(bodyList.first as Map),
        );

        expect(group.commitSha, equals('sha-123'));
        expect(group.commitMessage, equals('feat: implement new api endpoint'));
        expect(group.branch, equals('main'));
        expect(group.status, equals(BuildJobStatus.IN_PROGRESS));
        expect(group.workflows.length, equals(1));

        final wf = group.workflows.first;
        expect(wf.fileName, equals('my-wf.yaml'));
        expect(wf.status, equals(BuildJobStatus.IN_PROGRESS));
        expect(wf.stages.length, equals(3));

        // Stage 0: job-a
        expect(wf.stages[0].length, equals(1));
        expect(wf.stages[0][0].id, equals('id-a'));
        expect(wf.stages[0][0].label, equals('job-a'));
        expect(wf.stages[0][0].status, equals(BuildJobStatus.SUCCESS));

        // Stage 1: job-b
        expect(wf.stages[1].length, equals(1));
        expect(wf.stages[1][0].id, equals('id-b'));
        expect(wf.stages[1][0].label, equals('job-b'));
        expect(wf.stages[1][0].status, equals(BuildJobStatus.SUCCESS));

        // Stage 2: job-c
        expect(wf.stages[2].length, equals(1));
        expect(wf.stages[2][0].id, equals('id-c'));
        expect(wf.stages[2][0].label, equals('job-c'));
        expect(wf.stages[2][0].status, equals(BuildJobStatus.QUEUED));
      },
    );
  });
}
