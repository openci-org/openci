import 'package:openci_server/webhook_task/extract_commit_message_from_push_event.dart';
import 'package:test/test.dart';

void main() {
  group('extractCommitMessageFromPushEvent', () {
    test('returns message from head_commit when head_commit is present', () {
      final payload = {
        'head_commit': {
          'id': 'sha-head',
          'message': 'feat: head commit message',
        },
        'commits': [
          {
            'id': 'sha-1',
            'message': 'feat: commit 1',
          },
          {
            'id': 'sha-head',
            'message': 'feat: head commit message',
          },
        ],
      };

      final result = extractCommitMessageFromPushEvent(payload);
      expect(result, equals('feat: head commit message'));
    });

    test(
      'returns message from last commit in commits list when head_commit is null',
      () {
        final payload = {
          'head_commit': null,
          'commits': [
            {
              'id': 'sha-1',
              'message': 'feat: first commit',
            },
            {
              'id': 'sha-2',
              'message': 'feat: last commit message',
            },
          ],
        };

        final result = extractCommitMessageFromPushEvent(payload);
        expect(result, equals('feat: last commit message'));
      },
    );

    test('returns null when head_commit is null and commits list is empty', () {
      final payload = {
        'head_commit': null,
        'commits': <dynamic>[],
      };

      final result = extractCommitMessageFromPushEvent(payload);
      expect(result, isNull);
    });

    test(
      'returns null when head_commit is null and commits key is missing',
      () {
        final payload = {
          'head_commit': null,
        };

        final result = extractCommitMessageFromPushEvent(payload);
        expect(result, isNull);
      },
    );

    test('returns null when payload is empty', () {
      final payload = <String, dynamic>{};

      final result = extractCommitMessageFromPushEvent(payload);
      expect(result, isNull);
    });
  });
}
