import 'package:openci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';

extension DriftBuildJobMapper on DriftBuildJob {
  BuildJob toShared() {
    return BuildJob(
      id: id,
      status: status,
      owner: owner,
      repo: repo,
      workflowName: workflowName,
      teamId: teamId,
      workflowId: workflowId,
      workflowFileName: workflowFileName,
      commitSha: commitSha,
      commitMessage: commitMessage,
      pullRequestNumber: pullRequestNumber,
      runCount: runCount,
      latestRunId: latestRunId,
      tagName: tagName,
      branch: branch,
      jobKey: jobKey,
      workflowJobKey: workflowJobKey,
      matrix: matrix,
      matrixLabel: matrixLabel,
      workflowRunId: workflowRunId,
      needs: needs,
      runsOn: runsOn,
      failureSummary: failureSummary,
      failureSummaryModel: failureSummaryModel,
      failureSummaryStatus: failureSummaryStatus,
      failureSummaryDurationMs: failureSummaryDurationMs,
      provisionedUdids: provisionedUdids,
      ipaUrl: ipaUrl,
      hasIpa: hasIpa,
      bundleId: bundleId,
      ipaVersion: ipaVersion,
      appName: appName,
      githubBaseUrl: githubBaseUrl,
      vmName: vmName,
      workerHost: workerHost,
      createdAt: createdAt,
      updatedAt: updatedAt,
      completedAt: completedAt,
    );
  }
}

extension BuildJobMapper on BuildJob {
  DriftBuildJob toDrift({
    String? installationId,
    String? checkRunId,
  }) {
    return DriftBuildJob(
      id: id,
      status: status,
      owner: owner,
      repo: repo,
      workflowName: workflowName,
      teamId: teamId,
      workflowId: workflowId,
      workflowFileName: workflowFileName,
      commitSha: commitSha,
      commitMessage: commitMessage,
      pullRequestNumber: pullRequestNumber,
      runCount: runCount,
      latestRunId: latestRunId,
      tagName: tagName,
      branch: branch,
      jobKey: jobKey,
      workflowJobKey: workflowJobKey,
      matrix: matrix,
      matrixLabel: matrixLabel,
      workflowRunId: workflowRunId,
      needs: needs,
      runsOn: runsOn,
      failureSummary: failureSummary,
      failureSummaryModel: failureSummaryModel,
      failureSummaryStatus: failureSummaryStatus,
      failureSummaryDurationMs: failureSummaryDurationMs,
      provisionedUdids: provisionedUdids,
      ipaUrl: ipaUrl,
      hasIpa: hasIpa,
      bundleId: bundleId,
      ipaVersion: ipaVersion,
      appName: appName,
      githubBaseUrl: githubBaseUrl,
      vmName: vmName,
      workerHost: workerHost,
      installationId: installationId,
      checkRunId: checkRunId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      completedAt: completedAt,
    );
  }
}

List<CicdCommitGroup> groupBuildJobsToCommitGroups(List<BuildJob> jobs) {
  if (jobs.isEmpty) return [];

  final jobsByCommit = <String, List<BuildJob>>{};
  for (final job in jobs) {
    final sha = job.commitSha ?? 'unknown';
    jobsByCommit.putIfAbsent(sha, () => []).add(job);
  }

  final commitGroups = <CicdCommitGroup>[];

  for (final entry in jobsByCommit.entries) {
    final sha = entry.key;
    final commitJobs = entry.value;

    final latestCreatedAt = commitJobs
        .map((j) => j.createdAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final branch =
        commitJobs
            .firstWhere((j) => j.branch != null, orElse: () => commitJobs.first)
            .branch ??
        'unknown';
    final repo = commitJobs.first.repo;
    final owner = commitJobs.first.owner;

    final commitMessage =
        commitJobs
            .firstWhere(
              (j) => j.commitMessage != null,
              orElse: () => commitJobs.first,
            )
            .commitMessage ??
        '$owner/$repo on $branch';

    final jobsByWorkflow = <String, List<BuildJob>>{};
    for (final job in commitJobs) {
      final wfName = job.workflowFileName;
      jobsByWorkflow.putIfAbsent(wfName, () => []).add(job);
    }

    final workflows = <CicdWorkflowGroup>[];

    for (final wfEntry in jobsByWorkflow.entries) {
      final wfFileName = wfEntry.key;
      final wfJobs = wfEntry.value;

      var wfStatus = BuildJobStatus.SUCCESS;
      if (wfJobs.any(
        (j) =>
            j.status == BuildJobStatus.FAILURE ||
            j.status == BuildJobStatus.CANCELLED ||
            j.status == BuildJobStatus.TIMED_OUT,
      )) {
        wfStatus = BuildJobStatus.FAILURE;
      } else if (wfJobs.any(
        (j) =>
            j.status == BuildJobStatus.IN_PROGRESS ||
            j.status == BuildJobStatus.QUEUED ||
            j.status == BuildJobStatus.WAITING,
      )) {
        wfStatus = BuildJobStatus.IN_PROGRESS;
      }

      var maxDuration = Duration.zero;
      for (final job in wfJobs) {
        final completedAt = job.completedAt;
        if (completedAt != null) {
          final diff = completedAt.difference(job.createdAt);
          if (diff > maxDuration) maxDuration = diff;
        } else if (job.status == BuildJobStatus.IN_PROGRESS ||
            job.status == BuildJobStatus.QUEUED) {
          final diff = DateTime.now().toUtc().difference(job.createdAt);
          if (diff > maxDuration) maxDuration = diff;
        }
      }

      final stages = partitionJobsIntoStages(wfJobs);

      workflows.add(
        CicdWorkflowGroup(
          fileName: wfFileName,
          status: wfStatus,
          duration: maxDuration,
          stages: stages,
        ),
      );
    }

    var commitStatus = BuildJobStatus.SUCCESS;
    if (workflows.any((w) => w.status == BuildJobStatus.FAILURE)) {
      commitStatus = BuildJobStatus.FAILURE;
    } else if (workflows.any((w) => w.status == BuildJobStatus.IN_PROGRESS)) {
      commitStatus = BuildJobStatus.IN_PROGRESS;
    }

    commitGroups.add(
      CicdCommitGroup(
        branch: branch,
        commitSha: sha,
        commitMessage: commitMessage,
        status: commitStatus,
        createdAt: latestCreatedAt,
        workflows: workflows,
      ),
    );
  }

  commitGroups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return commitGroups;
}

List<List<CicdJobGroup>> partitionJobsIntoStages(List<BuildJob> jobs) {
  final jobMap = {for (final j in jobs) j.jobKey ?? j.id: j};

  final stages = <List<CicdJobGroup>>[];
  final processedKeys = <String>{};

  while (processedKeys.length < jobs.length) {
    final currentStage = <CicdJobGroup>[];

    for (final job in jobs) {
      final key = job.jobKey ?? job.id;
      if (processedKeys.contains(key)) continue;

      final needs = job.needs ?? [];
      final needsMet = needs.every((need) {
        if (!jobMap.containsKey(need)) return true;
        return processedKeys.contains(need);
      });

      if (needsMet) {
        currentStage.add(
          CicdJobGroup(
            id: job.id,
            label: job.displayMatrixLabel ?? job.jobKey ?? job.id,
            status: job.status,
          ),
        );
      }
    }

    if (currentStage.isEmpty) {
      final remainingJobs = <CicdJobGroup>[];
      for (final job in jobs) {
        final key = job.jobKey ?? job.id;
        if (!processedKeys.contains(key)) {
          remainingJobs.add(
            CicdJobGroup(
              id: job.id,
              label: job.displayMatrixLabel ?? job.jobKey ?? job.id,
              status: job.status,
            ),
          );
        }
      }
      if (remainingJobs.isNotEmpty) {
        stages.add(remainingJobs);
      }
      break;
    }

    stages.add(currentStage);
    processedKeys.addAll(
      currentStage.map((j) {
        final originalJob = jobs.firstWhere((oj) => oj.id == j.id);
        return originalJob.jobKey ?? originalJob.id;
      }),
    );
  }

  return stages;
}
