import 'package:openci_workflow/openci_workflow.dart';

import 'generated/paths.g.dart';

Future<void> main() async {
  final openCI = await OpenCI.init(
    workflowName: 'Dart Functions CI',
    ciTriggers: [
      CITrigger.pullRequest(branch: '*'),
      CITrigger.push(branch: 'develop'),
    ],
    currentWorkingDirectory: WorkspacePaths.root.firebase.dartFunctions,
  );

  await openCI.flutter.staticAnalysis();

  await openCI.flutter.unitTests();
}
