import 'package:openci_workflow/openci_workflow.dart';

import '../../generated/paths.g.dart';
import '../../generated/secrets.g.dart';
import '../../lib/dashboard_patch_mode.dart';

Future<void> main() async {
  final dashboard = WorkspacePaths.root.apps.dashboard;
  final ci = await OpenCI.init(
    workflowName: 'Dashboard iOS Patch',
    flutterVersion: FlutterVersion.v3_47_8.value,
    cancelPreviousRuns: true,
    ciTriggers: [
      CITrigger.pullRequest(
        branch: '*',
        paths: [
          'apps/dashboard/ios/**',
          'apps/dashboard/lib/**',
          'apps/dashboard/assets/**',
          'apps/dashboard/pubspec.yaml',
          'apps/dashboard/shorebird.yaml',
          'apps/dashboard/tool/configure_google_sign_in.dart',
          'packages/macos_updater/lib/**',
          'packages/openci_shared/lib/**',
          'packages/openci_workflow/lib/**',
          'packages/pubspec_version_hook/lib/**',
          'packages/*/pubspec.yaml',
          'openci/dashboard/ios/patch.dart',
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
          'apps/dashboard/ios/**',
          'apps/dashboard/lib/**',
          'apps/dashboard/assets/**',
          'apps/dashboard/pubspec.yaml',
          'apps/dashboard/shorebird.yaml',
          'apps/dashboard/tool/configure_google_sign_in.dart',
          'packages/macos_updater/lib/**',
          'packages/openci_shared/lib/**',
          'packages/openci_workflow/lib/**',
          'packages/pubspec_version_hook/lib/**',
          'packages/*/pubspec.yaml',
          'openci/dashboard/ios/patch.dart',
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
  final release = await findDashboardPatchRelease(
    directory: dashboard,
    platform: 'ios',
  );
  if (release == null) return;
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
  await ci.run('dart run tool/configure_google_sign_in.dart ios');
  await ci.run(
    'CI=true shorebird patch ios --release-version=$release --no-codesign '
    '${mode.shorebirdArgument}',
  );
}
