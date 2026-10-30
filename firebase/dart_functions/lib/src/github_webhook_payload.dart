import 'package:freezed_annotation/freezed_annotation.dart';

part 'github_webhook_payload.freezed.dart';

@freezed
abstract class GitHubWebhookPayload with _$GitHubWebhookPayload {
  const factory GitHubWebhookPayload({
    required int installationId,
    required String eventType,
    required String owner,
    required String repo,
    required String commitSha,
    required String branch,
    required String triggerBranch,
    required String triggerType,
    int? pullRequestNumber,
    String? commitMessage,
    @Default(false) bool isDeleted,
  }) = _GitHubWebhookPayload;

  factory GitHubWebhookPayload.fromRawJson({
    required String eventType,
    required Map<String, dynamic> rawJson,
  }) {
    final installation = rawJson['installation'] as Map<String, dynamic>?;
    if (installation == null || installation['id'] == null) {
      throw const FormatException('Missing installation ID in webhook payload');
    }
    final installationId = installation['id'] as int;

    if (eventType == 'pull_request') {
      final pr = rawJson['pull_request'] as Map<String, dynamic>?;
      final repoMap = rawJson['repository'] as Map<String, dynamic>?;
      if (pr == null || repoMap == null) {
        throw const FormatException(
          'Missing pull_request or repository data in payload',
        );
      }

      final owner = (repoMap['owner']?['login'] as String?) ?? '';
      final repo = (repoMap['name'] as String?) ?? '';
      final commitSha = (pr['head']?['sha'] as String?) ?? '';
      final branch = (pr['head']?['ref'] as String?) ?? '';
      final triggerBranch = (pr['base']?['ref'] as String?) ?? '';
      final pullRequestNumber = rawJson['number'] as int?;
      final commitMessage = pr['title'] as String?;

      return GitHubWebhookPayload(
        installationId: installationId,
        eventType: eventType,
        owner: owner,
        repo: repo,
        commitSha: commitSha,
        branch: branch,
        triggerBranch: triggerBranch,
        triggerType: 'pull_request',
        pullRequestNumber: pullRequestNumber,
        commitMessage: commitMessage,
      );
    } else {
      // push event
      final isDeleted = rawJson['deleted'] == true;
      final repoMap = rawJson['repository'] as Map<String, dynamic>?;
      if (repoMap == null) {
        throw const FormatException(
          'Missing repository data in push webhook payload',
        );
      }

      final owner = (repoMap['owner']?['login'] as String?) ?? '';
      final repo = (repoMap['name'] as String?) ?? '';
      final commitSha =
          ((rawJson['head_commit']?['id'] ?? rawJson['after']) as String?) ??
          '';
      final ref = (rawJson['ref'] as String?) ?? '';
      final branch = ref.startsWith('refs/heads/') ? ref.substring(11) : ref;
      final commitMessage = (rawJson['head_commit']?['message'] as String?)
          ?.split('\n')
          .first;

      return GitHubWebhookPayload(
        installationId: installationId,
        eventType: eventType,
        owner: owner,
        repo: repo,
        commitSha: commitSha,
        branch: branch,
        triggerBranch: branch,
        triggerType: 'push',
        pullRequestNumber: null,
        commitMessage: commitMessage,
        isDeleted: isDeleted,
      );
    }
  }
}
