import 'package:openci_workflow/openci_workflow.dart';

import 'paths.g.dart';

Future<void> main() async {
  final openCI = await OpenCI.init(
    workflowName: 'OpenCI Workflow CI',
    ciTriggers: [
      CITrigger.pullRequest(branch: 'develop'),
      CITrigger.push(branch: 'develop'),
    ],
    currentWorkingDirectory: WorkspacePaths.root.packages.openciWorkflow,
  );

  await openCI.run('dart --suppress-analytics analyze --fatal-infos');

  await openCI.run('dart --suppress-analytics test');
}
