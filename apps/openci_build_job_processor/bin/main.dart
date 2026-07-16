import 'dart:async';
import 'dart:io';

import 'package:openci_build_job_processor/openci_build_job_processor.dart';
import 'package:sentry/sentry.dart';

Future<void> main() async {
  await runZonedGuarded(
    () async {
      final config = ProcessorConfig.fromEnvironment();

      await initializeSentry(config.sentryDsn);

      final jobPoller = JobPoller(config: config);
      await jobPoller.startPolling(config.runsOnPattern);
    },
    (error, stackTrace) async {
      stderr.writeln('FATAL UNCAUGHT ERROR: $error');
      stderr.writeln(stackTrace);
      await Sentry.captureException(error, stackTrace: stackTrace);
      exit(1);
    },
  );
}
