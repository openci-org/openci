import 'dart:io';
import 'dart:typed_data';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_server/storage.dart';
import 'package:test/test.dart';

import '../../../../routes/builds/[id]/artifacts.dart' as route;

class MockStorageManager extends Mock implements StorageManager {}

void main() {
  late MockStorageManager storage;

  setUpAll(() {
    registerFallbackValue(Stream<Uint8List>.value(Uint8List(0)));
  });

  setUp(() {
    storage = MockStorageManager();
  });

  group('POST /builds/<id>/artifacts', () {
    test('responds with 200 OK and downloadUrl on successful upload', () async {
      when(
        () => storage.uploadObject(
          any(),
          any(),
          size: any(named: 'size'),
        ),
      ).thenAnswer((_) async {});

      final context = TestRequestContext(
        path: '/builds/job-123/artifacts?name=app.ipa',
        method: HttpMethod.post,
        body: 'dummy-file-content',
        headers: {
          'content-length': '18',
        },
      );
      context.provide<StorageManager>(storage);

      final response = await route.onRequest(context.context, 'job-123');

      expect(response.statusCode, equals(HttpStatus.ok));

      final body = await response.json() as Map<String, dynamic>;
      expect(body['success'], isTrue);
      expect(
        body['downloadUrl'],
        equals('https://test.com/builds/job-123/artifacts?name=app.ipa'),
      );

      verify(
        () => storage.uploadObject(
          'artifacts/buildJobs/job-123/app.ipa',
          any(),
          size: 18,
        ),
      ).called(1);
    });

    test(
      'responds with 400 Bad Request when name query parameter is missing',
      () async {
        final context = TestRequestContext(
          path: '/builds/job-123/artifacts',
          method: HttpMethod.post,
          body: 'dummy-file-content',
        );
        context.provide<StorageManager>(storage);

        final response = await route.onRequest(context.context, 'job-123');

        expect(response.statusCode, equals(HttpStatus.badRequest));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], contains('name parameter is required'));
      },
    );

    test(
      'responds with 405 Method Not Allowed for unsupported methods',
      () async {
        final context = TestRequestContext(
          path: '/builds/job-123/artifacts?name=app.ipa',
          method: HttpMethod.get,
        );
        context.provide<StorageManager>(storage);

        final response = await route.onRequest(context.context, 'job-123');

        expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
      },
    );
  });
}
