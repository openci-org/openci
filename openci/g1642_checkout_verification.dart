import 'package:openci_workflow/openci_workflow.dart';

Future<void> main() async {
  final openCI = await OpenCI.init(
    workflowName: 'G-1642 checkout verification',
    cancelPreviousRuns: true,
    ciTriggers: [
      CITrigger.pullRequest(
        branch: 'verify/g1642-merge-base-20261109',
        paths: [
          'openci/g1642_checkout_verification.dart',
          '.g1642-merge-proof',
        ],
      ),
    ],
  );

  await openCI.run('git rev-parse HEAD');
  await openCI.run(r'test "$(cat .g1642-merge-proof)" = "base-only-marker"');
}
