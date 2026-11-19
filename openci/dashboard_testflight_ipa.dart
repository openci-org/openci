import 'package:openci_workflow/openci_workflow.dart';
import 'package:openci_workflows/dashboard_store_build_number.dart';

import 'generated/paths.g.dart';
import 'generated/secrets.g.dart';

Future<void> main() async {
  final dashboard = WorkspacePaths.root.apps.dashboard;
  final ci = await OpenCI.init(
    workflowName: 'Dashboard TestFlight IPA',
    flutterVersion: '3.47.8',
    ciTriggers: [CITrigger.release()],
    currentWorkingDirectory: dashboard,
  );

  final context = ci.context;
  if (context is! PushContext || !context.branch.startsWith('refs/tags/')) {
    return;
  }
  if (Secrets.shorebirdToken.value.trim().isEmpty) {
    throw StateError('SHOREBIRD_TOKEN is empty.');
  }

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
  await ci.run('dart run tool/configure_google_sign_in.dart ios');
  final buildNumber = dashboardStoreBuildNumber(ci.runNumber);
  final ipaPath = await ci.shorebird.releaseIos(
    bundleId: 'org.openci.dashboard.prod',
    flutterVersion: ci.flutterVersion!,
    distributionMethod: IosDistributionMethod.appStore,
    ascKeys: ascKeys,
    certificatePrivateKey:
        Secrets.openciGeneratedIosCertificatePrivateKey.value,
    additionalArguments: ['--build-number=$buildNumber'],
  );
  await ci.flutter.deployIpaToTestFlight(ipaPath: ipaPath, ascKeys: ascKeys);
}
