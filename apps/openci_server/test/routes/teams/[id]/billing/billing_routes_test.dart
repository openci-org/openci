import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:firebase_admin_sdk/auth.dart';
import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_server/auth/internal_api_key_validator.dart';
import 'package:openci_server/billing/billing_proxy.dart';
import 'package:openci_server/billing/billing_proxy_config.dart';
import 'package:test/test.dart';

import '../../../../../routes/_middleware.dart' as root;
import '../../../../../routes/teams/[id]/billing/checkout.dart' as checkout;
import '../../../../../routes/teams/[id]/billing/index.dart' as status;
import '../../../../../routes/teams/[id]/billing/portal.dart' as portal;

class _MockFirebaseApp extends Mock implements FirebaseApp {}

class _MockAuth extends Mock implements Auth {}

class _MockDecodedIdToken extends Mock implements DecodedIdToken {}

void main() {
  late BillingProxy proxy;
  late List<http.Request> requests;

  setUp(() {
    requests = [];
    final client = MockClient((request) async {
      requests.add(request);
      return http.Response('{"error":"forbidden"}', HttpStatus.forbidden);
    });
    addTearDown(client.close);
    proxy = BillingProxy(
      BillingProxyConfig.fromEnvironment({
        'SERVER_ACCESS_MODE': 'cloud',
        'BILLING_ENABLED': 'true',
        'GENUINECI_SERVER_URL': 'http://genuineci-server:8081',
        'BILLING_INTERNAL_TOKEN': '01234567890123456789012345678901',
      })!,
      client,
    );
  });

  for (final endpoint in [
    (name: 'status', handler: status.onRequest, method: HttpMethod.get),
    (name: 'checkout', handler: checkout.onRequest, method: HttpMethod.post),
    (name: 'portal', handler: portal.onRequest, method: HttpMethod.post),
  ]) {
    group(endpoint.name, () {
      test(
        'disabled billing returns 404 without authentication or network',
        () async {
          final context = TestRequestContext(
            path: '/teams/team-1/billing',
            method: endpoint.method,
          );
          context.provide<BillingProxy?>(null);
          final response = await endpoint.handler(context.context, 'team-1');
          expect(response.statusCode, HttpStatus.notFound);
          expect(requests, isEmpty);
        },
      );

      test(
        'requires a verified UID, ignoring caller-supplied identity',
        () async {
          final context = TestRequestContext(
            path: '/teams/team-1/billing',
            method: endpoint.method,
            headers: {'x-genuineci-user-id': 'forged-user'},
            body: '{"planId":"light","userId":"forged-user"}',
          );
          context.provide<BillingProxy?>(proxy);
          context.provide<String?>(null);
          final response = await endpoint.handler(context.context, 'team-1');
          expect(response.statusCode, HttpStatus.unauthorized);
          expect(response.headers['cache-control'], 'no-store');
          expect(requests, isEmpty);
        },
      );

      test('rejects other HTTP methods before forwarding', () async {
        final context = TestRequestContext(
          path: '/teams/team-1/billing',
          method: HttpMethod.delete,
        );
        context.provide<BillingProxy?>(proxy);
        final response = await endpoint.handler(context.context, 'team-1');
        expect(response.statusCode, HttpStatus.methodNotAllowed);
        expect(requests, isEmpty);
      });

      test(
        'passes verified identity and preserves Go membership denial',
        () async {
          final context = TestRequestContext(
            path: '/teams/team-1/billing',
            method: endpoint.method,
            body: endpoint.name == 'checkout' ? '{"planId":"pro"}' : '',
          );
          context.provide<BillingProxy?>(proxy);
          context.provide<String?>('verified-user');
          final response = await endpoint.handler(context.context, 'team-1');
          expect(response.statusCode, HttpStatus.forbidden);
          expect(await response.json(), {'error': 'forbidden'});
          expect(requests, hasLength(1));
          expect(
            requests.single.headers['x-genuineci-user-id'],
            'verified-user',
          );
          expect(requests.single.url.pathSegments, [
            'internal',
            'billing',
            'teams',
            'team-1',
            if (endpoint.name != 'status') endpoint.name,
          ]);
        },
      );
    });
  }

  test('Checkout rejects invalid plans and server-controlled fields', () async {
    for (final body in [
      '',
      '{}',
      '[]',
      '{',
      '{"planId":"trial"}',
      '{"planId":1}',
      '{"planId":"light","userId":"other"}',
      '{"planId":"light","returnUrl":"https://attacker.example"}',
      '{"planId":"light","priceId":"price_other"}',
    ]) {
      final context = TestRequestContext(
        path: '/teams/team-1/billing',
        method: HttpMethod.post,
        body: body,
      );
      context.provide<BillingProxy?>(proxy);
      context.provide<String?>('user-1');
      final response = await checkout.onRequest(context.context, 'team-1');
      expect(response.statusCode, HttpStatus.badRequest, reason: body);
    }
    expect(requests, isEmpty);
  });

  test('Portal rejects customer IDs and return URLs', () async {
    final context = TestRequestContext(
      path: '/teams/team-1/billing',
      method: HttpMethod.post,
      body: '{"customerId":"cus_other","returnUrl":"https://attacker.example"}',
    );
    context.provide<BillingProxy?>(proxy);
    context.provide<String?>('user-1');
    final response = await portal.onRequest(context.context, 'team-1');
    expect(response.statusCode, HttpStatus.badRequest);
    expect(requests, isEmpty);
  });

  test('oversized bodies never reach Go', () async {
    final context = TestRequestContext(
      path: '/teams/team-1/billing',
      method: HttpMethod.post,
      body: jsonEncode({'planId': 'a' * 4096}),
    );
    context.provide<BillingProxy?>(proxy);
    context.provide<String?>('user-1');
    final response = await checkout.onRequest(context.context, 'team-1');
    expect(response.statusCode, HttpStatus.requestEntityTooLarge);
    expect(requests, isEmpty);
  });

  test('root authentication supplies the UID from the Firebase token', () async {
    final firebase = _MockFirebaseApp();
    final auth = _MockAuth();
    final token = _MockDecodedIdToken();
    when(() => firebase.auth()).thenReturn(auth);
    when(() => token.uid).thenReturn('verified-user');
    when(() => token.emailVerified).thenReturn(true);
    when(
      () => auth.verifyIdToken('firebase-token', checkRevoked: false),
    ).thenAnswer((_) async => token);
    final server = await serve(
      ((RequestContext context) => checkout.onRequest(context, 'team-1'))
          .use(provider<BillingProxy?>((_) => proxy))
          .use(root.authProvider(firebase))
          .use(
            provider<InternalApiKeyValidator>(
              (_) => const InternalApiKeyValidator(environment: {}),
            ),
          ),
      InternetAddress.loopbackIPv4,
      0,
    );
    addTearDown(() => server.close(force: true));
    final client = http.Client();
    addTearDown(client.close);
    final response = await client.post(
      Uri.parse(
        'http://${server.address.address}:${server.port}/teams/team-1/billing/checkout',
      ),
      headers: {
        'authorization': 'Bearer firebase-token',
        'x-genuineci-user-id': 'forged-user',
      },
      body: '{"planId":"light"}',
    );
    expect(response.statusCode, HttpStatus.forbidden);
    expect(requests.single.headers['x-genuineci-user-id'], 'verified-user');
    expect(
      requests.single.headers['authorization'],
      isNot(contains('firebase-token')),
    );
  });
}
