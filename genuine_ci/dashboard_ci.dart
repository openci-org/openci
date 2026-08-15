import 'package:genuine_ci/genuine_ci.dart';

Future<void> main() async {
  final genuineCI = await GenuineCI.init(
    workflowName: 'Dashboard CI',
    githubRepositoryUrl: 'https://github.com/openci-org/openci.git',
    ciTrigger: CiTrigger.push(branch: 'develop'),
    gitClone: false,
  );

  await FlutterCi.staticAnalysis(genuineCI.workspacePath);
}
