import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/auth/internal_api_key_validator.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../../../routes/_middleware.dart' as root;
import '../../../routes/worker/_middleware.dart' as worker;

void main() {
  group('worker middleware', () {
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
    ..mount('/worker', worker.middleware(nestedRouter.call));
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
    path: '/worker/new/nested',
  );
}
