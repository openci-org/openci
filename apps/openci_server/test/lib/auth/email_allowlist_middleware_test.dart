import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:openci_server/auth/email_allowlist_middleware.dart';
import 'package:openci_server/auth/server_access_policy.dart';
import 'package:openci_server/auth/user_email_info.dart';
import 'package:test/test.dart';

void main() {
  final policy = ServerAccessPolicy.fromEnvironment({
    'ALLOWED_USER_EMAILS': 'test@openci.org',
  });
  late TestRequestContext context;

  setUp(() {
    context = TestRequestContext(path: '/teams');
    context.provide<ServerAccessPolicy>(policy);
  });

  test('returns the handler response for a listed email', () async {
    context.provide<UserEmailInfo?>((
      email: 'test@openci.org',
      emailVerified: true,
    ));
    final expected = Response(
      statusCode: HttpStatus.accepted,
      body: 'accepted',
    );
    final handler = emailAllowlistMiddleware()((_) => expected);

    expect(await handler(context.context), same(expected));
  });

  test('matches a listed email regardless of letter case', () async {
    context.provide<UserEmailInfo?>((
      email: 'Test@OpenCI.ORG',
      emailVerified: true,
    ));
    final handler = emailAllowlistMiddleware()((_) => Response());

    final response = await handler(context.context);

    expect(response.statusCode, HttpStatus.ok);
  });

  test('rejects an unlisted email before calling the handler', () async {
    context.provide<UserEmailInfo?>((
      email: 'other@openci.org',
      emailVerified: true,
    ));
    final handler = emailAllowlistMiddleware()(
      (_) => fail('Rejected requests must not reach the handler'),
    );

    final response = await handler(context.context);

    expect(response.statusCode, HttpStatus.forbidden);
    expect(await response.json(), {
      'success': false,
      'error': 'Access denied',
      'code': 'access_denied',
    });
  });

  test('rejects missing identity information', () async {
    context.provide<UserEmailInfo?>(null);
    final handler = emailAllowlistMiddleware()(
      (_) => fail('Rejected requests must not reach the handler'),
    );

    final response = await handler(context.context);

    expect(response.statusCode, HttpStatus.forbidden);
  });

  test('rejects a missing email', () async {
    context.provide<UserEmailInfo?>((email: null, emailVerified: true));
    final handler = emailAllowlistMiddleware()(
      (_) => fail('Rejected requests must not reach the handler'),
    );

    final response = await handler(context.context);

    expect(response.statusCode, HttpStatus.forbidden);
  });

  test('rejects an invalid email', () async {
    context.provide<UserEmailInfo?>((
      email: 'not-an-email',
      emailVerified: true,
    ));
    final handler = emailAllowlistMiddleware()(
      (_) => fail('Rejected requests must not reach the handler'),
    );

    final response = await handler(context.context);

    expect(response.statusCode, HttpStatus.forbidden);
  });

  test('rejects access when the allowlist is unset', () async {
    context.provide<ServerAccessPolicy>(ServerAccessPolicy.fromEnvironment({}));
    context.provide<UserEmailInfo?>((
      email: 'test@openci.org',
      emailVerified: true,
    ));
    final handler = emailAllowlistMiddleware()(
      (_) => fail('Rejected requests must not reach the handler'),
    );

    final response = await handler(context.context);

    expect(response.statusCode, HttpStatus.forbidden);
  });

  test('rejects access when the allowlist is empty', () async {
    context.provide<ServerAccessPolicy>(
      ServerAccessPolicy.fromEnvironment({'ALLOWED_USER_EMAILS': ''}),
    );
    context.provide<UserEmailInfo?>((
      email: 'test@openci.org',
      emailVerified: true,
    ));
    final handler = emailAllowlistMiddleware()(
      (_) => fail('Rejected requests must not reach the handler'),
    );

    final response = await handler(context.context);

    expect(response.statusCode, HttpStatus.forbidden);
  });

  test('allows a listed email even when it is unverified', () async {
    context.provide<UserEmailInfo?>((
      email: 'test@openci.org',
      emailVerified: false,
    ));
    final handler = emailAllowlistMiddleware()((_) => Response());

    final response = await handler(context.context);

    expect(response.statusCode, HttpStatus.ok);
  });

  test('allows a listed email with a missing verification claim', () async {
    context.provide<UserEmailInfo?>((
      email: 'test@openci.org',
      emailVerified: null,
    ));
    final handler = emailAllowlistMiddleware()((_) => Response());

    final response = await handler(context.context);

    expect(response.statusCode, HttpStatus.ok);
  });

  test('ignores an allowed email supplied in the query parameter', () async {
    context = TestRequestContext(path: '/teams?email=test%40openci.org');
    context.provide<ServerAccessPolicy>(policy);
    context.provide<UserEmailInfo?>((
      email: 'other@openci.org',
      emailVerified: true,
    ));
    final handler = emailAllowlistMiddleware()(
      (_) => fail('Rejected requests must not reach the handler'),
    );

    final response = await handler(context.context);

    expect(response.statusCode, HttpStatus.forbidden);
  });

  test('ignores an allowed email supplied in the header', () async {
    context = TestRequestContext(
      path: '/teams',
      headers: {'email': 'test@openci.org'},
    );
    context.provide<ServerAccessPolicy>(policy);
    context.provide<UserEmailInfo?>((
      email: 'other@openci.org',
      emailVerified: true,
    ));
    final handler = emailAllowlistMiddleware()(
      (_) => fail('Rejected requests must not reach the handler'),
    );

    final response = await handler(context.context);

    expect(response.statusCode, HttpStatus.forbidden);
  });

  test('ignores an allowed email supplied in the body', () async {
    context = TestRequestContext(
      path: '/teams',
      method: HttpMethod.post,
      body: '{"email":"test@openci.org"}',
    );
    context.provide<ServerAccessPolicy>(policy);
    context.provide<UserEmailInfo?>((
      email: 'other@openci.org',
      emailVerified: true,
    ));
    final handler = emailAllowlistMiddleware()(
      (_) => fail('Rejected requests must not reach the handler'),
    );

    final response = await handler(context.context);

    expect(response.statusCode, HttpStatus.forbidden);
  });

  test('ignores a Cloud mode flag supplied in the query parameter', () async {
    context = TestRequestContext(path: '/teams?SERVER_ACCESS_MODE=cloud');
    context.provide<ServerAccessPolicy>(policy);
    context.provide<UserEmailInfo?>((
      email: 'other@openci.org',
      emailVerified: true,
    ));
    final handler = emailAllowlistMiddleware()(
      (_) => fail('Rejected requests must not reach the handler'),
    );

    final response = await handler(context.context);

    expect(response.statusCode, HttpStatus.forbidden);
  });

  test(
    'does not bypass the allowlist based on the server access mode',
    () async {
      context.provide<ServerAccessPolicy>(
        ServerAccessPolicy.fromEnvironment({'SERVER_ACCESS_MODE': 'cloud'}),
      );
      context.provide<UserEmailInfo?>((
        email: 'test@openci.org',
        emailVerified: true,
      ));
      final handler = emailAllowlistMiddleware()(
        (_) => fail('Rejected requests must not reach the handler'),
      );

      final response = await handler(context.context);

      expect(response.statusCode, HttpStatus.forbidden);
    },
  );
}
