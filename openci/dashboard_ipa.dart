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

  await openCI.run('''
set -eu
if ! command -v npm >/dev/null 2>&1; then
  brew install node
fi
npm install --prefix .dart_tool/firebase-cli --no-audit --no-fund firebase-tools@15.25.0
.dart_tool/firebase-cli/node_modules/.bin/firebase --version
''');

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

  final ipaPath = await openCI.flutter.buildIpa(
    distributionMethod: IosDistributionMethod.adHoc,
    ascKeys: AppStoreConnectKeys(
      issuerId: Secrets.openciGeneratedAscIssuerId,
      keyId: Secrets.openciGeneratedAscKeyId,
      privateKeyBase64: Secrets.openciGeneratedP8Base64,
    ),
    certificatePrivateKey: Secrets.openciGeneratedIosCertificatePrivateKey,
  );

  await openCI.flutter.deployIpaToFirebaseAppDistribution(
    ipaPath: ipaPath,
    serviceAccountJsonBase64: Secrets.firebaseServiceAccountJsonBase64,
    firebaseCliPath: '.dart_tool/firebase-cli/node_modules/.bin/firebase',
  );

  await openCI.run('ls -lh build/ios/ipa/*.ipa');
}
