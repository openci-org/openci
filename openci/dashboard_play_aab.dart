import 'package:openci_workflow/openci_workflow.dart';
import 'package:openci_workflows/dashboard_store_build_number.dart';

import 'generated/paths.g.dart';
import 'generated/secrets.g.dart';

Future<void> main() async {
  final dashboard = WorkspacePaths.root.apps.dashboard;
  final ci = await OpenCI.init(
    workflowName: 'Dashboard Google Play AAB',
    flutterVersion: '3.47.8',
    // Store uploads will resume on GitHub Release publication.
    ciTriggers: [],
    currentWorkingDirectory: dashboard,
  );

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

  final buildNumber = dashboardStoreBuildNumber(ci.runNumber);
  await ci.run('flutter build appbundle --release --build-number=$buildNumber');
  await ci.flutter.deployAabToPlayConsole(
    aabPath: 'build/app/outputs/bundle/release/app-release.aab',
    packageName: 'org.openci.dashboard.prod',
    serviceAccountJsonBase64: Secrets.googlePlayServiceAccountJsonBase64.value,
    track: 'internal',
  );
}
