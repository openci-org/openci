import 'package:openci_workflow/openci_workflow.dart';

import 'generated/secrets.g.dart';

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
          'openci/tool/with_node.sh',
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
          'openci/tool/with_node.sh',
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
  switch (openCI.context) {
    case PullRequestContext(:final number):
      final preview = await openCI.firebaseHosting.deployPreview(
        siteId: 'openci-b1b91',
        channelId: 'pr-$number',
        expiresIn: const Duration(days: 7),
        firebaseConfigPath: 'firebase.json',
        serviceAccountJsonBase64:
            Secrets.firebaseHostingServiceAccountJsonBase64.value,
      );
      await openCI.pullRequest.postQrCode(
        url: preview.url,
        expiresAt: preview.expiresAt,
        lang: PostQrCodeLang.ja,
      );
    case PushContext(branch: 'develop'):
      await openCI.firebaseHosting.deploy(
        siteId: 'openci-b1b91',
        firebaseConfigPath: 'firebase.json',
        serviceAccountJsonBase64:
            Secrets.firebaseHostingServiceAccountJsonBase64.value,
      );
    case PushContext() || LocalContext():
      break;
  }
}
