import '../util/logger.dart';
import 'build_trigger.dart';
import 'sync_workflow_files.dart';
import 'update_worker_cli_version.dart';
import 'webhook_event.dart';

Future<void> routeWebhookEvent(WebhookEvent event) async {
  switch (event.event) {
    case GitHubEventType.pullRequest:
      await _onPullRequest(event);
    case GitHubEventType.push:
      await _onPush(event);
    case GitHubEventType.create:
      await _onCreate(event);
    case GitHubEventType.release:
      await _onRelease(event);
    case GitHubEventType.issueComment:
      await _onIssueComment(event);
    case GitHubEventType.unknown:
      break;
  }
}

Future<void> _onPullRequest(WebhookEvent event) async {
  if (event.action != WebhookAction.opened &&
      event.action != WebhookAction.synchronize) {
    return;
  }

  logInfo('PR ${event.action}', {'repo': event.repository?.fullName});
  await handleBuildTrigger(event);
}

Future<void> _onPush(WebhookEvent event) async {
  final ref = event.ref ?? '';
  if (ref.startsWith('refs/tags/')) {
    logInfo('Skipping push for tag', {'ref': ref});
    return;
  }

  logInfo('Push', {'ref': ref, 'repo': event.repository?.fullName});
  await handleBuildTrigger(event);

  final repo = event.repository;
  final installationId = event.installation?.id;
  if (repo != null && installationId != null) {
    await syncWorkflowFiles(
      repository: repo.fullName,
      branch: ref.replaceFirst('refs/heads/', ''),
      installationId: installationId,
    );
  }
}

Future<void> _onCreate(WebhookEvent event) async {
  if (event.refType != 'tag') return;

  logInfo('Tag created', {'ref': event.ref});
  await handleBuildTrigger(event);
}

Future<void> _onRelease(WebhookEvent event) async {
  if (event.action != WebhookAction.published) return;

  logInfo('Release published', {'tag': event.release?.tagName});
  await handleBuildTrigger(event);
  await updateWorkerCliVersion(event);
}

Future<void> _onIssueComment(WebhookEvent event) async {
  if (event.action != WebhookAction.created) return;

  final commentBody = event.comment?.body ?? '';
  if (commentBody.contains('@openci rerun')) {
    logInfo('Rerun requested via comment');
  }
}
