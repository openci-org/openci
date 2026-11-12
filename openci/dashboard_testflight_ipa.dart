import 'package:openci_workflow/openci_workflow.dart';
import 'package:openci_workflows/dashboard_store_build_number.dart';

import 'generated/paths.g.dart';
import 'generated/secrets.g.dart';

Future<void> main() async {
  final dashboard = WorkspacePaths.root.apps.dashboard;
  final ci = await OpenCI.init(
    workflowName: 'Dashboard TestFlight IPA',
    flutterVersion: '3.47.8',
    ciTriggers: [
      CITrigger.push(
        branch: 'develop',
        paths: [
          'apps/dashboard/ios/**',
          'apps/dashboard/lib/**',
          'apps/dashboard/assets/**',
          'apps/dashboard/pubspec.yaml',
          'apps/dashboard/shorebird.yaml',
          'packages/macos_updater/lib/**',
          'packages/openci_shared/lib/**',
          'packages/openci_workflow/lib/**',
          'packages/pubspec_version_hook/lib/**',
          'packages/*/pubspec.yaml',
          'openci/dashboard_testflight_ipa.dart',
          'openci/lib/dashboard_store_build_number.dart',
          'openci/generated/**',
          'openci/pubspec.yaml',
          'pubspec.yaml',
          'pubspec.lock',
        ],
      ),
    ],
    currentWorkingDirectory: dashboard,
  );

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

  final ascKeys = AppStoreConnectKeys(
    issuerId: Secrets.openciGeneratedAscIssuerId.value,
    keyId: Secrets.openciGeneratedAscKeyId.value,
    privateKeyBase64: Secrets.openciGeneratedP8Base64.value,
  );
  final buildNumber = dashboardStoreBuildNumber(ci.runNumber);
  final ipaPath = await ci.flutter.buildIpa(
    distributionMethod: IosDistributionMethod.appStore,
    ascKeys: ascKeys,
    certificatePrivateKey:
        Secrets.openciGeneratedIosCertificatePrivateKey.value,
    additionalArguments: ['--build-number=$buildNumber'],
  );
  await ci.flutter.deployIpaToTestFlight(ipaPath: ipaPath, ascKeys: ascKeys);
}
