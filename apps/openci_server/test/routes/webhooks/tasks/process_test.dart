import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_server/database.dart';
import 'package:test/test.dart';

import '../../../../routes/webhooks/tasks/[id]/process.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

class _MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  group('POST /webhooks/tasks/[id]/process', () {
    late RequestContext context;
    late Request request;
    late AppDatabase db;

    setUp(() {
      context = _MockRequestContext();
      request = _MockRequest();
      db = _MockAppDatabase();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(() => context.read<AppDatabase>()).thenReturn(db);
    });

    test('returns 401 Unauthorized when not authenticated', () async {
      when(() => context.read<String?>()).thenReturn(null);

      final response = await route.onRequest(context, 'task-1');

      expect(response.statusCode, equals(HttpStatus.unauthorized));
    });
  });
}
