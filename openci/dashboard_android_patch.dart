import 'package:openci_workflow/openci_workflow.dart';

import 'generated/paths.g.dart';
import 'generated/secrets.g.dart';
import 'lib/dashboard_patch_mode.dart';

Future<void> main() async {
  final dashboard = WorkspacePaths.root.apps.dashboard;
  final ci = await OpenCI.init(
    workflowName: 'Dashboard Android Patch',
    flutterVersion: FlutterVersion.v3_47_8.value,
    cancelPreviousRuns: true,
    ciTriggers: [
      CITrigger.pullRequest(
        branch: '*',
        paths: [
          'apps/dashboard/android/**',
          'apps/dashboard/lib/**',
          'apps/dashboard/assets/**',
          'apps/dashboard/pubspec.yaml',
          'apps/dashboard/shorebird.yaml',
          'packages/macos_updater/lib/**',
          'packages/openci_shared/lib/**',
          'packages/openci_workflow/lib/**',
          'packages/pubspec_version_hook/lib/**',
          'packages/*/pubspec.yaml',
          'openci/dashboard_android_patch.dart',
          'openci/lib/dashboard_patch_mode.dart',
          'openci/generated/**',
          'openci/pubspec.yaml',
          'pubspec.yaml',
          'pubspec.lock',
        ],
      ),
      CITrigger.push(
        branch: 'develop',
        paths: [
          'apps/dashboard/android/**',
          'apps/dashboard/lib/**',
          'apps/dashboard/assets/**',
          'apps/dashboard/pubspec.yaml',
          'apps/dashboard/shorebird.yaml',
          'packages/macos_updater/lib/**',
          'packages/openci_shared/lib/**',
          'packages/openci_workflow/lib/**',
          'packages/pubspec_version_hook/lib/**',
          'packages/*/pubspec.yaml',
          'openci/dashboard_android_patch.dart',
          'openci/lib/dashboard_patch_mode.dart',
          'openci/generated/**',
          'openci/pubspec.yaml',
          'pubspec.yaml',
          'pubspec.lock',
        ],
      ),
    ],
    currentWorkingDirectory: dashboard,
  );

  final mode = DashboardPatchMode.forContext(ci.context);
  if (mode == null) return;
  if (Secrets.shorebirdToken.value.trim().isEmpty) {
    throw StateError('SHOREBIRD_TOKEN is empty.');
  }
  await ci.placeFileFromBase64(
    dir: dashboard.lib,
    fileName: 'firebase_options.dart',
    base64Content: Secrets.firebaseOptionsDartBase64.value,
  );
  await ci.placeFileFromBase64(
    dir: dashboard.android.app,
    fileName: 'google-services.json',
    base64Content: Secrets.googleServicesJsonBase64.value,
  );
  if (mode == DashboardPatchMode.publish) {
    await ci.placeFileFromBase64(
      dir: dashboard.android,
      fileName: 'key.properties',
      base64Content: Secrets.keyPropertiesBase64.value,
    );
    await ci.placeFileFromBase64(
      dir: dashboard.android.app,
      fileName: 'upload-keystore.jks',
      base64Content: Secrets.uploadKeystoreJksBase64.value,
    );
  }
  await ci.run(
    'CI=true shorebird patch android --release-version=latest '
    '${mode.shorebirdArgument}',
  );
}
