import 'package:openci_workflow/openci_workflow.dart';

import 'generated/paths.g.dart';

Future<void> main() async {
  final openCI = await OpenCI.init(
    workflowName: 'Dart Functions CI',
    ciTriggers: [
      CITrigger.pullRequest(
        branch: '*',
        paths: [
          'firebase/dart_functions/**',
          'packages/openci_shared/**',
          'analysis_options.yaml',
          'openci/dart_functions_ci.dart',
          'packages/openci_workflow/**',
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
          'firebase/dart_functions/**',
          'packages/openci_shared/**',
          'analysis_options.yaml',
          'openci/dart_functions_ci.dart',
          'packages/openci_workflow/**',
          'packages/pubspec_version_hook/**',
          'openci/generated/**',
          '**/pubspec.yaml',
          'pubspec.lock',
          '.fvmrc',
        ],
      ),
    ],
    currentWorkingDirectory: WorkspacePaths.root.firebase.dartFunctions,
  );

  await openCI.flutter.staticAnalysis();

  await openCI.flutter.unitTests();
}
