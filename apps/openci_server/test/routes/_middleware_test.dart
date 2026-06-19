import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:firebase_admin_sdk/auth.dart';
import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../routes/_middleware.dart';

class MockFirebaseApp extends Mock implements FirebaseApp {}

class MockAuth extends Mock implements Auth {}

class MockDecodedIdToken extends Mock implements DecodedIdToken {}

class MockRequestContext extends Mock implements RequestContext {}

class MockRequest extends Mock implements Request {}

void main() {
  setUpAll(() {
    registerFallbackValue(() => 'dummy');
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
      when(() => mockContext.provide<String?>(any())).thenReturn(mockContext);
    });

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
  });
}
