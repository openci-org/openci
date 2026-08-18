import 'dart:async';
import 'dart:io';

import 'package:sentry/sentry.dart';

Future<void> genuineCiRunZonedGuarded(Future<void> Function() body) async =>
    runZonedGuarded(body, (error, stackTrace) async {
      stderr.writeln('FATAL UNCAUGHT ERROR: $error');
      stderr.writeln(stackTrace);
      await Sentry.captureException(error, stackTrace: stackTrace);
      exit(1);
    });
