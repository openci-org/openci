import 'package:openci_workflow/openci_workflow.dart';

import 'paths.g.dart';

Future<void> main() async {
  final openCI = await OpenCI.init(
    workflowName: 'GenuineCI Server CI',
    ciTriggers: [
      CiTrigger.pullRequest(branch: 'develop'),
      CiTrigger.push(branch: 'develop'),
    ],
    currentWorkingDirectory: WorkspacePaths.root.apps.genuineciServer,
  );

  await openCI.flutter.staticAnalysis();

  await openCI.flutter.unitTests();
}
