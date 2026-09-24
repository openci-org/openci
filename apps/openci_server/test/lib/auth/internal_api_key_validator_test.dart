import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:openci_server/auth/internal_api_key_validator.dart';
import 'package:test/test.dart';

void main() {
  Request request({
    String query = '',
    Map<String, String> headers = const {},
  }) => Request(
    'POST',
    Uri.parse('https://api.openci.test/any-route$query'),
    headers: headers,
  );

  group('InternalApiKeyValidator.readInternalApiKey', () {
    test('reads the configured internal key', () {
      const validator = InternalApiKeyValidator.forTesting(
        environment: {'INTERNAL_API_KEY': 'test-internal-key'},
      );

      expect(validator.readInternalApiKey(), 'test-internal-key');
    });

    test('returns null when the internal key is unset', () {
      const validator = InternalApiKeyValidator.forTesting(environment: {});

      expect(validator.readInternalApiKey(), isNull);
    });

    test('returns null when the internal key is empty', () {
      const validator = InternalApiKeyValidator.forTesting(
        environment: {'INTERNAL_API_KEY': ''},
      );

      expect(validator.readInternalApiKey(), isNull);
    });
  });

  group('InternalApiKeyValidator.extractToken', () {
    test('extracts a Bearer token from the authorization header', () {
      const validator = InternalApiKeyValidator.forTesting(environment: {});
      final value = request(headers: {'Authorization': 'Bearer header-token'});

      expect(validator.extractToken(value), 'header-token');
    });

    test('accepts a lowercase authorization header', () {
      const validator = InternalApiKeyValidator.forTesting(environment: {});
      final value = request(headers: {'authorization': 'Bearer header-token'});

      expect(validator.extractToken(value), 'header-token');
    });

    test('extracts the token query parameter', () {
      const validator = InternalApiKeyValidator.forTesting(environment: {});

      expect(
        validator.extractToken(request(query: '?token=query-token')),
        'query-token',
      );
    });

    test('extracts the auth query parameter', () {
      const validator = InternalApiKeyValidator.forTesting(environment: {});

      expect(
        validator.extractToken(request(query: '?auth=query-token')),
        'query-token',
      );
    });

    test('prefers a Bearer token over both query parameters', () {
      const validator = InternalApiKeyValidator.forTesting(environment: {});
      final value = request(
        query: '?token=query-token&auth=query-auth',
        headers: {'Authorization': 'Bearer header-token'},
      );

      expect(validator.extractToken(value), 'header-token');
    });

    test('does not replace an empty Bearer token with a query token', () {
      const validator = InternalApiKeyValidator.forTesting(environment: {});
      final value = request(
        query: '?token=query-token',
        headers: {'Authorization': 'Bearer '},
      );

      expect(validator.extractToken(value), isEmpty);
    });

    test('prefers the token query parameter over auth', () {
      const validator = InternalApiKeyValidator.forTesting(environment: {});
      final value = request(query: '?token=query-token&auth=query-auth');

      expect(validator.extractToken(value), 'query-token');
    });

    test('returns null when no token is present', () {
      const validator = InternalApiKeyValidator.forTesting(environment: {});

      expect(validator.extractToken(request()), isNull);
    });

    test('returns null for a non-Bearer header without query credentials', () {
      const validator = InternalApiKeyValidator.forTesting(environment: {});
      final value = request(headers: {'Authorization': 'Basic header-token'});

      expect(validator.extractToken(value), isNull);
    });

    test('preserves query fallback for a non-Bearer header', () {
      const validator = InternalApiKeyValidator.forTesting(environment: {});
      final value = request(
        query: '?auth=query-token',
        headers: {'Authorization': 'Basic header-token'},
      );

      expect(validator.extractToken(value), 'query-token');
    });
  });

  group('InternalApiKeyValidator.matchesInternalApiKey', () {
    test('accepts an exact match', () {
      const validator = InternalApiKeyValidator.forTesting(environment: {});

      expect(
        validator.matchesInternalApiKey('internal-key', 'internal-key'),
        isTrue,
      );
    });

    test('rejects a missing token', () {
      const validator = InternalApiKeyValidator.forTesting(environment: {});

      expect(validator.matchesInternalApiKey(null, 'internal-key'), isFalse);
    });

    test('rejects an empty token', () {
      const validator = InternalApiKeyValidator.forTesting(environment: {});

      expect(validator.matchesInternalApiKey('', 'internal-key'), isFalse);
    });

    test('rejects an empty key even when both strings match', () {
      const validator = InternalApiKeyValidator.forTesting(environment: {});

      expect(validator.matchesInternalApiKey('', ''), isFalse);
    });

    for (final token in [
      'incorrect-key',
      'internal-ke',
      'internal-key-extra',
      'internal-keY',
    ]) {
      test('rejects a different token: $token', () {
        const validator = InternalApiKeyValidator.forTesting(environment: {});

        expect(validator.matchesInternalApiKey(token, 'internal-key'), isFalse);
      });
    }
  });

  group('InternalApiKeyValidator.isValid', () {
    test('accepts a matching key without a UID', () {
      const validator = InternalApiKeyValidator.forTesting(
        environment: {'INTERNAL_API_KEY': 'test-internal-key'},
      );
      final context = TestRequestContext(
        path: '/any-route',
        headers: {'Authorization': 'Bearer test-internal-key'},
      );

      expect(validator.isValid(context.context), isTrue);
    });

    test(
      'rejects a different Bearer token even when the query key matches',
      () {
        const validator = InternalApiKeyValidator.forTesting(
          environment: {'INTERNAL_API_KEY': 'test-internal-key'},
        );
        final context = TestRequestContext(
          path: '/any-route?token=test-internal-key',
          headers: {'Authorization': 'Bearer different-token'},
        );

        expect(validator.isValid(context.context), isFalse);
      },
    );

    test('rejects requests when the internal key is unset', () {
      const validator = InternalApiKeyValidator.forTesting(environment: {});
      final context = TestRequestContext(
        path: '/any-route',
        headers: {'Authorization': 'Bearer test-internal-key'},
      );

      expect(validator.isValid(context.context), isFalse);
    });
  });
}
