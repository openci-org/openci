import 'package:openci_workflow/openci_workflow.dart';

import 'paths.g.dart';

Future<void> main() async {
  final openCI = await OpenCI.init(
    workflowName: 'OpenCI Server CI',
    ciTriggers: [
      CITrigger.pullRequest(branch: 'develop'),
      CITrigger.push(branch: 'develop'),
    ],
    currentWorkingDirectory: WorkspacePaths.root.apps.openciServer,
  );

  await openCI.flutter.staticAnalysis();

  await openCI.flutter.unitTests();
}
