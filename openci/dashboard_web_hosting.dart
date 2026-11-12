import 'package:openci_workflow/openci_workflow.dart';

import 'generated/paths.g.dart';
import 'generated/secrets.g.dart';
import 'tool/deploy_hosting.dart' as hosting;

Future<void> main() async {
  final ci = await OpenCI.init(
    workflowName: 'Dashboard Web Hosting',
    flutterVersion: '3.47.8',
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
          'packages/openci_workflow/**',
          'packages/pubspec_version_hook/**',
          'openci/dashboard_web_hosting.dart',
          'openci/tool/deploy_hosting.dart',
          'openci/tool/with_node.sh',
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
          'packages/openci_workflow/**',
          'packages/pubspec_version_hook/**',
          'openci/dashboard_web_hosting.dart',
          'openci/tool/deploy_hosting.dart',
          'openci/tool/with_node.sh',
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
  await hosting.publish(
    ci,
    hosting.Site.dashboard,
    Secrets.firebaseServiceAccountJsonBase64,
  );
}
