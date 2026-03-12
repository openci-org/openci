import 'dart:convert';
import 'dart:io';

import 'package:openci_worker_cli/args.dart';
import 'package:openci_worker_cli/constants.dart';
import 'package:process_run/process_run.dart';
import 'package:sentry/sentry.dart';

typedef WorkerConfig = ({
  String serviceAccountPath,
  String workerId,
  String projectId,
});

Future<WorkerConfig?> parseWorkerConfig(List<String> arguments) async {
  final results = argParser.parse(arguments);

  if (results.flag('help')) {
    printArgsUsage();
    return null;
  }

  if (results.flag('version')) {
    print('openci-worker version: $version');
    return null;
  }

  if (results.flag('update')) {
    print('Updating openci-worker...');
    final shell = Shell(verbose: true);
    await shell.run('brew update');
    await shell.run('brew upgrade openci-worker');
    print('Updated successfully!');
    return null;
  }

  final serviceAccountPath = results['service-account'] as String?;
  if (serviceAccountPath == null) {
    print('Error: --service-account is required.');
    printArgsUsage();
    return null;
  }

  final workerId = results['worker-id'] as String?;
  if (workerId == null) {
    print('Error: --worker-id is required.');
    printArgsUsage();
    return null;
  }

  final serviceAccountFile = File(serviceAccountPath);
  if (!serviceAccountFile.existsSync()) {
    print('Error: Service account file not found: $serviceAccountPath');
    return null;
  }

  final serviceAccountJson =
      jsonDecode(serviceAccountFile.readAsStringSync()) as Map<String, dynamic>;
  final projectId = serviceAccountJson['project_id'] as String?;
  if (projectId == null) {
    print('Error: project_id not found in service account file.');
    return null;
  }

  if (projectId.isEmpty) {
    print('Error: project_id is empty in service account file.');
    return null;
  }

  final sentryDsn = results['sentry-dsn'] as String?;
  if (sentryDsn != null && sentryDsn.isNotEmpty) {
    await Sentry.init((options) {
      options.dsn = sentryDsn;
      options.release = version;
    });
  }

  return (
    serviceAccountPath: serviceAccountPath,
    workerId: workerId,
    projectId: projectId,
  );
}
