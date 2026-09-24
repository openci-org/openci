import 'package:openci_server/auth/server_access_policy.dart';
import 'package:test/test.dart';

void main() {
  group('server configuration', () {
    test('defaults to restricted self-hosting with no allowed users', () {
      final policy = ServerAccessPolicy.fromEnvironment({});
      expect(policy.mode, ServerAccessMode.selfHosted);
      expect(
        policy.evaluate(email: 'alice@example.com', emailVerified: true),
        ServerAccessDecision.accessDenied,
      );
      expect(
        policy.evaluate(email: 'alice@example.com', emailVerified: false),
        ServerAccessDecision.accessDenied,
      );
    });

    for (final value in ['', ' \n ', 'cloud ', 'CLOUD', 'public']) {
      test('rejects invalid access mode "$value"', () {
        expect(
          () => ServerAccessPolicy.fromEnvironment({
            'SERVER_ACCESS_MODE': value,
          }),
          throwsFormatException,
        );
      });
    }

    for (final value in ['', ' \n ']) {
      test('an empty allowlist does not enable public access', () {
        final policy = ServerAccessPolicy.fromEnvironment({
          'SERVER_ACCESS_MODE': 'self_hosted',
          'ALLOWED_USER_EMAILS': value,
        });
        expect(
          policy.evaluate(email: 'alice@example.com', emailVerified: true),
          ServerAccessDecision.accessDenied,
        );
        expect(
          policy.evaluate(email: 'alice@example.com', emailVerified: false),
          ServerAccessDecision.accessDenied,
        );
      });
    }

    for (final value in [
      '*',
      '*@example.com',
      'alice@',
      'alice@example',
      'alice@-example.com',
      'alice@example..com',
      '.alice@example.com',
      'alice..smith@example.com',
      'Alice <alice@example.com>',
      'alice@example.com,bad-address',
      'alice@example.com,',
      'alice@example.com,,bob@example.com',
      'alice@example.com;bob@example.com',
      'alice@example.com\nbob@example.com',
    ]) {
      test('rejects the entire malformed allowlist: $value', () {
        expect(
          () => ServerAccessPolicy.fromEnvironment({
            'ALLOWED_USER_EMAILS': value,
          }),
          throwsA(
            isA<FormatException>().having(
              (error) => error.toString(),
              'safe message',
              isNot(contains(value)),
            ),
          ),
        );
      });
    }

    test('trims settings and matches case-insensitively', () {
      final policy = ServerAccessPolicy.fromEnvironment({
        'ALLOWED_USER_EMAILS':
            ' Alice@Example.com ,bob@example.com,alice@example.com ',
      });
      for (final email in ['alice@example.com', 'BOB@EXAMPLE.COM']) {
        expect(
          policy.evaluate(email: email, emailVerified: true),
          ServerAccessDecision.allowed,
        );
      }
    });

    test('does not remove dots or plus suffixes when matching email', () {
      final policy = ServerAccessPolicy.fromEnvironment({
        'ALLOWED_USER_EMAILS': 'alice.smith+ci@example.com',
      });
      expect(
        policy.evaluate(
          email: 'alice.smith+ci@example.com',
          emailVerified: true,
        ),
        ServerAccessDecision.allowed,
      );
      for (final email in [
        'alicesmith+ci@example.com',
        'alice.smith@example.com',
        'alice.smith+other@example.com',
        'alice.smith+ci@other.example.com',
      ]) {
        expect(
          policy.evaluate(email: email, emailVerified: true),
          ServerAccessDecision.accessDenied,
        );
      }
    });

    test('uses a snapshot until configuration is reapplied', () {
      final environment = {'ALLOWED_USER_EMAILS': 'alice@example.com'};
      final original = ServerAccessPolicy.fromEnvironment(environment);
      environment['ALLOWED_USER_EMAILS'] = 'bob@example.com';
      final updated = ServerAccessPolicy.fromEnvironment(environment);
      expect(
        original.evaluate(email: 'alice@example.com', emailVerified: true),
        ServerAccessDecision.allowed,
      );
      expect(
        updated.evaluate(email: 'alice@example.com', emailVerified: true),
        ServerAccessDecision.accessDenied,
      );
    });
  });

  group('verified token claims', () {
    final policy = ServerAccessPolicy.fromEnvironment({
      'ALLOWED_USER_EMAILS': 'alice@example.com',
    });

    for (final verified in [false, null]) {
      test('requires positive email verification, got $verified', () {
        expect(
          policy.evaluate(email: 'alice@example.com', emailVerified: verified),
          ServerAccessDecision.emailVerificationRequired,
        );
      });
    }

    for (final email in [null, '', ' ', 'invalid', ' alice@example.com ']) {
      test('denies missing or invalid email: $email', () {
        expect(
          policy.evaluate(email: email, emailVerified: true),
          ServerAccessDecision.accessDenied,
        );
      });
    }

    test('denies a verified email outside the allowlist', () {
      expect(
        policy.evaluate(email: 'bob@example.com', emailVerified: true),
        ServerAccessDecision.accessDenied,
      );
    });

    test('denies an unverified email outside the allowlist', () {
      expect(
        policy.evaluate(email: 'bob@example.com', emailVerified: false),
        ServerAccessDecision.accessDenied,
      );
    });

    test('denies an unlisted email when verification status is missing', () {
      expect(
        policy.evaluate(email: 'bob@example.com'),
        ServerAccessDecision.accessDenied,
      );
    });

    test('explicit Cloud mode does not require verified or listed email', () {
      final cloud = ServerAccessPolicy.fromEnvironment({
        'SERVER_ACCESS_MODE': 'cloud',
        'ALLOWED_USER_EMAILS': 'ignored-in-cloud-mode',
      });
      expect(cloud.mode, ServerAccessMode.cloud);
      expect(cloud.evaluate(), ServerAccessDecision.allowed);
      expect(
        cloud.evaluate(email: 'other@example.com', emailVerified: false),
        ServerAccessDecision.allowed,
      );
    });
  });
}
