import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/settings/storage_settings.dart';
import 'package:openci_server/storage.dart';
import 'package:openci_server/webhook_task/webhook_task_worker.dart';
import 'package:sentry/sentry.dart';

final _db = () {
  final db = AppDatabase();
  startWebhookTaskWorker(db);
  return db;
}();
final FirebaseApp _firebaseApp = FirebaseApp.initializeApp();

final _storage = () {
  final settings = loadStorageSettings();
  final storage = StorageManager(settings);
  storage.initialize().catchError((Object e) {
    stderr.writeln('StorageManager initialization failed: $e');
  });
  return storage;
}();

bool _sentryInitialized = false;

void _initSentry() {
  if (_sentryInitialized) return;
  final sentryDsn = Platform.environment['SENTRY_DSN'];
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
      .use(storageProvider(_storage))
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

Middleware storageProvider(StorageManager storage) {
  return provider<StorageManager>((context) => storage);
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

      final authHeader = context.request.headers['Authorization'];
      if (authHeader != null && authHeader.startsWith('Bearer ')) {
        final token = authHeader.substring(7);
        if (internalApiKey != null &&
            internalApiKey.isNotEmpty &&
            token == internalApiKey) {
          return handler(
            context.provide<String?>(() => 'system-job-processor'),
          );
        }
      }

      if (firebaseApp == null && allowTestUid) {
        return handler(context.provide<String?>(() => 'test-uid'));
      }
      if (firebaseApp == null) {
        return handler(context.provide<String?>(() => null));
      }

      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return handler(context.provide<String?>(() => null));
      }

      final token = authHeader.substring(7);
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
