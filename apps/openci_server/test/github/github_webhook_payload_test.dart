import 'package:openci_server/github/github_webhook_payload.dart';
import 'package:test/test.dart';

void main() {
  group('GitHubWebhookPayload', () {
    test('parses push event payload correctly', () {
      final rawJson = {
        'ref': 'refs/heads/main',
        'head_commit': {
          'id': 'abc1234567890',
          'message': 'feat: awesome new feature\n\nMore details',
        },
        'repository': {
          'name': 'openci',
          'owner': {'login': 'openci-org'},
        },
        'installation': {'id': 998877},
        'deleted': false,
      };

      final payload = GitHubWebhookPayload.fromRawJson(
        eventType: 'push',
        rawJson: rawJson,
      );

      expect(payload.installationId, equals(998877));
      expect(payload.eventType, equals('push'));
      expect(payload.owner, equals('openci-org'));
      expect(payload.repo, equals('openci'));
      expect(payload.commitSha, equals('abc1234567890'));
      expect(payload.branch, equals('main'));
      expect(payload.triggerBranch, equals('main'));
      expect(payload.triggerType, equals('push'));
      expect(payload.commitMessage, equals('feat: awesome new feature'));
      expect(payload.isDeleted, isFalse);
    });

    test('parses pull_request event payload correctly', () {
      final rawJson = {
        'number': 42,
        'pull_request': {
          'title': 'Add new features',
          'head': {
            'sha': 'def987654321',
            'ref': 'feature/new-feature',
          },
          'base': {
            'ref': 'main',
          },
        },
        'repository': {
          'name': 'openci',
          'owner': {'login': 'openci-org'},
        },
        'installation': {'id': 998877},
      };

      final payload = GitHubWebhookPayload.fromRawJson(
        eventType: 'pull_request',
        rawJson: rawJson,
      );

      expect(payload.installationId, equals(998877));
      expect(payload.eventType, equals('pull_request'));
      expect(payload.owner, equals('openci-org'));
      expect(payload.repo, equals('openci'));
      expect(payload.commitSha, equals('def987654321'));
      expect(payload.branch, equals('feature/new-feature'));
      expect(payload.triggerBranch, equals('main'));
      expect(payload.triggerType, equals('pull_request'));
      expect(payload.pullRequestNumber, equals(42));
      expect(payload.commitMessage, equals('Add new features'));
      expect(payload.isDeleted, isFalse);
    });
  });
}
