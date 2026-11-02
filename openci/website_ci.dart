import 'package:openci_workflow/openci_workflow.dart';

Future<void> main() async {
  final openCI = await OpenCI.init(
    workflowName: 'Website CI',
    ciTriggers: [
      CITrigger.pullRequest(
        branch: '*',
        paths: [
          'apps/website/**',
          'package.json',
          'package-lock.json',
          'vite.config.mts',
          '.node-version',
          'openci/website_ci.dart',
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
          'apps/website/**',
          'package.json',
          'package-lock.json',
          'vite.config.mts',
          '.node-version',
          'openci/website_ci.dart',
          'packages/openci_workflow/**',
          'packages/pubspec_version_hook/**',
          'openci/generated/**',
          '**/pubspec.yaml',
          'pubspec.lock',
          '.fvmrc',
        ],
      ),
    ],
    currentWorkingDirectory: 'apps/website',
  );

  // Bootstrap the pinned runtime; CI VMs may not have Node.js/npm installed.
  await openCI.run('bash scripts/ci.sh');
}
