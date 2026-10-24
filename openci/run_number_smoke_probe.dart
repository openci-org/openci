import 'dart:io';

import 'package:openci_workflow/openci_workflow.dart';

Future<void> verifyRunNumber(OpenCI openCI) async {
  final assigned = int.parse(Platform.environment['OPENCI_RUN_NUMBER']!);
  if (assigned <= 0 || openCI.runNumber != assigned) {
    throw StateError('The environment and SDK run numbers must agree.');
  }
  final directory = await Directory.systemTemp.createTemp('g1538-consumer-');
  try {
    await File('${directory.path}/pubspec.yaml').writeAsString('''
name: run_number_consumer
environment:
  sdk: ^3.11.5
dependencies:
  openci_workflow: 0.1.6
''');
    await File('${directory.path}/main.dart').writeAsString('''
import 'dart:convert';
import 'dart:io';
import 'package:openci_workflow/openci_workflow.dart';

Future<void> main() async {
  final openCI = await OpenCI.init(workflowName: 'Probe', ciTriggers: const []);
  final first = openCI.runNumber;
  await Future<void>.delayed(const Duration(seconds: 5));
  final repeated = openCI.runNumber;
  final environment = int.parse(Platform.environment['OPENCI_RUN_NUMBER']!);
  if (first != repeated || first != environment || first <= 0) {
    throw StateError('Run number changed or differs from the environment.');
  }
  print('G1538_SMOKE ' + jsonEncode({
    'version': '0.1.6',
    'runId': Platform.environment['OPENCI_RUN_ID'],
    'jobId': Platform.environment['OPENCI_BUILD_JOB_ID'],
    'environment': environment,
    'sdk': first,
    'repeated': repeated,
  }));
}
''');
    for (final arguments in [
      ['pub', 'get'],
      ['analyze', '--fatal-infos', 'main.dart'],
      ['run', 'main.dart'],
    ]) {
      final result = await Process.run(
        'dart',
        arguments,
        workingDirectory: directory.path,
        environment: {'PUB_CACHE': '${directory.path}/pub-cache'},
      ).timeout(const Duration(minutes: 2));
      stdout.write(result.stdout);
      stderr.write(result.stderr);
      if (result.exitCode != 0) {
        throw StateError('Published SDK probe failed: dart $arguments');
      }
    }
    if (openCI.runNumber != assigned) {
      throw StateError('Run number changed during the workflow.');
    }
  } finally {
    await directory.delete(recursive: true);
  }
}
