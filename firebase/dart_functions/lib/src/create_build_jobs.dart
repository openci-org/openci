import 'package:openci_shared/openci_shared.dart';

import 'data_connect.dart';
import 'open_ci_parser.dart';
import 'plan_jobs.dart';
import 'planning_event.dart';

typedef FetchWorkflows = Future<List<OpenCIFile>> Function(PlanningEvent event);

class BuildJobPlanner {
  const BuildJobPlanner({required this.store, required this.fetchWorkflows});
  final PlanningStore store;
  final FetchWorkflows fetchWorkflows;

  Future<String> process(String taskId) async {
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
    var jobs = <BuildJobPlan>[];
    try {
      event = PlanningEvent.parse(task.eventType, task.payload);
      if (event != null) {
        connection = await store.findConnection(event.webhook.installationId);
        if (connection != null) {
          if (connection.accountId != event.ownerId.toString()) {
            throw const InvalidPlanningInput('invalid_payload');
          }
          final files = await fetchWorkflows(event);
          jobs = planJobs(
            event: event.webhook,
            teamId: connection.teamId,
            files: files,
          );
          if (jobs.length > 100 ||
              jobs.map((job) => job.workflowFileName).toSet().length !=
                  jobs.length ||
              jobs.any((job) => job.workflowName.trim().isEmpty)) {
            throw const InvalidPlanningInput('invalid_workflow');
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
    try {
      await store.complete(task.id, event, connection, jobs);
      return 'created';
    } catch (_) {
      // Another consumer may have committed, or only the response was lost.
      if ((await store.getTask(task.id))?.status == 'completed') {
        return 'duplicate';
      }
      rethrow;
    }
  }
}
