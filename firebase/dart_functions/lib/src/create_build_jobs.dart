import 'package:openci_shared/openci_shared.dart';

import 'data_connect.dart';
import 'github_workflows.dart';
import 'open_ci_parser.dart';
import 'plan_jobs.dart';
import 'planning_event.dart';

typedef FetchWorkflows = Future<List<OpenCIFile>> Function(PlanningEvent event);
typedef FetchChangedFiles =
    Future<ChangedFilesResult> Function(PlanningEvent event);

class BuildJobPlanner {
  const BuildJobPlanner({
    required this.store,
    required this.fetchWorkflows,
    this.fetchChangedFiles,
    this.observePullRequest,
    this.resolveReleaseCommit,
  });
  final PlanningStore store;
  final FetchWorkflows fetchWorkflows;
  final FetchChangedFiles? fetchChangedFiles;
  final Future<PullRequestObservation> Function(PlanningEvent event)?
  observePullRequest;
  final Future<String> Function(PlanningEvent event)? resolveReleaseCommit;

  Future<String> process(String taskId) async {
    String? revalidationBase;
    for (var attempt = 0; ; attempt++) {
      try {
        return await _processOnce(
          taskId,
          retryingConflict: attempt > 0,
          revalidationBase: revalidationBase,
        );
      } on PlanningObservationSuperseded catch (change) {
        // Sustained contention still falls back to durable event redelivery.
        if (attempt >= 2) rethrow;
        revalidationBase = change.baseSha ?? revalidationBase;
      }
    }
  }

  Future<String> _processOnce(
    String taskId, {
    required bool retryingConflict,
    required String? revalidationBase,
  }) async {
    final task = await store.getTask(taskId);
    if (task == null) throw StateError('Webhook task not found');
    if (task.status == 'completed' || task.status == 'failed') {
      return 'duplicate';
    }
    if (task.status != 'pending') {
      throw StateError('Webhook task is not pending');
    }
    PlanningEvent? event;
    PlanningConnection? connection;
    PlanningFence? fence;
    var plan = const WorkflowPlan();
    try {
      event = PlanningEvent.parse(task.eventType, task.payload);
      if (event != null) {
        if (revalidationBase != null) {
          event = event.withRevalidationBase(revalidationBase);
        }
        connection = await store.findConnection(
          event.webhook.installationId,
          event.repositoryId,
        );
        if (connection != null) {
          if (event.isBaseRevalidation &&
              event.revalidationTeamId != connection.teamId) {
            return await _completeTask(task.id);
          }
          if (connection.accountId != event.ownerId.toString()) {
            throw const InvalidPlanningInput('invalid_payload');
          }
          if (event.isRelease) {
            final resolve = resolveReleaseCommit;
            if (resolve == null) {
              throw StateError('Release tag resolution is unavailable');
            }
            event = event.withReleaseCommit(await resolve(event));
          }
          if (event.webhook.pullRequestNumber != null) {
            if (retryingConflict &&
                await _observePullRequest(event) ==
                    PullRequestObservation.stale) {
              // Retire this delivery without displacing the current planner.
              return await _completeTask(task.id);
            }
            fence = await store.beginPullRequestPlanning(
              task.id,
              event,
              connection,
            );
          }
          // Close notifications need neither workflow source nor commit access.
          final files = event.isPullRequestClosed
              ? <OpenCIFile>[]
              : await fetchWorkflows(event);
          final workflows = files
              .map(
                (file) => parseOpenCIWorkflow(
                  file.content,
                  file.path.substring('openci/'.length),
                ),
              )
              .whereType<ParsedWorkflow>()
              .toList();
          if (workflows.length > 100 ||
              workflows.map((w) => w.workflowFileName).toSet().length !=
                  workflows.length ||
              workflows.any((w) => w.workflowName.trim().isEmpty)) {
            throw const InvalidPlanningInput('invalid_workflow');
          }
          final changedFiles = needsChangedFiles(workflows, event.webhook)
              ? await fetchChangedFiles?.call(event)
              : null;
          plan = planJobs(
            event: event.webhook,
            teamId: connection.teamId,
            workflows: workflows,
            changedFiles: changedFiles,
          );
          if (event.webhook.pullRequestNumber != null) {
            final observation = await _observePullRequest(event);
            if (observation == PullRequestObservation.closed) {
              plan = const WorkflowPlan(cancelClosedPullRequest: true);
            } else if (observation == PullRequestObservation.stale) {
              plan = const WorkflowPlan();
            }
          }
        }
      }
    } on InvalidPlanningInput catch (error) {
      await store.reject(task.id, error.reason);
      return 'failed';
    } on WorkflowConfigurationException {
      await store.reject(task.id, 'invalid_workflow');
      return 'failed';
    }
    return _completeTask(
      task.id,
      event: event,
      connection: connection,
      plan: plan,
      fence: fence,
    );
  }

  Future<PullRequestObservation> _observePullRequest(PlanningEvent event) {
    final verify = observePullRequest;
    if (verify == null) throw StateError('PR head verification is unavailable');
    return verify(event);
  }

  Future<String> _completeTask(
    String taskId, {
    PlanningEvent? event,
    PlanningConnection? connection,
    WorkflowPlan plan = const WorkflowPlan(),
    PlanningFence? fence,
  }) async {
    try {
      await store.complete(taskId, event, connection, plan, fence: fence);
      return 'created';
    } catch (_) {
      // Another consumer may have committed, or only the response was lost.
      if ((await store.getTask(taskId))?.status == 'completed') {
        return 'duplicate';
      }
      rethrow;
    }
  }
}
