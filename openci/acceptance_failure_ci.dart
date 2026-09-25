import 'package:openci_workflow/openci_workflow.dart';

Future<void> main() async {
  final openCI = await OpenCI.init(
    workflowName: 'Release acceptance: expected failure (#2946)',
    ciTriggers: [
      CITrigger.push(branch: 'verify/2946-failure-reporting'),
    ],
  );

  await openCI.run('echo OPENCI_2946_BEFORE_EXPECTED_FAILURE');
  await openCI.run('exit 42');
  await openCI.run('echo OPENCI_2946_MUST_NOT_RUN');
}
