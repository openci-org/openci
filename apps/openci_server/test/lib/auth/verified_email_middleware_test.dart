import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:openci_server/auth/user_email_info.dart';
import 'package:openci_server/auth/verified_email_middleware.dart';
import 'package:test/test.dart';

void main() {
  group('verified email', () {
    late TestRequestContext context;

    setUp(() {
      context = TestRequestContext(path: '/teams');
      context.provide<UserEmailInfo?>((
        email: 'test@openci.org',
        emailVerified: true,
      ));
    });

    test('calls the handler once', () async {
      var calls = 0;
      final handler = verifiedEmailMiddleware()((_) {
        calls++;
        return Response();
      });

      await handler(context.context);

      expect(calls, 1);
    });

    test('passes the original context to the handler', () async {
      RequestContext? receivedContext;
      final handler = verifiedEmailMiddleware()((actualContext) {
        receivedContext = actualContext;
        return Response();
      });

      await handler(context.context);

      expect(receivedContext, same(context.context));
    });

    test('returns the handler response unchanged', () async {
      final expected = Response(
        statusCode: HttpStatus.accepted,
        body: 'accepted',
      );
      final handler = verifiedEmailMiddleware()((_) => expected);

      expect(await handler(context.context), same(expected));
    });
  });

  test('rejects unverified email', () async {
    final context = TestRequestContext(path: '/teams');
    context.provide<UserEmailInfo?>((
      email: 'test@openci.org',
      emailVerified: false,
    ));
    final handler = verifiedEmailMiddleware()(
      (_) => fail('Rejected requests must not reach the handler'),
    );

    final response = await handler(context.context);

    expect(response.statusCode, HttpStatus.forbidden);
    expect(await response.json(), {
      'success': false,
      'error': 'Email verification required',
      'code': 'email_verification_required',
    });
  });

  test('rejects missing verification claim', () async {
    final context = TestRequestContext(path: '/teams');
    context.provide<UserEmailInfo?>((
      email: 'test@openci.org',
      emailVerified: null,
    ));
    final handler = verifiedEmailMiddleware()(
      (_) => fail('Rejected requests must not reach the handler'),
    );

    final response = await handler(context.context);

    expect(response.statusCode, HttpStatus.forbidden);
    expect(await response.json(), {
      'success': false,
      'error': 'Email verification required',
      'code': 'email_verification_required',
    });
  });

  test('rejects missing identity information', () async {
    final context = TestRequestContext(path: '/teams');
    context.provide<UserEmailInfo?>(null);
    final handler = verifiedEmailMiddleware()(
      (_) => fail('Rejected requests must not reach the handler'),
    );

    final response = await handler(context.context);

    expect(response.statusCode, HttpStatus.forbidden);
    expect(await response.json(), {
      'success': false,
      'error': 'Email verification required',
      'code': 'email_verification_required',
    });
  });

  test('ignores email_verified supplied in the query parameter', () async {
    final context = TestRequestContext(path: '/teams?email_verified=true');
    context.provide<UserEmailInfo?>((
      email: 'test@openci.org',
      emailVerified: false,
    ));
    final handler = verifiedEmailMiddleware()((_) => Response());

    final response = await handler(context.context);

    expect(response.statusCode, HttpStatus.forbidden);
  });

  test('ignores email_verified supplied in the header', () async {
    final context = TestRequestContext(
      path: '/teams',
      headers: {'email_verified': 'true'},
    );
    context.provide<UserEmailInfo?>((
      email: 'test@openci.org',
      emailVerified: false,
    ));
    final handler = verifiedEmailMiddleware()((_) => Response());

    final response = await handler(context.context);

    expect(response.statusCode, HttpStatus.forbidden);
  });

  test('ignores email_verified supplied in the body', () async {
    final context = TestRequestContext(
      path: '/teams',
      method: HttpMethod.post,
      body: '{"email_verified":true}',
    );
    context.provide<UserEmailInfo?>((
      email: 'test@openci.org',
      emailVerified: false,
    ));
    final handler = verifiedEmailMiddleware()((_) => Response());

    final response = await handler(context.context);

    expect(response.statusCode, HttpStatus.forbidden);
  });
}
