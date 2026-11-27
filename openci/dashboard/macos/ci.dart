import 'package:openci_workflow/openci_workflow.dart';

import '../../generated/paths.g.dart';
import '../../generated/secrets.g.dart';

Future<void> main() async {
  final ci = await OpenCI.init(
    workflowName: 'macOS release checks',
    flutterVersion: FlutterVersion.v3_47_8.value,
    cancelPreviousRuns: true,
    ciTriggers: [
      CITrigger.pullRequest(
        branch: '*',
        paths: [
          'apps/dashboard/**',
          'packages/macos_updater/**',
          'packages/openci_shared/**',
          'openci/dashboard/macos/publish.dart',
          'openci/dashboard/macos/ci.dart',
          'openci/lib/macos_release_publisher.dart',
          'openci/tool/release_macos.dart',
          'openci/pubspec.yaml',
          'pubspec.yaml',
          'pubspec.lock',
          '.fvmrc',
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
  await ci.flutter.unitTests(dir: dashboard, excludeTags: 'golden');
  await ci.run(
    'flutter test --no-pub --tags golden',
    workingDirectory: dashboard,
  );
  await ci.flutter.unitTests(dir: 'packages/macos_updater');
  await ci.run(
    'dart run openci/tool/release_macos.dart --build-number=1 --validate-only',
  );
}
