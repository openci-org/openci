import 'package:openci_workflow/openci_workflow.dart';

import 'generated/paths.g.dart';
import 'generated/secrets.g.dart';

Future<void> main() async {
  final ci = await OpenCI.init(
    workflowName: 'Dashboard macOS CD',
    flutterVersion: '3.47.8',
    ciTriggers: [
      CITrigger.push(
        branch: 'develop',
        paths: [
          'apps/dashboard/**',
          'packages/macos_updater/**',
          'packages/openci_shared/**',
          'packages/openci_workflow/**',
          'packages/pubspec_version_hook/**',
          'openci/dashboard_macos_cd.dart',
          'openci/lib/**',
          'openci/tool/**',
          'openci/generated/secrets.g.dart',
          '**/pubspec.yaml',
          'pubspec.lock',
        ],
      ),
    ],
  );

  // References here let the planner inject only this workflow's credentials.
  // Values are read by the release process from its environment, never placed
  // in the logged shell command.
  for (final secret in [
    Secrets.firebaseOptionsDartBase64,
    Secrets.openciGeneratedAscIssuerId,
    Secrets.openciGeneratedAscKeyId,
    Secrets.openciGeneratedP8Base64,
    // The Account Holder issues this key's Developer ID certificate once.
    // Subsequent releases fetch and reuse that certificate.
    Secrets.macosCertificatePrivateKey,
    Secrets.sparklePrivateEdKey,
    Secrets.macosReleaseServiceAccountJsonBase64,
  ]) {
    if (secret.value.trim().isEmpty) {
      throw StateError('Required secret ${secret.key} is empty.');
    }
  }

  await ci.placeFileFromBase64(
    dir: WorkspacePaths.root.apps.dashboard.lib,
    fileName: 'firebase_options.dart',
    base64Content: Secrets.firebaseOptionsDartBase64.value,
  );
  await ci.flutter.unitTests(dir: 'apps/dashboard');
  await ci.flutter.unitTests(dir: 'packages/macos_updater');
  await ci.run('dart test', workingDirectory: 'openci');
  await ci.run(
    'dart run openci/tool/release_macos.dart --build-number=${ci.runNumber}',
  );
}
