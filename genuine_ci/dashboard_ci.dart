import 'package:openci_workflow/openci_workflow.dart';

import 'paths.g.dart';
import 'secrets.g.dart';

Future<void> main() async {
  final genuineCI = await GenuineCI.init(
    workflowName: 'Dashboard CI',
    ciTriggers: [
      CiTrigger.pullRequest(branch: 'develop'),
      CiTrigger.push(branch: 'develop'),
    ],
    currentWorkingDirectory: WorkspacePaths.root.apps.dashboard,
  );

  await genuineCI.placeFileFromBase64(
    dir: WorkspacePaths.root.apps.dashboard.lib,
    fileName: 'firebase_options.dart',
    base64Content: Secrets.firebaseOptionsDartBase64,
  );

  await genuineCI.flutter.staticAnalysis();

  await genuineCI.flutter.unitTests();
}
