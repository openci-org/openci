import 'dart:io';

import 'package:logging/logging.dart';
import 'package:openci_worker_cli/args.dart';
import 'package:openci_worker_cli/constants.dart';
import 'package:process_run/process_run.dart';
import 'package:sentry/sentry.dart';

final _log = Logger('Config');

typedef WorkerConfig = ({String email, String password, String projectId});

Future<WorkerConfig?> parseWorkerConfig(List<String> arguments) async {
  final results = argParser.parse(arguments);

  if (results.flag('help')) {
    printArgsUsage();
    return null;
  }

  if (results.flag('version')) {
    _log.info('openci_worker version: $version');
    return null;
  }

  if (results.flag('update')) {
    _log.info('Updating openci_worker...');
    final shell = Shell(verbose: true);
    await shell.run('dart pub global activate openci_worker_cli');
    _log.info('Updated successfully!');
    return null;
  }

  final email =
      (results['email'] as String?) ?? Platform.environment['OPENCI_EMAIL'];
  if (email == null || email.isEmpty) {
    _log.severe('--email or OPENCI_EMAIL environment variable is required.');
    printArgsUsage();
    return null;
  }

  final password =
      (results['password'] as String?) ??
      Platform.environment['OPENCI_PASSWORD'];
  if (password == null || password.isEmpty) {
    _log.severe(
      '--password or OPENCI_PASSWORD environment variable is required.',
    );
    printArgsUsage();
    return null;
  }

  final projectId =
      (results['project-id'] as String?) ??
      Platform.environment['OPENCI_PROJECT_ID'] ??
      'openci-b1b91';

  final sentryDsn =
      (results['sentry-dsn'] as String?) ?? Platform.environment['SENTRY_DSN'];
  if (sentryDsn != null && sentryDsn.isNotEmpty) {
    await Sentry.init((options) {
      options.dsn = sentryDsn;
      options.release = version;
    });
  }

  return (email: email, password: password, projectId: projectId);
}
