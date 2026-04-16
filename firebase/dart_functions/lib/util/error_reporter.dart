import 'package:dart_functions/util/logger.dart';
import 'package:sentry/sentry.dart';

Future<void> reportError(Object error, StackTrace stackTrace) async {
  logError(error.toString(), {'stackTrace': stackTrace.toString()});

  if (Sentry.isEnabled) {
    await Sentry.captureException(error, stackTrace: stackTrace);
  }
}
