import 'package:genuine_ci/genuine_ci.dart';

Future<void> main() async {
  final genuineCI = await GenuineCI.init(
    workflowName: 'Dashboard CI',
    ciTrigger: CiTrigger.pullRequest(branch: 'develop'),
  );

  await FlutterCi.staticAnalysis(genuineCI.workspacePath);
}
