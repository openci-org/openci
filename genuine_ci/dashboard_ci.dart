import 'package:genuine_ci/genuine_ci.dart';

import 'paths.g.dart';
import 'secrets.g.dart';

Future<void> main() async {
  final genuineCI = await GenuineCI.init(
    workflowName: 'Dashboard CI',
    ciTriggers: [
      CiTrigger.pullRequest(branch: 'develop'),
      CiTrigger.push(branch: 'develop'),
    ],
  );

  await genuineCI.placeFileFromBase64(
    dir: WorkspacePaths.root.apps.dashboard.lib,
    fileName: 'firebase_options.dart',
    base64Content: Secrets.firebaseOptionsDartBase64,
  );

  await FlutterCi.staticAnalysis(WorkspacePaths.root.apps.dashboard);

  await FlutterCi.unitTests(WorkspacePaths.root.apps.dashboard);
}
