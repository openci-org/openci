import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../routes/installations/[id]/token.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

void main() {
  group('GET /installations/[id]/token', () {
    late RequestContext context;
    late Request request;

    setUp(() {
      context = _MockRequestContext();
      request = _MockRequest();
      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.get);
    });

    test('returns 401 Unauthorized when user is not authenticated', () async {
      when(() => context.read<String?>()).thenReturn(null);

      final response = await route.onRequest(context, '12345678');

      expect(response.statusCode, equals(HttpStatus.unauthorized));
    });

    test(
      'returns mock token when GitHub App keys are unconfigured (dev mode fallback)',
      () async {
        when(() => context.read<String?>()).thenReturn('system-job-processor');

        final response = await route.onRequest(context, '12345678');

        expect(response.statusCode, equals(HttpStatus.ok));
        final body = await response.json() as Map<String, dynamic>;
        expect(body['token'], isNotEmpty);
      },
    );
  });
}
