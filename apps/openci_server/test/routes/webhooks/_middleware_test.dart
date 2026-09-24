import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:openci_server/auth/internal_api_key_validator.dart';
import 'package:openci_server/database.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../routes/_middleware.dart' as root;
import '../../../routes/webhooks/_middleware.dart' as webhooks;
import '../../../routes/webhooks/claim.dart' as claim;
import '../../../routes/webhooks/tasks/[id]/complete.dart' as complete;
import '../../../routes/webhooks/tasks/[id]/fail.dart' as fail;

class _MockDatabase extends Mock implements AppDatabase {}

void main() {
  for (final (path, route) in <(String, Handler)>[
    ('/webhooks/claim', claim.onRequest),
    (
      '/webhooks/tasks/task-1/complete',
      (context) => complete.onRequest(context, 'task-1'),
    ),
    (
      '/webhooks/tasks/task-1/fail',
      (context) => fail.onRequest(context, 'task-1'),
    ),
  ]) {
    group('POST $path', () {
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
        test('rejects $name before reading the body or database', () async {
          const validator = InternalApiKeyValidator.forTesting(
            environment: {'INTERNAL_API_KEY': 'test-internal-key'},
          );
          final db = _MockDatabase();
          final context = TestRequestContext(
            path: path,
            method: HttpMethod.post,
            headers: {
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: 'not-json',
          );
          context.provide<AppDatabase>(db);
          context.provide<String?>(uid);
          context.provide<InternalApiKeyValidator>(validator);

          final response = await webhooks.middleware(route)(context.context);

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

  group('webhooks middleware', () {
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
      expect(jsonDecode(response.body), {
        'success': false,
        'error': 'Authentication required',
      });
    });

    test('preserves CORS preflight without credentials', () async {
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
  });
}

Future<Uri> _startServer({
  required InternalApiKeyValidator validator,
  required Handler handler,
}) async {
  final nestedRouter = Router()..all('/new/nested', handler);
  final router = Router()
    ..mount('/webhooks', webhooks.middleware(nestedRouter.call));
  final server = await serve(
    router.call
        .use(provider<InternalApiKeyValidator>((_) => validator))
        .use(root.corsMiddleware(environment: const {})),
    InternetAddress.loopbackIPv4,
    0,
  );
  addTearDown(() => server.close(force: true));
  return Uri(
    scheme: 'http',
    host: server.address.address,
    port: server.port,
    path: '/webhooks/new/nested',
  );
}
