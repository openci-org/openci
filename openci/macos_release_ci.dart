import 'package:openci_workflow/openci_workflow.dart';

import 'generated/paths.g.dart';
import 'generated/secrets.g.dart';

Future<void> main() async {
  final ci = await OpenCI.init(
    workflowName: 'macOS release checks',
    flutterVersion: '3.47.8',
    cancelPreviousRuns: true,
    ciTriggers: [
      CITrigger.pullRequest(
        branch: '*',
        paths: [
          'apps/dashboard/macos/**',
          'apps/dashboard/lib/utilities/macos_updater_initializer.dart',
          'packages/macos_updater/**',
          'openci/dashboard_macos_cd.dart',
          'openci/macos_release_ci.dart',
          'openci/lib/**',
          'openci/tool/**',
          'openci/test/**',
          'openci/generated/**',
          '**/pubspec.yaml',
          'pubspec.lock',
        ],
      ),
    ],
  );

  await ci.placeFileFromBase64(
    dir: WorkspacePaths.root.apps.dashboard.lib,
    fileName: 'firebase_options.dart',
    base64Content: Secrets.firebaseOptionsDartBase64.value,
  );
  await ci.flutter.unitTests(dir: 'apps/dashboard');
  await ci.flutter.unitTests(dir: 'packages/macos_updater');
  await ci.run('dart test', workingDirectory: 'openci');
  await ci.run(
    'dart run openci/tool/release_macos.dart --build-number=1 --validate-only',
  );
}
