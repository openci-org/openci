import 'package:openci_workflow/openci_workflow.dart';

Future<void> main() async {
  final openCI = await OpenCI.init(
    workflowName: 'Website CI',
    ciTriggers: [
      CITrigger.pullRequest(branch: '*'),
      CITrigger.push(branch: 'develop'),
    ],
    currentWorkingDirectory: 'apps/website',
  );

  // Bootstrap the pinned runtime; CI VMs may not have Node.js/npm installed.
  await openCI.run('bash scripts/ci.sh');
}
