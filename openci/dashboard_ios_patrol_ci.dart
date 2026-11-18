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
      CITrigger.push(
        branch: 'develop',
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
    await ci.patrol.test(
      dir: dashboard,
      device: simulator.id,
      targets: ['patrol_test/app_startup_test.dart'],
      env: [
        Secrets.dashboardPatrolEmail,
        Secrets.dashboardPatrolPassword,
      ],
    );
  } finally {
    await simulator.dispose();
  }
}
