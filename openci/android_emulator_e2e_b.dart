import 'package:openci_workflow/openci_workflow.dart';

Future<void> main() async {
  final ci = await OpenCI.init(
    workflowName: 'Android Emulator E2E B',
    machine: MachineType.linuxLatest,
    ciTriggers: [CITrigger.push(branch: 'pilot/scaleway-android-e2e-20261125')],
  );
  await ci.run('bash openci/tool/android_emulator_smoke/run.sh');
}
