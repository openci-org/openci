import 'dart:io';

import 'package:openci_workflow/openci_workflow.dart';

import 'generated/paths.g.dart';
import 'generated/secrets.g.dart';

Future<void> main() async {
  final ci = await OpenCI.init(
    workflowName: 'Dashboard iOS Patrol',
    flutterVersion: '3.47.8',
    cancelPreviousRuns: true,
    ciTriggers: [
      CITrigger.pullRequest(
        branch: '*',
        paths: [
          'apps/dashboard/**',
          'packages/macos_updater/**',
          'packages/openci_shared/**',
          'packages/openci_workflow/**',
          'packages/pubspec_version_hook/**',
          'openci/dashboard_ios_patrol_ci.dart',
          'openci/generated/**',
          '**/pubspec.yaml',
          'pubspec.lock',
        ],
      ),
    ],
  );

  final dashboard = WorkspacePaths.root.apps.dashboard;
  await ci.placeFileFromBase64(
    dir: dashboard.lib,
    fileName: 'firebase_options.dart',
    base64Content: Secrets.firebaseOptionsDartBase64.value,
  );
  await ci.placeFileFromBase64(
    dir: dashboard.ios.runner,
    fileName: 'GoogleService-Info.plist',
    base64Content: Secrets.googleServiceInfoPlistBase64.value,
  );

  final simulator = await ci.launchIosSimulator(
    name: 'OpenCI Dashboard Patrol',
  );
  try {
    // Preserve finally cleanup when Patrol fails; ci.run exits on failure.
    final process = await Process.start(
      'dart',
      [
        'run',
        'patrol_cli:main',
        'test',
        '--target',
        'patrol_test/app_startup_test.dart',
        '--device',
        simulator.id,
      ],
      workingDirectory: '${ci.workspacePath}/$dashboard',
      mode: ProcessStartMode.inheritStdio,
    );
    exitCode = await process.exitCode;
  } finally {
    await simulator.dispose();
  }
}
