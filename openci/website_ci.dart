import 'package:openci_workflow/openci_workflow.dart';

import 'generated/secrets.g.dart';
import 'tool/deploy_hosting.dart' as hosting;

Future<void> main() async {
  final openCI = await OpenCI.init(
    workflowName: 'Website CI',
    cancelPreviousRuns: true,
    ciTriggers: [
      CITrigger.pullRequest(
        branch: '*',
        paths: [
          'apps/website/**',
          'apps/landing_page/**',
          'package.json',
          'package-lock.json',
          'vite.config.mts',
          '.node-version',
          'openci/website_ci.dart',
          'openci/tool/deploy_hosting.dart',
          'openci/tool/with_node.sh',
          'packages/openci_workflow/**',
          'packages/pubspec_version_hook/**',
          'openci/generated/**',
          '**/pubspec.yaml',
          'pubspec.lock',
          '.fvmrc',
        ],
      ),
      CITrigger.push(
        branch: 'develop',
        paths: [
          'apps/website/**',
          'apps/landing_page/**',
          'package.json',
          'package-lock.json',
          'vite.config.mts',
          '.node-version',
          'openci/website_ci.dart',
          'openci/tool/deploy_hosting.dart',
          'openci/tool/with_node.sh',
          'packages/openci_workflow/**',
          'packages/pubspec_version_hook/**',
          'openci/generated/**',
          '**/pubspec.yaml',
          'pubspec.lock',
          '.fvmrc',
        ],
      ),
    ],
    currentWorkingDirectory: 'apps/website',
  );

  // Bootstrap the pinned runtime; CI VMs may not have Node.js/npm installed.
  await openCI.run('bash scripts/ci.sh');
  await hosting.publish(
    openCI,
    hosting.Site.website,
    Secrets.firebaseHostingServiceAccountJsonBase64,
  );
}
