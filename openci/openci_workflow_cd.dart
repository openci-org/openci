import 'package:openci_workflow/openci_workflow.dart';

import 'generated/paths.g.dart';
import 'generated/secrets.g.dart';

Future<void> main() async {
  final ci = await OpenCI.init(
    workflowName: 'OpenCI Workflow CD',
    ciTriggers: [
      CITrigger.push(
        branch: 'develop',
        paths: [
          'packages/openci_workflow/pubspec.yaml',
          'packages/openci_workflow/CHANGELOG.md',
        ],
      ),
    ],
    currentWorkingDirectory: WorkspacePaths.root.packages.openciWorkflow,
  );

  await ci.dart.publishToPubDev(
    serviceAccountJsonBase64: Secrets.pubDevServiceAccountJsonBase64.value,
    skipIfPublished: true,
  );
}
