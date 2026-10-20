import 'package:openci_workflow/openci_workflow.dart';

Future<void> main() async {
  final openCI = await OpenCI.init(
    workflowName: 'GenuineCI Server CI',
    ciTriggers: [
      CITrigger.pullRequest(branch: '*'),
      CITrigger.push(branch: 'develop'),
    ],
    currentWorkingDirectory: 'apps/genuineci_server',
  );

  await openCI.run('command -v go >/dev/null || brew install go');
  await openCI.run('go vet ./...');
  await openCI.run('go test -v ./...');
}
