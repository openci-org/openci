import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:firebase_admin_sdk/auth.dart';
import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:genuineci_server/auth/internal_api_key_validator.dart';
import 'package:genuineci_server/auth/user_email_info.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:genuineci_server/database.dart';
import 'package:test/test.dart';

import '../../routes/_middleware.dart';
import '../../routes/internal/build_jobs.dart' as build_jobs;
import '../../routes/internal/seed/index.dart' as seed;
import '../../routes/internal/seed/jobs.dart' as seed_jobs;
import '../../routes/internal/seed/teams.dart' as seed_teams;

class MockFirebaseApp extends Mock implements FirebaseApp {}

class MockAuth extends Mock implements Auth {}

class MockDecodedIdToken extends Mock implements DecodedIdToken {}

class MockRequestContext extends Mock implements RequestContext {}

class MockRequest extends Mock implements Request {}

void main() {
  setUpAll(() {
    registerFallbackValue(() => 'dummy');
    registerFallbackValue(() => null);
  });

  test(
    'databaseProvider makes the same database available downstream',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final context = MockRequestContext();
      registerFallbackValue(() => db);
      when(() => context.provide<AppDatabase>(any())).thenAnswer((invocation) {
        final create =
            invocation.positionalArguments.single as AppDatabase Function();
        expect(create(), same(db));
        return context;
      });
      final handler = databaseProvider(db)(
        (_) => Response(statusCode: 201, body: 'created'),
      );
      final response = await handler(context);
      expect(response.statusCode, 201);
      expect(await response.body(), 'created');
    },
  );

  group('sentryMiddleware', () {
    test('preserves a successful downstream response', () async {
      final context = TestRequestContext(path: '/');
      final expected = Response(statusCode: 202, body: 'accepted');
      final handler = sentryMiddleware()((_) => expected);
      expect(await handler(context.context), same(expected));
    });

    test(
      'returns a generic error without exposing exception details',
      () async {
        final context = TestRequestContext(path: '/');
        final handler = sentryMiddleware()((_) async {
          throw StateError('private exception detail');
        });
        final response = await handler(context.context);
        expect(response.statusCode, HttpStatus.internalServerError);
        expect(await response.json(), {
          'success': false,
          'error': 'Internal server error',
        });
      },
    );

    test('propagates hijack exceptions for streaming responses', () async {
      final context = TestRequestContext(path: '/');
      final error = StateError('request hijack');
      final handler = sentryMiddleware()((_) async => throw error);
      await expectLater(handler(context.context), throwsA(same(error)));
    });
  });

  group('corsMiddleware', () {
    late MockRequestContext mockContext;
    late MockRequest mockRequest;

    setUp(() {
      mockContext = MockRequestContext();
      mockRequest = MockRequest();
      when(() => mockContext.request).thenReturn(mockRequest);
    });

    test(
      'OPTIONS request returns 200 with CORS headers for allowed origin',
      () async {
        final middleware = corsMiddleware(
          environment: {'ALLOWED_ORIGINS': 'https://custom.example.com'},
        );
        final handler = middleware((context) => Response());

        when(() => mockRequest.method).thenReturn(HttpMethod.options);
        when(() => mockRequest.headers).thenReturn({
          'Origin': 'https://custom.example.com',
        });

        final response = await handler(mockContext);
        expect(response.statusCode, equals(HttpStatus.ok));
        expect(
          response.headers['Access-Control-Allow-Origin'],
          equals('https://custom.example.com'),
        );
        expect(
          response.headers['Access-Control-Allow-Credentials'],
          equals('true'),
        );
      },
    );

    test('GET request adds CORS headers for allowed origin', () async {
      final middleware = corsMiddleware(
        environment: {'ALLOWED_ORIGINS': 'https://custom.example.com'},
      );
      final handler = middleware((context) => Response(body: 'ok'));

      when(() => mockRequest.method).thenReturn(HttpMethod.get);
      when(() => mockRequest.headers).thenReturn({
        'Origin': 'https://custom.example.com',
      });

      final response = await handler(mockContext);
      expect(response.statusCode, equals(HttpStatus.ok));
      expect(
        response.headers['Access-Control-Allow-Origin'],
        equals('https://custom.example.com'),
      );
    });

    test(
      'GET request does not add CORS headers for disallowed origin',
      () async {
        final middleware = corsMiddleware(
          environment: {'ALLOWED_ORIGINS': 'https://custom.example.com'},
        );
        final handler = middleware((context) => Response(body: 'ok'));

        when(() => mockRequest.method).thenReturn(HttpMethod.get);
        when(() => mockRequest.headers).thenReturn({
          'Origin': 'https://evil.com',
        });

        final response = await handler(mockContext);
        expect(response.statusCode, equals(HttpStatus.ok));
        expect(response.headers['Access-Control-Allow-Origin'], isNull);
      },
    );
  });

  group('authProvider', () {
    late MockRequestContext mockContext;
    late MockRequest mockRequest;
    late MockFirebaseApp mockFirebaseApp;
    late MockAuth mockAuth;
    late MockDecodedIdToken mockToken;

    setUp(() {
      mockContext = MockRequestContext();
      mockRequest = MockRequest();
      mockFirebaseApp = MockFirebaseApp();
      mockAuth = MockAuth();
      mockToken = MockDecodedIdToken();

      when(() => mockContext.request).thenReturn(mockRequest);
      when(() => mockContext.read<InternalApiKeyValidator>()).thenReturn(
        const InternalApiKeyValidator.forTesting(environment: {}),
      );
      when(() => mockRequest.headers).thenReturn({});
      when(() => mockContext.provide<String?>(any())).thenReturn(mockContext);
      when(
        () => mockContext.provide<UserEmailInfo?>(any()),
      ).thenReturn(mockContext);
    });

    Future<Object?> readAuthContext({
      String path = '/teams',
      Map<String, String> headers = const {},
    }) async {
      final handler =
          authProvider(mockFirebaseApp)((context) {
            final info = context.read<UserEmailInfo?>();
            return Response.json(
              body: {
                'uid': context.read<String?>(),
                'emailInfo': info == null
                    ? null
                    : {
                        'email': info.email,
                        'emailVerified': info.emailVerified,
                      },
              },
            );
          }).use(
            provider<InternalApiKeyValidator>(
              (_) => const InternalApiKeyValidator.forTesting(
                environment: {'INTERNAL_API_KEY': 'test-internal-key'},
              ),
            ),
          );
      final server = await serve(handler, InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final uri = Uri(
        scheme: 'http',
        host: server.address.address,
        port: server.port,
      ).resolve(path);
      final response = await http.get(uri, headers: headers);
      expect(response.statusCode, HttpStatus.ok);
      return jsonDecode(response.body);
    }

    for (final info in <UserEmailInfo>[
      (email: 'Alice@Example.com', emailVerified: true),
      (email: 'alice@example.com', emailVerified: false),
      (email: 'alice@example.com', emailVerified: null),
      (email: null, emailVerified: null),
    ]) {
      for (final (path, headers) in [
        (
          '/teams?email=spoof@example.com&emailVerified=true',
          {
            'Authorization': 'Bearer valid-token',
            'email': 'spoof@example.com',
            'emailVerified': 'true',
          },
        ),
        ('/teams?token=valid-token', <String, String>{}),
        ('/teams?auth=valid-token', <String, String>{}),
      ]) {
        test('passes UID and email information $info via $path', () async {
          when(() => mockFirebaseApp.auth()).thenReturn(mockAuth);
          when(
            () => mockAuth.verifyIdToken('valid-token', checkRevoked: false),
          ).thenAnswer((_) async => mockToken);
          when(() => mockToken.uid).thenReturn('user-1');
          when(() => mockToken.email).thenReturn(info.email);
          when(() => mockToken.emailVerified).thenReturn(info.emailVerified);

          expect(await readAuthContext(path: path, headers: headers), {
            'uid': 'user-1',
            'emailInfo': {
              'email': info.email,
              'emailVerified': info.emailVerified,
            },
          });
          verify(
            () => mockAuth.verifyIdToken('valid-token', checkRevoked: false),
          ).called(1);
        });
      }
    }

    for (final token in [null, '', 'rejected-token']) {
      test('provides no email information for credential $token', () async {
        when(() => mockFirebaseApp.auth()).thenReturn(mockAuth);
        when(
          () => mockAuth.verifyIdToken('rejected-token', checkRevoked: false),
        ).thenThrow(Exception('Token invalid'));

        expect(
          await readAuthContext(
            path: '/teams?email=spoof@example.com&emailVerified=true',
            headers: {
              if (token != null) 'Authorization': 'Bearer $token',
              'email': 'spoof@example.com',
              'emailVerified': 'true',
            },
          ),
          {'uid': null, 'emailInfo': null},
        );
      });
    }

    for (final (name, path, headers) in [
      (
        'Bearer header over query credentials',
        '/teams?token=wrong-key&auth=wrong-key',
        {'Authorization': 'Bearer test-internal-key'},
      ),
      (
        'token query parameter over auth',
        '/teams?token=test-internal-key&auth=wrong-key',
        <String, String>{},
      ),
      (
        'auth query parameter',
        '/teams?auth=test-internal-key',
        <String, String>{},
      ),
    ]) {
      test('authenticates the internal key from $name', () async {
        expect(await readAuthContext(path: path, headers: headers), {
          'uid': null,
          'emailInfo': null,
        });
        verifyZeroInteractions(mockFirebaseApp);
      });
    }

    test(
      'treats the former internal UID as an ordinary Firebase identity',
      () async {
        when(() => mockFirebaseApp.auth()).thenReturn(mockAuth);
        when(
          () => mockAuth.verifyIdToken('valid-token', checkRevoked: false),
        ).thenAnswer((_) async => mockToken);
        when(() => mockToken.uid).thenReturn('system-job-processor');
        when(() => mockToken.email).thenReturn('alice@example.com');
        when(() => mockToken.emailVerified).thenReturn(true);

        expect(
          await readAuthContext(
            headers: {'Authorization': 'Bearer valid-token'},
          ),
          {
            'uid': 'system-job-processor',
            'emailInfo': {'email': 'alice@example.com', 'emailVerified': true},
          },
        );
        verify(
          () => mockAuth.verifyIdToken('valid-token', checkRevoked: false),
        ).called(1);
      },
    );

    test(
      'keeps the public root anonymous without verifying credentials',
      () async {
        expect(
          await readAuthContext(
            path: '/',
            headers: {'Authorization': 'Bearer rejected-token'},
          ),
          {'uid': null, 'emailInfo': null},
        );
        verifyZeroInteractions(mockFirebaseApp);
      },
    );

    test(
      'prefers a Firebase Bearer token over an internal query key',
      () async {
        when(() => mockFirebaseApp.auth()).thenReturn(mockAuth);
        when(
          () => mockAuth.verifyIdToken('valid-token', checkRevoked: false),
        ).thenAnswer((_) async => mockToken);
        when(() => mockToken.uid).thenReturn('user-1');
        when(() => mockToken.email).thenReturn('alice@example.com');
        when(() => mockToken.emailVerified).thenReturn(true);

        expect(
          await readAuthContext(
            path: '/teams?token=test-internal-key&auth=test-internal-key',
            headers: {'Authorization': 'Bearer valid-token'},
          ),
          {
            'uid': 'user-1',
            'emailInfo': {'email': 'alice@example.com', 'emailVerified': true},
          },
        );
        verify(
          () => mockAuth.verifyIdToken('valid-token', checkRevoked: false),
        ).called(1);
      },
    );

    test(
      'does not fall back to auth when the token query is invalid',
      () async {
        when(() => mockFirebaseApp.auth()).thenReturn(mockAuth);
        when(
          () => mockAuth.verifyIdToken('rejected-token', checkRevoked: false),
        ).thenThrow(Exception('Token invalid'));

        expect(
          await readAuthContext(
            path: '/teams?token=rejected-token&auth=test-internal-key',
          ),
          {'uid': null, 'emailInfo': null},
        );
        verify(
          () => mockAuth.verifyIdToken('rejected-token', checkRevoked: false),
        ).called(1);
      },
    );

    test(
      'provides test-uid when firebaseApp is null and allowTestUid is true',
      () async {
        final middleware = authProvider(null, allowTestUid: true);

        when(
          () => mockRequest.uri,
        ).thenReturn(Uri.parse('http://localhost/teams'));

        var handlerCalled = false;
        final handler = middleware((context) {
          handlerCalled = true;
          return Response();
        });

        await handler(mockContext);
        expect(handlerCalled, isTrue);

        final captured =
            verify(
                  () => mockContext.provide<String?>(captureAny()),
                ).captured.single
                as String? Function();
        expect(captured(), equals('test-uid'));
      },
    );

    test(
      'provides null when firebaseApp is null and allowTestUid is false',
      () async {
        final middleware = authProvider(null, allowTestUid: false);

        when(
          () => mockRequest.uri,
        ).thenReturn(Uri.parse('http://localhost/teams'));

        var handlerCalled = false;
        final handler = middleware((context) {
          handlerCalled = true;
          return Response();
        });

        await handler(mockContext);
        expect(handlerCalled, isTrue);

        final captured =
            verify(
                  () => mockContext.provide<String?>(captureAny()),
                ).captured.single
                as String? Function();
        expect(captured(), isNull);
      },
    );

    test('provides null when path is root (/)', () async {
      final middleware = authProvider(null);

      when(() => mockRequest.uri).thenReturn(Uri.parse('http://localhost/'));

      var handlerCalled = false;
      final handler = middleware((context) {
        handlerCalled = true;
        return Response();
      });

      await handler(mockContext);
      expect(handlerCalled, isTrue);

      final captured =
          verify(
                () => mockContext.provide<String?>(captureAny()),
              ).captured.single
              as String? Function();
      expect(captured(), isNull);
    });

    test('provides uid when valid token is provided via FirebaseApp', () async {
      when(() => mockFirebaseApp.auth()).thenReturn(mockAuth);
      when(
        () => mockAuth.verifyIdToken(
          any(),
          checkRevoked: any(named: 'checkRevoked'),
        ),
      ).thenAnswer((_) async => mockToken);
      when(() => mockToken.uid).thenReturn('user-firebase-123');

      final middleware = authProvider(mockFirebaseApp);

      when(
        () => mockRequest.uri,
      ).thenReturn(Uri.parse('http://localhost/teams'));
      when(() => mockRequest.headers).thenReturn({
        'Authorization': 'Bearer valid-token',
      });

      var handlerCalled = false;
      final handler = middleware((context) {
        handlerCalled = true;
        return Response();
      });

      await handler(mockContext);
      expect(handlerCalled, isTrue);

      final captured =
          verify(
                () => mockContext.provide<String?>(captureAny()),
              ).captured.single
              as String? Function();
      expect(captured(), equals('user-firebase-123'));
    });

    test('does not retry an authenticated handler when it throws', () async {
      when(() => mockFirebaseApp.auth()).thenReturn(mockAuth);
      when(
        () => mockAuth.verifyIdToken('valid-token', checkRevoked: false),
      ).thenAnswer((_) async => mockToken);
      when(() => mockToken.uid).thenReturn('user-1');
      when(
        () => mockRequest.uri,
      ).thenReturn(Uri.parse('http://localhost/teams'));
      when(() => mockRequest.headers).thenReturn({
        'authorization': 'Bearer valid-token',
      });
      final error = StateError('downstream request failed');
      var handlerCalls = 0;
      final handler = authProvider(mockFirebaseApp)((_) async {
        handlerCalls++;
        throw error;
      });

      await expectLater(handler(mockContext), throwsA(same(error)));
      expect(handlerCalls, 1);
      final captured =
          verify(
                () => mockContext.provide<String?>(captureAny()),
              ).captured.single
              as String? Function();
      expect(captured(), 'user-1');
    });

    test(
      'provides null when invalid token is provided via FirebaseApp',
      () async {
        when(() => mockFirebaseApp.auth()).thenReturn(mockAuth);
        when(
          () => mockAuth.verifyIdToken(
            any(),
            checkRevoked: any(named: 'checkRevoked'),
          ),
        ).thenThrow(Exception('Token invalid'));

        final middleware = authProvider(mockFirebaseApp);

        when(
          () => mockRequest.uri,
        ).thenReturn(Uri.parse('http://localhost/teams'));
        when(() => mockRequest.headers).thenReturn({
          'Authorization': 'Bearer invalid-token',
        });

        var handlerCalled = false;
        final handler = middleware((context) {
          handlerCalled = true;
          return Response();
        });

        await handler(mockContext);
        expect(handlerCalled, isTrue);

        final captured =
            verify(
                  () => mockContext.provide<String?>(captureAny()),
                ).captured.single
                as String? Function();
        expect(captured(), isNull);
      },
    );

    test('provides null when Authorization header is missing', () async {
      final middleware = authProvider(mockFirebaseApp);

      when(
        () => mockRequest.uri,
      ).thenReturn(Uri.parse('http://localhost/teams'));
      when(() => mockRequest.headers).thenReturn({});

      var handlerCalled = false;
      final handler = middleware((context) {
        handlerCalled = true;
        return Response();
      });

      await handler(mockContext);
      expect(handlerCalled, isTrue);

      final captured =
          verify(
                () => mockContext.provide<String?>(captureAny()),
              ).captured.single
              as String? Function();
      expect(captured(), isNull);
    });

    test(
      'provides no UID when Authorization header matches INTERNAL_API_KEY',
      () async {
        final middleware = authProvider(null);

        when(
          () => mockRequest.uri,
        ).thenReturn(Uri.parse('http://localhost/teams'));
        when(() => mockRequest.headers).thenReturn({
          'authorization': 'Bearer my-internal-key',
        });
        when(
          () => mockContext.read<InternalApiKeyValidator>(),
        ).thenReturn(
          const InternalApiKeyValidator.forTesting(
            environment: {'INTERNAL_API_KEY': 'my-internal-key'},
          ),
        );

        var handlerCalled = false;
        final handler = middleware((context) {
          handlerCalled = true;
          return Response();
        });

        await handler(mockContext);
        expect(handlerCalled, isTrue);

        final captured =
            verify(
                  () => mockContext.provide<String?>(captureAny()),
                ).captured.single
                as String? Function();
        expect(captured(), isNull);
      },
    );

    test(
      'provides null when Authorization header does not match INTERNAL_API_KEY',
      () async {
        final middleware = authProvider(null);

        when(
          () => mockRequest.uri,
        ).thenReturn(Uri.parse('http://localhost/teams'));
        when(() => mockRequest.headers).thenReturn({
          'authorization': 'Bearer wrong-internal-key',
        });
        when(
          () => mockContext.read<InternalApiKeyValidator>(),
        ).thenReturn(
          const InternalApiKeyValidator.forTesting(
            environment: {'INTERNAL_API_KEY': 'my-internal-key'},
          ),
        );

        var handlerCalled = false;
        final handler = middleware((context) {
          handlerCalled = true;
          return Response();
        });

        await handler(mockContext);
        expect(handlerCalled, isTrue);

        final captured =
            verify(
                  () => mockContext.provide<String?>(captureAny()),
                ).captured.single
                as String? Function();
        expect(captured(), isNull);
      },
    );
  });

  group('internalRoutesMiddleware', () {
    for (final (path, method, route) in <(String, HttpMethod, Handler)>[
      ('/internal/build_jobs', HttpMethod.delete, build_jobs.onRequest),
      ('/internal/seed', HttpMethod.post, seed.onRequest),
      ('/internal/seed/teams', HttpMethod.post, seed_teams.onRequest),
      ('/internal/seed/jobs', HttpMethod.post, seed_jobs.onRequest),
      ('/internal/seed/jobs', HttpMethod.delete, seed_jobs.onRequest),
    ]) {
      test(
        'blocks ${method.name} $path before accessing the database',
        () async {
          final context = TestRequestContext(path: path, method: method);
          final handler = internalRoutesMiddleware(environment: const {})(
            route,
          );

          final response = await handler(context.context);

          expect(response.statusCode, HttpStatus.notFound);
        },
      );
    }

    for (final value in [null, '', 'false', 'TRUE', '1', ' true ', 'invalid']) {
      test(
        'disables internal routes when ENABLE_INTERNAL_API is $value',
        () async {
          final context = TestRequestContext(path: '/internal/seed');
          final handler = internalRoutesMiddleware(
            environment: {'ENABLE_INTERNAL_API': ?value},
          )((_) => throw StateError('Disabled route must not run'));

          final response = await handler(context.context);

          expect(response.statusCode, HttpStatus.notFound);
          expect(await response.body(), isEmpty);
        },
      );
    }

    for (final method in HttpMethod.values) {
      test('blocks ${method.name} even with an internal API key', () async {
        final context = TestRequestContext(
          path: '/internal/seed/jobs',
          method: method,
          headers: {'Authorization': 'Bearer test-internal-key'},
        );
        final handler = internalRoutesMiddleware(
          environment: const {'INTERNAL_API_KEY': 'test-internal-key'},
        )((_) => throw StateError('Disabled route must not run'));

        final response = await handler(context.context);

        expect(response.statusCode, HttpStatus.notFound);
      });
    }

    test('covers the internal root and future nested routes', () async {
      final handler = internalRoutesMiddleware(environment: const {})(
        (_) => throw StateError('Disabled route must not run'),
      );

      for (final path in ['/internal', '/internal/', '/internal/new/nested']) {
        final context = TestRequestContext(path: path);
        expect(
          (await handler(context.context)).statusCode,
          HttpStatus.notFound,
          reason: path,
        );
      }
    });

    test(
      'preserves the handler and response when explicitly enabled',
      () async {
        final context = TestRequestContext(
          path: '/internal/seed',
          method: HttpMethod.post,
        ).context;
        final expected = Response(
          statusCode: HttpStatus.created,
          body: 'seeded',
        );
        var calls = 0;
        final handler =
            internalRoutesMiddleware(
              environment: const {'ENABLE_INTERNAL_API': 'true'},
            )((actualContext) {
              calls++;
              expect(actualContext, same(context));
              return expected;
            });

        expect(await handler(context), same(expected));
        expect(calls, 1);
      },
    );

    test('preserves routes outside the internal path segment', () async {
      final expected = Response(statusCode: HttpStatus.accepted);
      final handler = internalRoutesMiddleware(environment: const {})(
        (_) => expected,
      );

      for (final path in [
        '/',
        '/webhook',
        '/webhooks/claim',
        '/worker/jobs/claim',
        '/teams',
        '/internal-other',
      ]) {
        final context = TestRequestContext(path: path);
        expect(await handler(context.context), same(expected), reason: path);
      }
    });

    test(
      'rejects disabled routes before CORS can answer a preflight',
      () async {
        final context = TestRequestContext(
          path: '/internal/seed',
          method: HttpMethod.options,
          headers: {'Origin': 'https://dashboard.openci.org'},
        );
        Handler handler = (_) =>
            throw StateError('Disabled route must not run');
        handler = handler
            .use(corsMiddleware(environment: const {}))
            .use(internalRoutesMiddleware(environment: const {}));

        final response = await handler(context.context);

        expect(response.statusCode, HttpStatus.notFound);
        expect(
          response.headers,
          isNot(contains('Access-Control-Allow-Origin')),
        );
      },
    );
  });
}
