import 'package:openci_workflow/openci_workflow.dart';

Future<void> main() async {
  final openCI = await OpenCI.init(
    workflowName: 'GitHub Connect production rollout check',
    ciTriggers: [
      CITrigger.pullRequest(branch: 'codex/g1379-rollout-base-20261019'),
      CITrigger.push(branch: 'codex/g1379-rollout-proof-20261019'),
    ],
  );

  await openCI.run('dart --version');
  await openCI.run(
    'dart test test/api/github_connection_api_test.dart',
    workingDirectory: 'packages/openci_shared',
  );
}
