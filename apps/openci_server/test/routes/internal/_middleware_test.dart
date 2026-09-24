import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:openci_server/auth/internal_api_key_validator.dart';
import 'package:openci_server/database.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../routes/_middleware.dart' as root;
import '../../../routes/internal/_middleware.dart' as internal;
import '../../../routes/internal/build_jobs.dart' as build_jobs;
import '../../../routes/internal/seed/index.dart' as seed;
import '../../../routes/internal/seed/jobs.dart' as seed_jobs;
import '../../../routes/internal/seed/teams.dart' as seed_teams;

class _MockDatabase extends Mock implements AppDatabase {}

void main() {
  for (final (path, method, route) in <(String, HttpMethod, Handler)>[
    ('/internal/build_jobs', HttpMethod.delete, build_jobs.onRequest),
    ('/internal/seed', HttpMethod.post, seed.onRequest),
    ('/internal/seed/teams', HttpMethod.post, seed_teams.onRequest),
    ('/internal/seed/jobs', HttpMethod.post, seed_jobs.onRequest),
    ('/internal/seed/jobs', HttpMethod.delete, seed_jobs.onRequest),
  ]) {
    group('${method.name} $path', () {
      test('allows the internal key without a UID', () async {
        const validator = InternalApiKeyValidator.forTesting(
          environment: {'INTERNAL_API_KEY': 'test-internal-key'},
        );
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final context = TestRequestContext(
          path: path,
          method: method,
          headers: {'Authorization': 'Bearer test-internal-key'},
          body: '{"installationId":"42"}',
        );
        context.provide<AppDatabase>(db);
        context.provide<InternalApiKeyValidator>(validator);

        final response = await internal.middleware(route)(context.context);

        expect(response.statusCode, HttpStatus.ok);
        expect((await response.json())['success'], isTrue);
      });

      for (final (name, token, uid) in [
        ('missing credentials', null, null),
        ('an empty token', '', null),
        ('an incorrect key', 'wrong-key', 'system-job-processor'),
        ('a Firebase user token', 'firebase-token', 'user-1'),
        (
          'a Firebase token with the reserved UID',
          'firebase-token',
          'system-job-processor',
        ),
      ]) {
        test('rejects $name before accessing the database', () async {
          const validator = InternalApiKeyValidator.forTesting(
            environment: {'INTERNAL_API_KEY': 'test-internal-key'},
          );
          final db = _MockDatabase();
          final context = TestRequestContext(
            path: path,
            method: method,
            headers: {
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: 'not-json',
          );
          context.provide<AppDatabase>(db);
          context.provide<String?>(uid);
          context.provide<InternalApiKeyValidator>(validator);

          final response = await internal.middleware(route)(context.context);

          expect(response.statusCode, HttpStatus.unauthorized);
          expect(await response.json(), {
            'success': false,
            'error': 'Authentication required',
          });
          verifyZeroInteractions(db);
        });
      }
    });
  }

  group('internal middleware with root middleware', () {
    test('allows an internal key on a newly added nested route', () async {
      const validator = InternalApiKeyValidator.forTesting(
        environment: {'INTERNAL_API_KEY': 'test-internal-key'},
      );
      final uri = await _startServer(
        validator: validator,
        handler: (_) => Response(statusCode: HttpStatus.noContent),
      );

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer test-internal-key'},
      );

      expect(response.statusCode, HttpStatus.noContent);
    });

    test('rejects missing credentials on a newly added nested route', () async {
      const validator = InternalApiKeyValidator.forTesting(
        environment: {'INTERNAL_API_KEY': 'test-internal-key'},
      );
      final uri = await _startServer(
        validator: validator,
        handler: (_) => throw StateError('Handler must not run'),
      );

      final response = await http.get(uri);

      expect(response.statusCode, HttpStatus.unauthorized);
    });

    test('allows CORS preflight when internal APIs are enabled', () async {
      const validator = InternalApiKeyValidator.forTesting(environment: {});
      final uri = await _startServer(
        validator: validator,
        handler: (_) => throw StateError('Handler must not run'),
      );
      final client = http.Client();
      addTearDown(client.close);
      final request = http.Request('OPTIONS', uri)
        ..headers['Origin'] = 'https://dashboard.openci.org';

      final response = await client.send(request);
      await response.stream.drain<void>();

      expect(response.statusCode, HttpStatus.ok);
      expect(
        response.headers['access-control-allow-origin'],
        'https://dashboard.openci.org',
      );
    });

    for (final method in ['POST', 'OPTIONS']) {
      test('returns 404 for disabled $method even with a valid key', () async {
        const validator = InternalApiKeyValidator.forTesting(
          environment: {'INTERNAL_API_KEY': 'test-internal-key'},
        );
        final uri = await _startServer(
          validator: validator,
          environment: {'ENABLE_INTERNAL_API': 'false'},
          handler: (_) => throw StateError('Handler must not run'),
        );
        final client = http.Client();
        addTearDown(client.close);
        final request = http.Request(method, uri)
          ..headers.addAll({
            'Authorization': 'Bearer test-internal-key',
            'Origin': 'https://dashboard.openci.org',
          });

        final response = await client.send(request);
        await response.stream.drain<void>();

        expect(response.statusCode, HttpStatus.notFound);
        expect(
          response.headers,
          isNot(contains('access-control-allow-origin')),
        );
      });
    }
  });
}

Future<Uri> _startServer({
  required InternalApiKeyValidator validator,
  required Handler handler,
  Map<String, String> environment = const {'ENABLE_INTERNAL_API': 'true'},
}) async {
  final nestedRouter = Router()..all('/new/nested', handler);
  final router = Router()
    ..mount('/internal', internal.middleware(nestedRouter.call));
  final server = await serve(
    router.call
        .use(provider<InternalApiKeyValidator>((_) => validator))
        .use(root.corsMiddleware(environment: environment))
        .use(root.internalRoutesMiddleware(environment: environment)),
    InternetAddress.loopbackIPv4,
    0,
  );
  addTearDown(() => server.close(force: true));
  return Uri(
    scheme: 'http',
    host: server.address.address,
    port: server.port,
    path: '/internal/new/nested',
  );
}
