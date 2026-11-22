export const workflowCode = [
  `import 'package:openci_workflow/openci_workflow.dart';

Future<void> main() async {
  final ci = await OpenCI.init(
    workflowName: 'Flutter CI',
    ciTriggers: [CITrigger.pullRequest(branch: 'main')],
  );

  await ci.run('flutter pub get');
  await ci.flutter.staticAnalysis();
  await ci.flutter.unitTests();
}`,
  `import 'package:openci_workflow/openci_workflow.dart';

Future<void> main() async {
  final ci = await OpenCI.init(
    workflowName: 'Android build',
    ciTriggers: [CITrigger.push(branch: 'main')],
  );

  await ci.flutter.buildApk(flavor: 'staging');
  await ci.flutter.buildAab();
}`,
  `import 'package:openci_workflow/openci_workflow.dart';

Future<void> uploadBuild(
  OpenCI ci,
  String ipaPath,
  AppStoreConnectKeys ascKeys,
) async {
  await ci.flutter.deployIpaToTestFlight(
    ipaPath: ipaPath,
    ascKeys: ascKeys,
  );
}`,
];
