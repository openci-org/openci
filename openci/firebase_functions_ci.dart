import 'package:openci_workflow/openci_workflow.dart';

Future<void> main() async {
  final openCI = await OpenCI.init(
    workflowName: 'Firebase Functions CI',
    cancelPreviousRuns: true,
    ciTriggers: [
      CITrigger.pullRequest(
        branch: '*',
        paths: [
          'firebase/{functions,generated,scripts}/**',
          'firebase/{healthcheck.ts,package.json,tsconfig*.json}',
          'package.json',
          'package-lock.json',
          'vite.config.mts',
          '.node-version',
          'openci/firebase_functions_ci.dart',
          'packages/{openci_workflow,pubspec_version_hook}/**',
          'openci/generated/**',
          '**/pubspec.yaml',
          'pubspec.lock',
          '.fvmrc',
        ],
      ),
      CITrigger.push(
        branch: 'develop',
        paths: [
          'firebase/{functions,generated,scripts}/**',
          'firebase/{healthcheck.ts,package.json,tsconfig*.json}',
          'package.json',
          'package-lock.json',
          'vite.config.mts',
          '.node-version',
          'openci/firebase_functions_ci.dart',
          'packages/{openci_workflow,pubspec_version_hook}/**',
          'openci/generated/**',
          '**/pubspec.yaml',
          'pubspec.lock',
          '.fvmrc',
        ],
      ),
    ],
  );

  await openCI.run('bash firebase/scripts/ci.sh');
}
