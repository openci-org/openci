import 'package:openci_workflow/openci_workflow.dart';

Future<void> main() async {
  final openCI = await OpenCI.init(
    workflowName: 'Stacked PR CI',
    ciTriggers: [
      CITrigger.pullRequest(
        branch: '*',
        paths: [
          'apps/stacked_pr/**',
          '.node-version',
          'openci/stacked_pr_ci.dart',
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
          'apps/stacked_pr/**',
          '.node-version',
          'openci/stacked_pr_ci.dart',
          'packages/openci_workflow/**',
          'packages/pubspec_version_hook/**',
          'openci/generated/**',
          '**/pubspec.yaml',
          'pubspec.lock',
          '.fvmrc',
        ],
      ),
    ],
    currentWorkingDirectory: 'apps/stacked_pr',
  );

  await openCI.run('bash scripts/ci.sh');
}
