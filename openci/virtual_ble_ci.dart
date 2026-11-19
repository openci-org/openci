import 'package:openci_workflow/openci_workflow.dart';

import 'generated/paths.g.dart';
import 'lib/virtual_ble_checks.dart';

Future<void> main() async {
  final ci = await OpenCI.init(
    workflowName: 'Virtual BLE iOS E2E',
    currentWorkingDirectory: WorkspacePaths.root.packages.openciWorkflow,
    flutterVersion: FlutterVersion.v3_47_8.value,
    cancelPreviousRuns: true,
    ciTriggers: [
      CITrigger.pullRequest(
        branch: '*',
        paths: [
          'packages/openci_workflow/lib/**',
          'packages/openci_workflow/integration_test/**',
          'packages/openci_virtual_ble/**',
          'openci/lib/virtual_ble_checks.dart',
          'openci/virtual_ble_ci.dart',
          'openci/openci_workflow_cd.dart',
          '**/pubspec.yaml',
          'pubspec.yaml',
          'pubspec.lock',
        ],
      ),
      CITrigger.push(
        branch: 'develop',
        paths: [
          'packages/openci_workflow/lib/**',
          'packages/openci_workflow/integration_test/**',
          'packages/openci_virtual_ble/**',
          'openci/lib/virtual_ble_checks.dart',
          'openci/virtual_ble_ci.dart',
          'openci/openci_workflow_cd.dart',
          '**/pubspec.yaml',
          'pubspec.yaml',
          'pubspec.lock',
        ],
      ),
    ],
  );
  await runVirtualBleChecks(ci);
}
