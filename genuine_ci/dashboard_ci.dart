import 'package:genuine_ci/genuine_ci.dart';

Future<void> main() async {
  final genuineCI = await GenuineCI.init(
    workflowName: 'Dashboard CI',
    triggerBranch: 'develop',
    push: true,
    pullRequest: true,
    machine: 'macos-latest',
    githubRepositoryUrl: 'https://github.com/openci-org/openci.git',
  );

  await genuineCI.run('pwd');
  await genuineCI.run('git log -1 --oneline');
  await genuineCI.run('ls', workingDirectory: 'apps/dashboard');
}
