import 'package:openci_server/build_job/build_job_mapper.dart';
import 'package:openci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';

extension BuildJobPlanMapper on BuildJobPlan {
  DriftBuildJob toDriftBuildJob({
    required String id,
    required DateTime timestamp,
  }) {
    return BuildJob(
      id: id,
      status: BuildJobStatus.QUEUED,
      owner: owner,
      repo: repo,
      workflowName: workflowName,
      workflowFileName: workflowFileName,
      teamId: teamId,
      workflowId: workflowId,
      commitSha: commitSha,
      commitMessage: commitMessage,
      pullRequestNumber: pullRequestNumber,
      runCount: 0,
      tagName: tagName,
      branch: branch,
      jobKey: jobKey,
      workflowJobKey: workflowJobKey,
      matrix: matrix,
      matrixLabel: matrixLabel,
      workflowRunId: workflowRunId,
      needs: needs,
      runsOn: runsOn,
      githubBaseUrl: githubBaseUrl,
      createdAt: timestamp,
      updatedAt: timestamp,
    ).toDrift(installationId: installationId);
  }
}
