import 'package:sentry/sentry.dart';

Future<void> initializeSentry(String? sentryDsn) async {
  if (sentryDsn != null && sentryDsn.isNotEmpty) {
    await Sentry.init((options) {
      options.dsn = sentryDsn;
      options.tracesSampleRate = 1.0;
    });
  }
}
