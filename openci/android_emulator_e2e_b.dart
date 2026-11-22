import 'package:openci_workflow/openci_workflow.dart';

Future<void> main() async {
  final ci = await OpenCI.init(
    workflowName: 'Android Emulator E2E B',
    machine: MachineType.linuxLatest,
    ciTriggers: [CITrigger.push(branch: 'pilot/android-emulator-linux')],
  );
  await ci.run('/usr/local/bin/openci-android-smoke');
}
