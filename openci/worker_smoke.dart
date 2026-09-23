import 'package:openci_workflow/openci_workflow.dart';

import 'paths.g.dart';

Future<void> main() async {
  final openCI = await OpenCI.init(
    workflowName: 'Build job worker smoke',
    ciTriggers: [CITrigger.push(branch: 'test/build-job-worker-smoke-openci')],
  );

  await openCI.run('sw_vers');
  await openCI.run('flutter --version');
  await openCI.run(
    'dart test --reporter=expanded',
    workingDirectory: WorkspacePaths.root.apps.buildJobWorker,
  );
}
