import 'package:dashboard/issues/issue_board_ima_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldSpinCardBuildStatus', () {
    test('does not spin when any current CI job failed', () {
      expect(
        shouldSpinCardBuildStatus(failed: 1, active: 1, queuedOnly: false),
        isFalse,
      );
    });

    test('spins while non-queued jobs are still running', () {
      expect(
        shouldSpinCardBuildStatus(failed: 0, active: 1, queuedOnly: false),
        isTrue,
      );
    });

    test('does not spin for queued-only jobs', () {
      expect(
        shouldSpinCardBuildStatus(failed: 0, active: 1, queuedOnly: true),
        isFalse,
      );
    });
  });

  group('IssuePullRequestDiff', () {
    test('parses changed files and truncation flags', () {
      final diff = IssuePullRequestDiff.fromMap({
        'repository': 'openci-org/openci',
        'pullRequestNumber': 1956,
        'title': 'Show pull request diff',
        'url': 'https://github.com/openci-org/openci/pull/1956',
        'state': 'open',
        'merged': false,
        'branch': 'IMA-391',
        'additions': 12,
        'deletions': 3,
        'changedFiles': 1,
        'filesTruncated': true,
        'files': [
          {
            'filename': 'lib/issues/issue_board_ima_issue_editor.dart',
            'status': 'modified',
            'additions': 12,
            'deletions': 3,
            'changes': 15,
            'patch': '@@ -1 +1 @@',
            'patchTruncated': true,
            'blobUrl':
                'https://github.com/openci-org/openci/blob/main/file.dart',
            'rawUrl': 'https://github.com/openci-org/openci/raw/main/file.dart',
          },
        ],
      });

      expect(diff.repository, 'openci-org/openci');
      expect(diff.pullRequestNumber, 1956);
      expect(diff.filesTruncated, isTrue);
      expect(diff.files.single.patchTruncated, isTrue);
      expect(diff.files.single.additions, 12);
    });

    test('expands small textual diffs by default', () {
      const file = IssuePullRequestDiffFile(
        filename: 'lib/main.dart',
        status: 'modified',
        additions: 2,
        deletions: 1,
        changes: 3,
        patch: '@@ -1 +1 @@',
        patchTruncated: false,
        blobUrl: '',
        rawUrl: '',
      );

      expect(diffFileInitiallyExpanded(file), isTrue);
    });
  });
}
