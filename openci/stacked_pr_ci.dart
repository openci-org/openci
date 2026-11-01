import 'package:openci_workflow/openci_workflow.dart';

Future<void> main() async {
  final openCI = await OpenCI.init(
    workflowName: 'Stacked PR CI',
    ciTriggers: [
      CITrigger.pullRequest(branch: '*'),
      CITrigger.push(branch: 'develop'),
    ],
    currentWorkingDirectory: 'apps/stacked_pr',
  );

  await openCI.run('dart pub get --enforce-lockfile');
  await openCI.run(
    'dart format --output=none --set-exit-if-changed lib bin test integration_test',
  );
  await openCI.run('dart analyze --fatal-infos');
  await openCI.run('dart test test integration_test --concurrency=1');
}
