import 'package:openci_shared/openci_shared.dart';

import 'github_webhook_payload.dart';
import 'open_ci_parser.dart';

class SkippedWorkflow {
  const SkippedWorkflow(this.workflowName, this.workflowFileName);
  final String workflowName;
  final String workflowFileName;
}

/// A durable planning decision; skipped workflows never become build jobs.
class WorkflowPlan {
  const WorkflowPlan({
    this.jobs = const [],
    this.skipped = const [],
    this.pathFilterReason,
    this.comparisonBaseSha,
    this.autoCancelWorkflowFiles = const {},
  });
  final List<BuildJobPlan> jobs;
  final List<SkippedWorkflow> skipped;
  final String? pathFilterReason;
  final String? comparisonBaseSha;
  final Set<String> autoCancelWorkflowFiles;

  WorkflowPlan withoutSupersededJobs() => WorkflowPlan(
    jobs: jobs
        .where((job) => !autoCancelWorkflowFiles.contains(job.workflowFileName))
        .toList(),
    skipped: skipped,
    pathFilterReason: pathFilterReason,
    comparisonBaseSha: comparisonBaseSha,
  );
}

Iterable<ParsedCITrigger> matchingTriggers(
  ParsedWorkflow workflow,
  GitHubWebhookPayload event,
) => workflow.ciTriggers.where(
  (trigger) => trigger.matches(
    eventType: event.triggerType,
    branch: event.triggerBranch,
  ),
);

/// An unfiltered matching trigger already runs its workflow without an API call.
bool needsChangedFiles(
  Iterable<ParsedWorkflow> workflows,
  GitHubWebhookPayload event,
) => workflows.any((workflow) {
  final triggers = matchingTriggers(workflow, event).toList();
  return triggers.isNotEmpty &&
      triggers.every((trigger) => trigger.paths != null);
});

WorkflowPlan planJobs({
  required GitHubWebhookPayload event,
  required String teamId,
  required Iterable<ParsedWorkflow> workflows,
  ChangedFilesResult? changedFiles,
}) {
  final jobs = <BuildJobPlan>[];
  final skipped = <SkippedWorkflow>[];
  final autoCancelWorkflowFiles = <String>{};
  String? fallback;
  // A complete result for another revision is never safe to use.
  final complete =
      changedFiles?.isComplete == true &&
      changedFiles?.baseSha != null &&
      changedFiles?.headSha == event.commitSha;
  for (final workflow in workflows) {
    final triggers = matchingTriggers(workflow, event).toList();
    if (triggers.isEmpty) continue;
    final filtered = triggers.every((trigger) => trigger.paths != null);
    if (filtered && complete) {
      if (!triggers.any(
        (trigger) => trigger.matchesChangedFiles(changedFiles!.paths),
      )) {
        skipped.add(
          SkippedWorkflow(workflow.workflowName, workflow.workflowFileName),
        );
        continue;
      }
    } else if (filtered) {
      fallback = changedFiles?.reason ?? 'changed_files_unavailable';
    }
    if (event.pullRequestNumber != null && workflow.cancelPreviousRuns) {
      autoCancelWorkflowFiles.add(workflow.workflowFileName);
    }
    jobs.add(
      BuildJobPlan(
        owner: event.owner,
        repo: event.repo,
        workflowName: workflow.workflowName,
        workflowFileName: workflow.workflowFileName,
        flutterVersion: workflow.flutterVersion,
        teamId: teamId,
        commitSha: event.commitSha,
        commitMessage: event.commitMessage,
        pullRequestNumber: event.pullRequestNumber,
        branch: event.branch,
        runsOn: 'macos-latest',
        installationId: event.installationId.toString(),
      ),
    );
  }
  return WorkflowPlan(
    jobs: jobs,
    skipped: skipped,
    pathFilterReason: fallback,
    comparisonBaseSha: changedFiles?.baseSha,
    autoCancelWorkflowFiles: autoCancelWorkflowFiles,
  );
}
