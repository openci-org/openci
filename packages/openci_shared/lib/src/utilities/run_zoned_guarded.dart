import 'dart:async';
import 'dart:io';

import 'package:sentry/sentry.dart';

Future<void> openCIRunZonedGuarded(
  Future<void> Function() body, {
  void Function(int) exitProcess = exit,
}) async => runZonedGuarded(body, (error, stackTrace) async {
  stderr.writeln('FATAL UNCAUGHT ERROR: $error');
  stderr.writeln(stackTrace);
  await Sentry.captureException(error, stackTrace: stackTrace);
  exitProcess(1);
});
