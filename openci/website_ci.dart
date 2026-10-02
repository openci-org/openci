import 'package:openci_workflow/openci_workflow.dart';

Future<void> main() async {
  final openCI = await OpenCI.init(
    workflowName: 'Website CI',
    ciTriggers: [
      CITrigger.pullRequest(branch: 'develop'),
      CITrigger.push(branch: 'develop'),
    ],
    // This app resolves its Jaspr dependencies outside the root Pub workspace.
    currentWorkingDirectory: 'apps/website',
  );

  await openCI.run('dart pub get --enforce-lockfile');
  await openCI.run('dart format --output=none --set-exit-if-changed lib test');
  await openCI.run('dart analyze --fatal-infos');
  await openCI.run('dart run jaspr_cli:jaspr build --port 62841');
  await openCI.run('dart test');
}
