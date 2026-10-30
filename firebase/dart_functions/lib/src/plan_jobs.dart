import 'package:openci_shared/openci_shared.dart';

import 'github_webhook_payload.dart';
import 'open_ci_parser.dart';

/// Builds job plans from workflow definitions matching the webhook event.
List<BuildJobPlan> planJobs({
  required GitHubWebhookPayload event,
  required String teamId,
  required Iterable<OpenCIFile> files,
}) => files
    .map((file) => parseOpenCIWorkflow(file.content, file.name))
    .whereType<ParsedWorkflow>()
    .where(
      (workflow) => workflow.matches(
        eventType: event.triggerType,
        branch: event.triggerBranch,
      ),
    )
    .map(
      (workflow) => BuildJobPlan(
        owner: event.owner,
        repo: event.repo,
        workflowName: workflow.workflowName,
        workflowFileName: workflow.workflowFileName,
        teamId: teamId,
        commitSha: event.commitSha,
        commitMessage: event.commitMessage,
        pullRequestNumber: event.pullRequestNumber,
        branch: event.branch,
        runsOn: 'macos-latest',
        installationId: event.installationId.toString(),
      ),
    )
    .toList();
