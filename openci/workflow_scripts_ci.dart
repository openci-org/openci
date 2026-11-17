import 'package:openci_workflow/openci_workflow.dart';

import 'generated/paths.g.dart';

Future<void> main() async {
  final ci = await OpenCI.init(
    workflowName: 'Workflow Scripts CI',
    flutterVersion: '3.47.8',
    cancelPreviousRuns: true,
    ciTriggers: [
      CITrigger.pullRequest(
        branch: '*',
        paths: [
          'openci/**',
          'packages/openci_workflow/**',
          'analysis_options.yaml',
          '**/pubspec.yaml',
          'pubspec.lock',
          '.fvmrc',
        ],
      ),
      CITrigger.push(
        branch: 'develop',
        paths: [
          'openci/**',
          'packages/openci_workflow/**',
          'analysis_options.yaml',
          '**/pubspec.yaml',
          'pubspec.lock',
          '.fvmrc',
        ],
      ),
    ],
    currentWorkingDirectory: WorkspacePaths.root.openci,
  );

  await ci.dart.analyze(fatalInfos: true);
  await ci.dart.test();
}
