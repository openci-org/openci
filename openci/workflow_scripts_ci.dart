import 'package:openci_workflow/openci_workflow.dart';

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
  );

  await ci.run('dart analyze --fatal-infos openci');
  await ci.run('dart test', workingDirectory: 'openci');
}
