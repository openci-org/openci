import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:openci_server/auth/internal_api_key_validator.dart';
import 'package:openci_server/auth/server_access_policy_provider.dart';
import 'package:openci_server/auth/user_email_info.dart';
import 'package:openci_server/database.dart';
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
  final accessPolicyMiddleware = serverAccessPolicyProvider();
  return handler
      .use(sentryMiddleware())
      .use(databaseProvider(_db))
      .use(authProvider(_firebaseApp))
      .use(
        provider<InternalApiKeyValidator>(
          (_) => const InternalApiKeyValidator(),
        ),
      )
      .use(provider<FirebaseApp>((context) => _firebaseApp))
      .use(accessPolicyMiddleware)
      .use(corsMiddleware())
      .use(internalRoutesMiddleware())
      .use(requestLogger());
}

Middleware internalRoutesMiddleware({Map<String, String>? environment}) {
  final env = environment ?? Platform.environment;
  final enabled = env['ENABLE_INTERNAL_API'] == 'true';

  return (handler) {
    return (context) {
      final segments = context.request.uri.pathSegments;
      if (!enabled && segments.isNotEmpty && segments.first == 'internal') {
        return Response(statusCode: HttpStatus.notFound);
      }
      return handler(context);
    };
  };
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
    return (requestContext) async {
      final context = requestContext.provide<UserEmailInfo?>(() => null);
      if (context.request.uri.path == '/') {
        return handler(context.provide<String?>(() => null));
      }

      final validator = context.read<InternalApiKeyValidator>();
      if (validator.isValid(context)) {
        return handler(context.provide<String?>(() => null));
      }

      String? token;
      final authHeader =
          context.request.headers['authorization'] ??
          context.request.headers['Authorization'];
      if (authHeader != null && authHeader.startsWith('Bearer ')) {
        token = authHeader.substring(7);
      } else {
        token =
            context.request.uri.queryParameters['token'] ??
            context.request.uri.queryParameters['auth'];
      }

      if (firebaseApp == null) {
        if (allowTestUid) {
          return handler(context.provide<String?>(() => 'test-uid'));
        }
        return handler(context.provide<String?>(() => null));
      }

      if (token == null || token.isEmpty) {
        return handler(context.provide<String?>(() => null));
      }
      final String uid;
      final UserEmailInfo emailInfo;
      try {
        final decodedToken = await firebaseApp.auth().verifyIdToken(
          token,
          checkRevoked: false,
        );
        uid = decodedToken.uid;
        emailInfo = (
          email: decodedToken.email,
          emailVerified: decodedToken.emailVerified,
        );
      } catch (e) {
        stderr.writeln('Token verification failed: $e');
        return handler(context.provide<String?>(() => null));
      }
      return handler(
        context
            .provide<String?>(() => uid)
            .provide<UserEmailInfo?>(() => emailInfo),
      );
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
