import 'package:openci_workflow/openci_workflow.dart';

enum DashboardPatchMode {
  dryRun('--dry-run'),
  publish('--track=stable');

  const DashboardPatchMode(this.shorebirdArgument);

  final String shorebirdArgument;

  static DashboardPatchMode? forContext(WorkflowContext context) =>
      switch (context) {
        PullRequestContext() => dryRun,
        PushContext(branch: 'develop') => publish,
        PushContext() || LocalContext() => null,
      };
}
