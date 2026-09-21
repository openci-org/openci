import 'package:openci_workflow/openci_workflow.dart';

import 'paths.g.dart';

Future<void> main() async {
  final genuineCI = await GenuineCI.init(
    workflowName: 'OpenCI Shared CI',
    ciTriggers: [
      CiTrigger.pullRequest(branch: 'develop'),
      CiTrigger.push(branch: 'develop'),
    ],
    currentWorkingDirectory: WorkspacePaths.root.packages.openciShared,
  );

  await genuineCI.flutter.staticAnalysis();

  await genuineCI.flutter.unitTests();
}
