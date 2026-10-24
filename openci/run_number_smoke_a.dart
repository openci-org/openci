import 'package:openci_workflow/openci_workflow.dart';

import 'run_number_smoke_probe.dart';

Future<void> main() async {
  final openCI = await OpenCI.init(
    workflowName: 'Run number smoke A',
    ciTriggers: [CITrigger.push(branch: 'test/g-1538-run-number-smoke')],
  );
  await verifyRunNumber(openCI);
}
