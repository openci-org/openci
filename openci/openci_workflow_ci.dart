import 'package:openci_workflow/openci_workflow.dart';

import 'generated/paths.g.dart';

Future<void> main() async {
  final openCI = await OpenCI.init(
    workflowName: 'OpenCI Workflow CI',
    cancelPreviousRuns: true,
    ciTriggers: [
      CITrigger.pullRequest(
        branch: '*',
        paths: [
          'packages/openci_workflow/**',
          'analysis_options.yaml',
          'openci/openci_workflow_ci.dart',
          'packages/pubspec_version_hook/**',
          'openci/generated/**',
          '**/pubspec.yaml',
          'pubspec.lock',
          '.fvmrc',
        ],
      ),
      CITrigger.push(
        branch: 'develop',
        paths: [
          'packages/openci_workflow/**',
          'analysis_options.yaml',
          'openci/openci_workflow_ci.dart',
          'packages/pubspec_version_hook/**',
          'openci/generated/**',
          '**/pubspec.yaml',
          'pubspec.lock',
          '.fvmrc',
        ],
      ),
    ],
    currentWorkingDirectory: WorkspacePaths.root.packages.openciWorkflow,
  );

  await openCI.flutter.staticAnalysis();

  // Subprocess tests require Isolate.packageConfig from the Dart test runner.
  await openCI.run('dart test');
}
