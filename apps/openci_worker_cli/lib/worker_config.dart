import 'dart:io';

import 'package:logging/logging.dart';
import 'package:openci_worker_cli/args.dart';
import 'package:openci_worker_cli/constants.dart';
import 'package:process_run/process_run.dart';
import 'package:sentry/sentry.dart';

final _log = Logger('Config');

typedef WorkerConfig = ({
  String email,
  String password,
  String projectId,
  String apiKey,
});

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

  final email = Platform.environment['OPENCI_EMAIL'];
  if (email == null || email.isEmpty) {
    _log.severe('OPENCI_EMAIL environment variable is required.');
    return null;
  }

  final password = Platform.environment['OPENCI_PASSWORD'];
  if (password == null || password.isEmpty) {
    _log.severe('OPENCI_PASSWORD environment variable is required.');
    return null;
  }

  final projectId = Platform.environment['OPENCI_PROJECT_ID'];
  if (projectId == null || projectId.isEmpty) {
    _log.severe('OPENCI_PROJECT_ID environment variable is required.');
    return null;
  }

  final apiKey = Platform.environment['OPENCI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    _log.severe('OPENCI_API_KEY environment variable is required.');
    return null;
  }

  final sentryDsn = Platform.environment['SENTRY_DSN'];
  if (sentryDsn != null && sentryDsn.isNotEmpty) {
    await Sentry.init((options) {
      options.dsn = sentryDsn;
      options.release = version;
    });
  }

  return (
    email: email,
    password: password,
    projectId: projectId,
    apiKey: apiKey,
  );
}
