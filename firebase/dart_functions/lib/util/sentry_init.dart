import 'package:sentry/sentry.dart';

import '../secret_manager.dart';

Future<void> initSentry() async {
  final dsn = await accessSecret('SENTRY_DSN');

  await Sentry.init((options) {
    options.dsn = dsn;
    options.environment = const bool.fromEnvironment('dart.vm.product')
        ? 'production'
        : 'development';
    options.tracesSampleRate = 1.0;
  });
}
