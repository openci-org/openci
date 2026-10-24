import 'package:openci_workflow/openci_workflow.dart';

import 'generated/paths.g.dart';

Future<void> main() async {
  final openCI = await OpenCI.init(
    workflowName: 'OpenCI Workflow CI',
    ciTriggers: [
      CITrigger.pullRequest(branch: '*'),
      CITrigger.push(branch: 'develop'),
    ],
    currentWorkingDirectory: WorkspacePaths.root.packages.openciWorkflow,
  );

  await openCI.flutter.staticAnalysis();

  // Subprocess tests require Isolate.packageConfig from the Dart test runner.
  await openCI.run('dart test');
}
