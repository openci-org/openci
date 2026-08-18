import 'dart:io';

import 'package:sentry/sentry.dart';

Future<void> initializeSentry(String? sentryDsn) async {
  if (sentryDsn == null || sentryDsn.isEmpty) {
    stdout.write(
      'Sentry DSN is not configured. Skipping Sentry initialization.',
    );
    return;
  }
  await Sentry.init((options) {
    options.dsn = sentryDsn;
    options.tracesSampleRate = 1.0;
  });
}
