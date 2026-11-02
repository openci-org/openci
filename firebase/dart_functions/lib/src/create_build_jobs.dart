import 'package:openci_shared/openci_shared.dart';

import 'data_connect.dart';
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
  });
  final PlanningStore store;
  final FetchWorkflows fetchWorkflows;
  final FetchChangedFiles? fetchChangedFiles;

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
    var plan = const WorkflowPlan();
    try {
      event = PlanningEvent.parse(task.eventType, task.payload);
      if (event != null) {
        connection = await store.findConnection(event.webhook.installationId);
        if (connection != null) {
          if (connection.accountId != event.ownerId.toString()) {
            throw const InvalidPlanningInput('invalid_payload');
          }
          final files = await fetchWorkflows(event);
          final workflows = files
              .map((file) => parseOpenCIWorkflow(file.content, file.name))
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
      await store.complete(task.id, event, connection, plan);
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
