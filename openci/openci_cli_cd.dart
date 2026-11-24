import 'package:openci_workflow/openci_workflow.dart';

import 'generated/paths.g.dart';
import 'generated/secrets.g.dart';

Future<void> main() async {
  final ci = await OpenCI.init(
    workflowName: 'OpenCI CLI CD',
    flutterVersion: FlutterVersion.v3_47_8.value,
    ciTriggers: [
      CITrigger.push(
        branch: 'develop',
        paths: [
          'apps/openci_cli/pubspec.yaml',
          'apps/openci_cli/CHANGELOG.md',
          'openci/openci_cli_cd.dart',
        ],
      ),
    ],
    currentWorkingDirectory: WorkspacePaths.root.apps.openciCli,
  );

  await ci.dart.analyze();
  await ci.dart.test();
  await ci.dart.publishToPubDev(
    serviceAccountJsonBase64: Secrets.pubDevServiceAccountJsonBase64.value,
    skipIfPublished: true,
  );
}
