import 'package:openci_workflow/openci_workflow.dart';

import 'generated/paths.g.dart';
import 'generated/secrets.g.dart';
import 'lib/virtual_ble_checks.dart';

Future<void> main() async {
  final ci = await OpenCI.init(
    workflowName: 'OpenCI Workflow CD',
    flutterVersion: FlutterVersion.v3_47_8.value,
    ciTriggers: [
      CITrigger.push(
        branch: 'develop',
        paths: [
          'packages/openci_workflow/pubspec.yaml',
          'packages/openci_workflow/CHANGELOG.md',
        ],
      ),
    ],
    currentWorkingDirectory: WorkspacePaths.root.packages.openciWorkflow,
  );

  await runVirtualBleChecks(ci);
  await ci.dart.publishToPubDev(
    serviceAccountJsonBase64: Secrets.pubDevServiceAccountJsonBase64.value,
    skipIfPublished: true,
  );
}
