import 'package:genuine_ci/genuine_ci.dart';

Future<void> main() async {
  final genuineCI = await GenuineCI.init(
    workflowName: 'Dashboard CI',
    triggerBranch: 'develop',
    push: true,
    pullRequest: true,
    machine: MachineType.macOsLatest,
    githubRepositoryUrl: 'https://github.com/openci-org/openci.git',
    gitClone: false,
  );

  await genuineCI.run('echo "Hello World"');
}
