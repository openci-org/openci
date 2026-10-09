import 'package:openci_workflow/openci_workflow.dart';

import 'generated/paths.g.dart';
import 'generated/secrets.g.dart';

Future<void> main() async {
  final openCI = await OpenCI.init(
    workflowName: 'Dashboard IPA',
    ciTriggers: [
      CITrigger.pullRequest(branch: 'develop'),
      CITrigger.push(branch: 'develop'),
    ],
    currentWorkingDirectory: WorkspacePaths.root.apps.dashboard,
  );

  await openCI.placeFileFromBase64(
    dir: WorkspacePaths.root.apps.dashboard.lib,
    fileName: 'firebase_options.dart',
    base64Content: Secrets.firebaseOptionsDartBase64,
  );
  await openCI.placeFileFromBase64(
    dir: WorkspacePaths.root.apps.dashboard.ios.runner,
    fileName: 'GoogleService-Info.plist',
    base64Content: Secrets.googleServiceInfoPlistBase64,
  );

  await openCI.run('xcodebuild -version');
  await openCI.run('xcodebuild -showsdks');
  await openCI.run('xcrun simctl list runtimes');

  await openCI.flutter.buildIpa(
    distributionMethod: IosDistributionMethod.adHoc,
    ascKeys: AppStoreConnectKeys(
      issuerId: Secrets.openciGeneratedAscIssuerId,
      keyId: Secrets.openciGeneratedAscKeyId,
      privateKeyBase64: Secrets.openciGeneratedP8Base64,
    ),
    certificatePrivateKey: Secrets.openciGeneratedIosCertificatePrivateKey,
  );

  await openCI.run('ls -lh build/ios/ipa/*.ipa');
}
