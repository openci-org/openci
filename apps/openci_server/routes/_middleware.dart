import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:openci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:sentry/sentry.dart';

final _db = AppDatabase();
final FirebaseApp _firebaseApp = FirebaseApp.initializeApp();

bool _sentryInitialized = false;

void _initSentry() {
  if (_sentryInitialized) return;
  final sentryDsn = Platform.environment['SENTRY_DSN_SERVER'];
  if (sentryDsn != null && sentryDsn.isNotEmpty) {
    Sentry.init((options) {
      options.dsn = sentryDsn;
      options.tracesSampleRate = 1.0;
      options.sendDefaultPii = true;
    });
    _sentryInitialized = true;
  }
}

Handler middleware(Handler handler) {
  return handler
      .use(sentryMiddleware())
      .use(databaseProvider(_db))
      .use(authProvider(_firebaseApp))
      .use(provider<FirebaseApp>((context) => _firebaseApp))
      .use(corsMiddleware())
      .use(requestLogger());
}

Middleware sentryMiddleware() {
  return (handler) {
    return (context) async {
      try {
        _initSentry();
        return await handler(context);
      } catch (exception, stackTrace) {
        if (exception.toString().contains('hijack')) {
          rethrow;
        }
        stderr.writeln('Unhandled exception: $exception\n$stackTrace');
        if (_sentryInitialized) {
          await Sentry.captureException(
            exception,
            stackTrace: stackTrace,
          );
        }
        return Response.json(
          statusCode: HttpStatus.internalServerError,
          body: {
            'success': false,
            'error': 'Internal server error',
          },
        );
      }
    };
  };
}

Middleware databaseProvider(AppDatabase db) {
  return provider<AppDatabase>((context) => db);
}

Middleware authProvider(FirebaseApp? firebaseApp, {bool allowTestUid = false}) {
  return (handler) {
    return (context) async {
      if (context.request.uri.path == '/') {
        return handler(context.provide<String?>(() => null));
      }

      Map<String, String> env;
      try {
        env = context.read<Map<String, String>>();
      } catch (_) {
        env = Platform.environment;
      }
      final internalApiKey = env['INTERNAL_API_KEY'];

      String? token;
      final authHeader = context.request.headers['authorization'] ??
          context.request.headers['Authorization'];
      if (authHeader != null && authHeader.startsWith('Bearer ')) {
        token = authHeader.substring(7);
      } else {
        token =
            context.request.uri.queryParameters['token'] ??
            context.request.uri.queryParameters['auth'];
      }

      if (token != null && token.isNotEmpty) {
        if (internalApiKey != null &&
            internalApiKey.isNotEmpty &&
            constantTimeCompareString(token, internalApiKey)) {
          return handler(
            context.provide<String?>(() => 'system-job-processor'),
          );
        }
      }

      if (firebaseApp == null) {
        if (token != null && token.isNotEmpty) {
          return handler(context.provide<String?>(() => 'test-uid'));
        }
        if (allowTestUid) {
          return handler(context.provide<String?>(() => 'test-uid'));
        }
        return handler(context.provide<String?>(() => null));
      }

      if (token == null || token.isEmpty) {
        return handler(context.provide<String?>(() => null));
      }
      try {
        final decodedToken = await firebaseApp.auth().verifyIdToken(
          token,
          checkRevoked: false,
        );
        return handler(context.provide<String?>(() => decodedToken.uid));
      } catch (e) {
        stderr.writeln('Token verification failed: $e');
        return handler(context.provide<String?>(() => null));
      }
    };
  };
}

Middleware corsMiddleware({Map<String, String>? environment}) {
  final env = environment ?? Platform.environment;
  final origins = env['ALLOWED_ORIGINS'] ?? '';
  final list = origins
      .split(',')
      .map((o) => o.trim().replaceAll(RegExp(r'/$'), ''))
      .where((o) => o.isNotEmpty)
      .toList();
  final allowedOrigins = {
    'https://dashboard.openci.org',
    ...list,
  };

  bool isAllowed(String origin) {
    final sanitized = origin.trim().replaceAll(RegExp(r'/$'), '');
    if (allowedOrigins.contains(sanitized)) {
      return true;
    }
    try {
      final uri = Uri.parse(sanitized);
      return uri.host == 'localhost' || uri.host == '127.0.0.1';
    } catch (_) {
      return false;
    }
  }

  return (handler) {
    return (context) async {
      final origin =
          context.request.headers['origin'] ??
          context.request.headers['Origin'];

      if (origin == null || !isAllowed(origin)) {
        return handler(context);
      }

      final corsHeaders = {
        'Access-Control-Allow-Origin': origin,
        'Access-Control-Allow-Methods':
            'GET, POST, PUT, DELETE, OPTIONS, PATCH',
        'Access-Control-Allow-Headers':
            'Origin, Content-Type, Accept, Authorization',
        'Access-Control-Allow-Credentials': 'true',
      };

      if (context.request.method == HttpMethod.options) {
        return Response(
          statusCode: HttpStatus.ok,
          body: '',
          headers: corsHeaders,
        );
      }

      final response = await handler(context);
      return response.copyWith(
        headers: {...response.headers, ...corsHeaders},
      );
    };
  };
}
