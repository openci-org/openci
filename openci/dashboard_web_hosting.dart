import 'package:openci_workflow/openci_workflow.dart';

import 'generated/paths.g.dart';
import 'generated/secrets.g.dart';

Future<void> main() async {
  final ci = await OpenCI.init(
    workflowName: 'Dashboard Web Hosting',
    flutterVersion: FlutterVersion.v3_47_8.value,
    cancelPreviousRuns: true,
    ciTriggers: [
      CITrigger.pullRequest(
        branch: '*',
        paths: [
          'apps/dashboard/lib/**',
          'apps/dashboard/web/**',
          'apps/dashboard/assets/**',
          'apps/dashboard/shorebird.yaml',
          'firebase/firebase.json',
          'firebase/.firebaserc',
          'packages/macos_updater/**',
          'packages/openci_shared/**',
          'packages/pubspec_version_hook/**',
          'openci/dashboard_web_hosting.dart',
          'openci/generated/**',
          '**/pubspec.yaml',
          'pubspec.lock',
          '.node-version',
        ],
      ),
      CITrigger.push(
        branch: 'develop',
        paths: [
          'apps/dashboard/lib/**',
          'apps/dashboard/web/**',
          'apps/dashboard/assets/**',
          'apps/dashboard/shorebird.yaml',
          'firebase/firebase.json',
          'firebase/.firebaserc',
          'packages/macos_updater/**',
          'packages/openci_shared/**',
          'packages/pubspec_version_hook/**',
          'openci/dashboard_web_hosting.dart',
          'openci/generated/**',
          '**/pubspec.yaml',
          'pubspec.lock',
          '.node-version',
        ],
      ),
    ],
    currentWorkingDirectory: 'apps/dashboard',
  );

  await ci.placeFileFromBase64(
    dir: WorkspacePaths.root.apps.dashboard.lib,
    fileName: 'firebase_options.dart',
    base64Content: Secrets.firebaseOptionsDartBase64.value,
  );
  await ci.run('flutter build web --release --no-pub');
  switch (ci.context) {
    case PullRequestContext(:final number):
      final preview = await ci.firebaseHosting.deployPreview(
        siteId: 'dashboard-openci',
        channelId: 'pr-$number',
        expiresIn: const Duration(days: 7),
        firebaseConfigPath: '../../firebase/firebase.json',
        publicDirectory: 'build/web',
        serviceAccountJsonBase64:
            Secrets.firebaseHostingServiceAccountJsonBase64.value,
      );
      await ci.pullRequest.postQrCode(
        url: preview.url,
        expiresAt: preview.expiresAt,
        lang: PostQrCodeLang.ja,
      );
    case PushContext(branch: 'develop'):
      await ci.firebaseHosting.deploy(
        siteId: 'dashboard-openci',
        firebaseConfigPath: '../../firebase/firebase.json',
        publicDirectory: 'build/web',
        serviceAccountJsonBase64:
            Secrets.firebaseHostingServiceAccountJsonBase64.value,
      );
    case PushContext() || LocalContext():
      break;
  }
}
