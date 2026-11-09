import 'package:openci_workflow/openci_workflow.dart';

Future<void> main() async {
  final openCI = await OpenCI.init(
    workflowName: 'Firebase Functions CI',
    cancelPreviousRuns: true,
    ciTriggers: [
      CITrigger.pullRequest(
        branch: '*',
        paths: [
          'firebase/functions/**',
          'firebase/generated/**',
          'firebase/scripts/**',
          'firebase/healthcheck.ts',
          'firebase/package.json',
          'firebase/tsconfig*.json',
          'package.json',
          'package-lock.json',
          'vite.config.mts',
          '.node-version',
          'openci/firebase_functions_ci.dart',
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
          'firebase/functions/**',
          'firebase/generated/**',
          'firebase/scripts/**',
          'firebase/healthcheck.ts',
          'firebase/package.json',
          'firebase/tsconfig*.json',
          'package.json',
          'package-lock.json',
          'vite.config.mts',
          '.node-version',
          'openci/firebase_functions_ci.dart',
          'packages/openci_workflow/**',
          'packages/pubspec_version_hook/**',
          'openci/generated/**',
          '**/pubspec.yaml',
          'pubspec.lock',
          '.fvmrc',
        ],
      ),
    ],
    currentWorkingDirectory: 'firebase',
  );

  // Bootstrap the pinned runtime; CI VMs may not have Node.js/npm installed.
  await openCI.run('bash scripts/ci.sh');
}
