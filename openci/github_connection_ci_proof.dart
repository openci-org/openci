import 'package:openci_workflow/openci_workflow.dart';

Future<void> main() async {
  final openCI = await OpenCI.init(
    workflowName: 'GitHub Connect isolated CI proof',
    ciTriggers: [],
  );

  await openCI.run('dart --version');
  await openCI.run(
    'dart test test/api/github_connection_api_test.dart',
    workingDirectory: 'packages/openci_shared',
  );
}
