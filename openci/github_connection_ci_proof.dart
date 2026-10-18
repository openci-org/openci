import 'package:openci_workflow/openci_workflow.dart';

Future<void> main() async {
  final openCI = await OpenCI.init(
    workflowName: 'GitHub Connect isolated CI proof',
    ciTriggers: [
      CITrigger.pullRequest(branch: 'codex/g1381-ci-base-20261018-2227'),
      CITrigger.push(branch: 'codex/g1381-ci-proof-20261018-2227'),
    ],
  );

  await openCI.run('dart --version');
  await openCI.run(
    'dart test test/api/github_connection_api_test.dart',
    workingDirectory: 'packages/openci_shared',
  );
}
