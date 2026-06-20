import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

import '../../../routes/builds/[id]/index.dart' as route;

DateTime _getNormalizedNow() {
  final now = DateTime.now().toUtc();
  return DateTime.utc(
    now.year,
    now.month,
    now.day,
    now.hour,
    now.minute,
    now.second,
  );
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('GET /builds/<id>', () {
    test(
      'responds with 200 OK and build job details when user is a member of the team',
      () async {
        final now = _getNormalizedNow();
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

        final context = TestRequestContext(
          path: '/builds/job-xyz',
          method: HttpMethod.get,
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');
        context.provide<DriftBuildJob>(job);

        final response = await route.onRequest(context.context, 'job-xyz');

        expect(response.statusCode, equals(HttpStatus.ok));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['id'], equals('job-xyz'));
        expect(body['teamId'], equals('team-xyz'));
        expect(body['status'], equals('QUEUED'));
      },
    );
  });

  group('PATCH /builds/<id>', () {
    test(
      'responds with 400 Bad Request when body is invalid JSON',
      () async {
        final now = _getNormalizedNow();
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

        final context = TestRequestContext(
          path: '/builds/job-xyz',
          method: HttpMethod.patch,
          body: 'not-a-json',
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');
        context.provide<DriftBuildJob>(job);

        final response = await route.onRequest(context.context, 'job-xyz');

        expect(response.statusCode, equals(HttpStatus.badRequest));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], contains('Invalid JSON'));
      },
    );

    test(
      'responds with 200 OK and updates build job when user is a member of the team',
      () async {
        final now = _getNormalizedNow();
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

        final payload = {
          'status': 'SUCCESS',
          'latestRunId': 'run-456',
          'runCount': 5,
          'failureSummary': 'Build failed due to test failure',
          'failureSummaryModel': 'gemini-1.5-pro',
          'failureSummaryStatus': 'completed',
          'failureSummaryDurationMs': 1200,
          'ipaUrl': 'https://s3.example.com/build.ipa',
          'hasIpa': true,
          'bundleId': 'com.example.app',
          'ipaVersion': '1.0.0',
          'appName': 'Test App',
          'completedAt': now.toIso8601String(),
        };

        final context = TestRequestContext(
          path: '/builds/job-xyz',
          method: HttpMethod.patch,
          body: jsonEncode(payload),
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');
        context.provide<DriftBuildJob>(job);

        final response = await route.onRequest(context.context, 'job-xyz');

        expect(response.statusCode, equals(HttpStatus.ok));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isTrue);

        final updatedDrift = await db.buildJobDao.getBuildJob('job-xyz');
        expect(updatedDrift, isNotNull);
        expect(updatedDrift!.status, equals(BuildJobStatus.SUCCESS));
        expect(updatedDrift.latestRunId, equals('run-456'));
        expect(updatedDrift.runCount, equals(5));
        expect(
          updatedDrift.failureSummary,
          equals('Build failed due to test failure'),
        );
        expect(updatedDrift.failureSummaryModel, equals('gemini-1.5-pro'));
        expect(updatedDrift.failureSummaryStatus, equals('completed'));
        expect(updatedDrift.failureSummaryDurationMs, equals(1200));
        expect(updatedDrift.ipaUrl, equals('https://s3.example.com/build.ipa'));
        expect(updatedDrift.hasIpa, isTrue);
        expect(updatedDrift.bundleId, equals('com.example.app'));
        expect(updatedDrift.ipaVersion, equals('1.0.0'));
        expect(updatedDrift.appName, equals('Test App'));
        expect(
          updatedDrift.completedAt?.toUtc().toIso8601String(),
          equals(now.toIso8601String()),
        );
      },
    );

    test(
      'responds with 400 Bad Request when JSON schema is incorrect (type mismatch)',
      () async {
        final now = _getNormalizedNow();
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

        final context = TestRequestContext(
          path: '/builds/job-xyz',
          method: HttpMethod.patch,
          body: '{"runCount": "should-be-int"}',
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');
        context.provide<DriftBuildJob>(job);

        final response = await route.onRequest(context.context, 'job-xyz');

        expect(response.statusCode, equals(HttpStatus.badRequest));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], contains('Invalid payload structure'));
      },
    );

    test(
      'responds with 400 Bad Request when status is invalid (ArgumentError)',
      () async {
        final now = _getNormalizedNow();
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

        final context = TestRequestContext(
          path: '/builds/job-xyz',
          method: HttpMethod.patch,
          body: '{"status": "INVALID_STATUS"}',
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');
        context.provide<DriftBuildJob>(job);

        final response = await route.onRequest(context.context, 'job-xyz');

        expect(response.statusCode, equals(HttpStatus.badRequest));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], contains('Invalid status'));
      },
    );

    test(
      'responds with 400 Bad Request when completedAt is invalid date format (FormatException)',
      () async {
        final now = _getNormalizedNow();
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

        final context = TestRequestContext(
          path: '/builds/job-xyz',
          method: HttpMethod.patch,
          body: '{"completedAt": "invalid-date-string"}',
        );

        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');
        context.provide<DriftBuildJob>(job);

        final response = await route.onRequest(context.context, 'job-xyz');

        expect(response.statusCode, equals(HttpStatus.badRequest));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], contains('Invalid date format'));
      },
    );
  });
}
