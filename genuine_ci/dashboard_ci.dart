import 'package:openci_workflow/openci_workflow.dart';

import 'paths.g.dart';
import 'secrets.g.dart';

Future<void> main() async {
  final openCI = await OpenCI.init(
    workflowName: 'Dashboard CI',
    ciTriggers: [
      CITrigger.pullRequest(branch: 'develop'),
      CITrigger.push(branch: 'develop'),
    ],
    currentWorkingDirectory: WorkspacePaths.root.apps.dashboard,
  );

  await openCI.placeFileFromBase64(
    dir: WorkspacePaths.root.apps.dashboard.lib,
    fileName: 'firebase_options.dart',
    base64Content: Secrets.firebaseOptionsDartBase64,
  );

  await openCI.flutter.staticAnalysis();

  await openCI.flutter.unitTests();
}
