import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:sentry/sentry.dart';

Future<Response> handleRouteException(
  Object exception,
  StackTrace stackTrace, {
  String? logMessage,
}) async {
  stderr.writeln('${logMessage ?? 'Route error'}: $exception\n$stackTrace');
  try {
    if (Sentry.isEnabled) {
      await Sentry.captureException(exception, stackTrace: stackTrace);
    }
  } catch (sentryErr) {
    stderr.writeln('Failed to send exception to Sentry: $sentryErr');
  }
  return Response.json(
    statusCode: HttpStatus.internalServerError,
    body: {
      'success': false,
      'error': 'Internal server error',
    },
  );
}
