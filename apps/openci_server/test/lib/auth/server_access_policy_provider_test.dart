import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/auth/server_access_policy.dart';
import 'package:openci_server/auth/server_access_policy_provider.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  group('serverAccessPolicyProvider', () {
    test('an unset list provides a deny-all self-hosted policy', () async {
      final policy = await _readPolicy(
        serverAccessPolicyProvider(environment: {}),
      );

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

    test('an empty list provides a deny-all self-hosted policy', () async {
      final policy = await _readPolicy(
        serverAccessPolicyProvider(environment: {'ALLOWED_USER_EMAILS': ''}),
      );

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

    test('provides the policy configured by the environment', () async {
      final policy = await _readPolicy(
        serverAccessPolicyProvider(
          environment: {
            'SERVER_ACCESS_MODE': 'self_hosted',
            'ALLOWED_USER_EMAILS': 'alice@example.com',
          },
        ),
      );

      expect(policy.mode, ServerAccessMode.selfHosted);
      expect(
        policy.evaluate(email: 'alice@example.com', emailVerified: true),
        ServerAccessDecision.allowed,
      );
      expect(
        policy.evaluate(email: 'bob@example.com', emailVerified: true),
        ServerAccessDecision.accessDenied,
      );
    });

    test('explicit Cloud mode ignores the allowlist', () async {
      final policy = await _readPolicy(
        serverAccessPolicyProvider(
          environment: {
            'SERVER_ACCESS_MODE': 'cloud',
            'ALLOWED_USER_EMAILS': 'ignored-in-cloud-mode',
          },
        ),
      );

      expect(policy.mode, ServerAccessMode.cloud);
      expect(policy.evaluate(), ServerAccessDecision.allowed);
    });

    for (final environment in [
      {'SERVER_ACCESS_MODE': 'private-alice@example.com'},
      {'SERVER_ACCESS_MODE': ''},
      {'ALLOWED_USER_EMAILS': 'alice@example.com,invalid-address'},
    ]) {
      test('rejects invalid configuration before receiving requests', () {
        expect(
          () => serverAccessPolicyProvider(environment: environment),
          throwsA(
            isA<FormatException>().having(
              (error) => error.toString(),
              'safe message',
              isNot(contains('alice@example.com')),
            ),
          ),
        );
      });
    }

    test('shares the startup snapshot until the provider is rebuilt', () async {
      final environment = {
        'SERVER_ACCESS_MODE': 'self_hosted',
        'ALLOWED_USER_EMAILS': 'alice@example.com',
      };
      final provision = serverAccessPolicyProvider(environment: environment);
      environment['ALLOWED_USER_EMAILS'] = 'bob@example.com';
      final original = await _readPolicy(provision);

      environment['SERVER_ACCESS_MODE'] = 'cloud';
      final subsequent = await _readPolicy(provision);
      expect(subsequent, same(original));
      expect(subsequent.mode, ServerAccessMode.selfHosted);
      expect(
        subsequent.evaluate(email: 'alice@example.com', emailVerified: true),
        ServerAccessDecision.allowed,
      );
      expect(
        subsequent.evaluate(email: 'bob@example.com', emailVerified: true),
        ServerAccessDecision.accessDenied,
      );

      final rebuilt = await _readPolicy(
        serverAccessPolicyProvider(environment: environment),
      );
      expect(rebuilt, isNot(same(original)));
      expect(rebuilt.mode, ServerAccessMode.cloud);
    });
  });
}

Future<ServerAccessPolicy> _readPolicy(Middleware provision) async {
  final policies = <ServerAccessPolicy>[];
  final handler = provision((context) {
    policies.add(context.read<ServerAccessPolicy>());
    policies.add(context.read<ServerAccessPolicy>());
    return Response(statusCode: HttpStatus.noContent);
  });
  final server = await serve(handler, InternetAddress.loopbackIPv4, 0);
  addTearDown(() => server.close(force: true));
  final uri = Uri(
    scheme: 'http',
    host: server.address.address,
    port: server.port,
    path: '/protected-route',
  );
  final response = await http.get(uri);

  // Providing configuration alone must not reject requests.
  expect(response.statusCode, HttpStatus.noContent);
  expect(policies, hasLength(2));
  expect(policies.last, same(policies.first));
  return policies.first;
}
