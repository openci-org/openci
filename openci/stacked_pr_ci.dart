import 'package:openci_workflow/openci_workflow.dart';

Future<void> main() async {
  final openCI = await OpenCI.init(
    workflowName: 'Stacked PR CI',
    ciTriggers: [
      CITrigger.pullRequest(branch: '*'),
      CITrigger.push(branch: 'develop'),
    ],
    currentWorkingDirectory: 'apps/stacked_pr',
  );

  await openCI.run('bash scripts/ci.sh');
}
