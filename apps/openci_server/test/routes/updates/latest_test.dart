import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/storage.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

import '../../../routes/updates/[owner]/[repo]/macos/latest.dart' as route;

class MockStorageManager extends Mock implements StorageManager {}

void main() {
  late AppDatabase db;
  late MockStorageManager storage;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    storage = MockStorageManager();
  });

  tearDown(() async {
    await db.close();
  });

  group('GET /updates/<owner>/<repo>/macos/latest', () {
    test('responds with 404 when no successful macOS build is found', () async {
      final context = TestRequestContext(
        path: '/updates/openci-org/openci/macos/latest',
        method: HttpMethod.get,
      );
      context.provide<AppDatabase>(db);
      context.provide<StorageManager>(storage);

      final response = await route.onRequest(
        context.context,
        'openci-org',
        'openci',
      );

      expect(response.statusCode, equals(HttpStatus.notFound));
      final body = await response.json() as Map<String, dynamic>;
      expect(body['success'], isFalse);
      expect(body['error'], contains('No successful macOS build found'));
    });

    test(
      'responds with 404 when successful macOS build exists but zip is missing in storage',
      () async {
        final job = DriftBuildJob(
          id: 'job-123',
          status: BuildJobStatus.SUCCESS,
          owner: 'openci-org',
          repo: 'openci',
          workflowName: 'CI',
          runsOn: 'macos-latest',
          branch: 'develop',
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
          completedAt: DateTime.now().toUtc(),
        );
        await db.buildJobDao.insertBuildJob(job);

        when(
          () => storage.downloadObject(
            'artifacts/buildJobs/job-123/OpenCI-dashboard-macos.zip',
          ),
        ).thenThrow(Exception('NoSuchKey'));

        final context = TestRequestContext(
          path: '/updates/openci-org/openci/macos/latest',
          method: HttpMethod.get,
        );
        context.provide<AppDatabase>(db);
        context.provide<StorageManager>(storage);

        final response = await route.onRequest(
          context.context,
          'openci-org',
          'openci',
        );

        expect(response.statusCode, equals(HttpStatus.notFound));
        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], contains('Artifact not found for build'));
      },
    );

    test(
      'responds with 200 and zip stream when zip exists in storage',
      () async {
        final job = DriftBuildJob(
          id: 'job-123',
          status: BuildJobStatus.SUCCESS,
          owner: 'openci-org',
          repo: 'openci',
          workflowName: 'CI',
          runsOn: 'macos-latest',
          branch: 'develop',
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
          completedAt: DateTime.now().toUtc(),
        );
        await db.buildJobDao.insertBuildJob(job);

        final dummyZipContent = 'dummy zip bytes'.codeUnits;
        when(
          () => storage.downloadObject(
            'artifacts/buildJobs/job-123/OpenCI-dashboard-macos.zip',
          ),
        ).thenAnswer((_) async => Stream<List<int>>.value(dummyZipContent));

        final context = TestRequestContext(
          path: '/updates/openci-org/openci/macos/latest',
          method: HttpMethod.get,
        );
        context.provide<AppDatabase>(db);
        context.provide<StorageManager>(storage);

        final response = await route.onRequest(
          context.context,
          'openci-org',
          'openci',
        );

        expect(response.statusCode, equals(HttpStatus.ok));
        expect(
          response.headers[HttpHeaders.contentTypeHeader],
          equals('application/zip'),
        );
        expect(
          response.headers['content-disposition'],
          equals('attachment; filename="OpenCI-dashboard-macos.zip"'),
        );

        final responseBody = await response.body();
        expect(responseBody, equals('dummy zip bytes'));
      },
    );
  });
}
