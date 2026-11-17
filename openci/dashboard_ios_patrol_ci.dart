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
          'packages/pubspec_version_hook/**',
          'openci/dashboard_ios_patrol_ci.dart',
          'openci/tool/run_dashboard_ios_patrol.sh',
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

  await ci.run('bash openci/tool/run_dashboard_ios_patrol.sh');
}
