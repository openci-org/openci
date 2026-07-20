import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/build_job/build_job_mapper.dart';
import 'package:openci_server/request/error_handler.dart';
import 'package:openci_shared/openci_shared.dart';

FutureOr<Response> onRequest(RequestContext context) {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  return _get(context);
}

Future<Response> _get(RequestContext context) async {
  try {
    final db = context.read<AppDatabase>();
    final uid = context.read<String?>();

    if (uid == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'success': false, 'error': 'Authentication required'},
      );
    }

    final queryParams = context.request.uri.queryParameters;
    final teamId = queryParams['teamId'];
    if (teamId == null || teamId.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'Missing teamId parameter'},
      );
    }

    final isMember = await db.teamDao.isTeamMember(uid, teamId);
    if (!isMember) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'success': false, 'error': 'Forbidden'},
      );
    }

    final limitParam = queryParams['limit'];
    final parsedLimit = limitParam == null ? 100 : int.tryParse(limitParam);
    final limit = (parsedLimit == null || parsedLimit < 1) ? 100 : parsedLimit;

    final driftJobs = await db.buildJobDao.getBuildJobsForTeam(
      teamId: teamId,
      limit: limit,
    );

    final jobs = driftJobs.map((j) => j.toShared()).toList();

    final commitGroups = groupBuildJobsToCommitGroups(jobs);

    return Response.json(
      body: commitGroups.map((g) => g.toJson()).toList(),
    );
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to get commit groups',
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
      final wfName = job.workflowFileName ?? job.workflowName;
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
