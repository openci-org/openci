import 'package:checks/checks.dart';
import 'package:dashboard/workspace/issue_board_ima_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldSpinCardBuildStatus', () {
    test('does not spin when any current CI job failed', () {
      check(shouldSpinCardBuildStatus(failed: 1, active: 1, queuedOnly: false))
          .isFalse();
    });

    test('spins while non-queued jobs are still running', () {
      check(shouldSpinCardBuildStatus(failed: 0, active: 1, queuedOnly: false))
          .isTrue();
    });

    test('does not spin for queued-only jobs', () {
      check(shouldSpinCardBuildStatus(failed: 0, active: 1, queuedOnly: true))
          .isFalse();
    });
  });

  group('IssuePullRequestDiff', () {
    testWidgets(
      'hides the generated document id while ticket number is pending',
      (
        tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 320,
                  child: IssueCard(
                    issue: Issue(
                      id: 'pending-document-id',
                      repo: 'openci-org/openci',
                      title: '番号確定前のカード',
                      labels: [],
                      comments: 0,
                      priority: Priority.medium,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.text('pending-document-id'), findsNothing);
        expect(find.text('作成中'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    test('parses changed files and truncation flags', () {
      final diff = IssuePullRequestDiff.fromMap({
        'repository': 'openci-org/openci',
        'pullRequestNumber': 1956,
        'title': 'Show pull request diff',
        'url': 'https://github.com/openci-org/openci/pull/1956',
        'state': 'open',
        'merged': false,
        'mergeable': false,
        'mergeableState': 'dirty',
        'branch': 'IMA-391',
        'additions': 12,
        'deletions': 3,
        'changedFiles': 1,
        'ci': {
          'status': 'success',
          'total': 4,
          'passed': 4,
          'failed': 0,
          'pending': 0,
          'skipped': 0,
          'checksTruncated': false,
        },
        'comments': [
          {
            'id': 'comment-1',
            'author': 'coderabbitai',
            'authorAssociation': 'NONE',
            'body': 'Consider handling this edge case.',
            'url':
                'https://github.com/openci-org/openci/pull/1956#discussion_r1',
            'createdAt': '2026-05-16T00:00:00Z',
            'updatedAt': '2026-05-16T00:00:00Z',
            'kind': 'review',
            'path': 'lib/workspace/issue_board_ima_issue_editor.dart',
            'line': 42,
            'side': 'RIGHT',
          },
        ],
        'commentsTruncated': false,
        'filesTruncated': true,
        'files': [
          {
            'filename': 'lib/workspace/issue_board_ima_issue_editor.dart',
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

      check(diff.repository).equals('openci-org/openci');
      check(diff.pullRequestNumber).equals(1956);
      check(diff.mergeable).equals(false);
      check(diff.mergeableState).equals('dirty');
      check(diff.filesTruncated).isTrue();
      check(diff.files.single.patchTruncated).isTrue();
      check(diff.files.single.additions).equals(12);
      check(diff.ci.allPassed).isTrue();
      check(diff.ci.passed).equals(4);
      check(diff.comments.single.author).equals('coderabbitai');
      check(diff.comments.single.kind).equals(IssuePullRequestCommentKind.review);
      check(diff.comments.single.path)
          .equals('lib/workspace/issue_board_ima_issue_editor.dart');
      check(diff.comments.single.line).equals(42);
    });

    test('defaults missing CI summary to no checks', () {
      final diff = IssuePullRequestDiff.fromMap({
        'repository': 'openci-org/openci',
        'pullRequestNumber': 1956,
        'title': 'Show pull request diff',
        'url': 'https://github.com/openci-org/openci/pull/1956',
        'state': 'open',
        'merged': false,
        'branch': 'IMA-391',
        'additions': 0,
        'deletions': 0,
        'changedFiles': 0,
        'files': [],
      });

      check(diff.ci.status).equals(PullRequestCiStatus.none);
      check(diff.ci.total).equals(0);
      check(diff.ci.allPassed).isFalse();
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

      check(diffFileInitiallyExpanded(file)).isTrue();
    });

    test('detects syntax language from diff file names', () {
      check(diffLanguageForFilename('lib/workspace/issue_board_ima_page.dart'))
          .equals('dart');
      check(diffLanguageForFilename('.openci/functions-ci.yaml')).equals('yaml');
      check(diffLanguageForFilename('firebase/functions/src/index.ts'))
          .equals('typescript');
      check(diffLanguageForFilename('Dockerfile')).equals('dockerfile');
    });

    test('parses patch line kinds and line numbers', () {
      final lines = diffPatchLines(
        '@@ -10,2 +10,3 @@\n'
        ' final title = oldTitle;\n'
        '-debugPrint(title);\n'
        '+logger.info(title);\n'
        '+logger.info("done");\n'
        r'\ No newline at end of file',
      );

      check(lines[0].kind).equals(DiffPatchLineKind.hunk);
      check(lines[1].kind).equals(DiffPatchLineKind.context);
      check(lines[1].oldLineNumber).equals(10);
      check(lines[1].newLineNumber).equals(10);
      check(lines[2].kind).equals(DiffPatchLineKind.removed);
      check(lines[2].oldLineNumber).equals(11);
      check(lines[2].newLineNumber).isNull();
      check(lines[3].kind).equals(DiffPatchLineKind.added);
      check(lines[3].oldLineNumber).isNull();
      check(lines[3].newLineNumber).equals(11);
      check(lines[4].newLineNumber).equals(12);
      check(lines[5].kind).equals(DiffPatchLineKind.meta);
    });

    testWidgets('retry keeps async diff loading outside setState', (
      tester,
    ) async {
      var attempts = 0;

      Future<IssuePullRequestDiff> loadDiff() {
        attempts += 1;
        return Future<IssuePullRequestDiff>.error(
          Exception('diff unavailable'),
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PullRequestDiffSheet(
              issue: const Issue(
                id: 'issue-1',
                repo: 'openci-org/openci',
                title: 'Review PR in OpenCI',
                labels: [],
                comments: 0,
                priority: Priority.medium,
              ),
              pullRequest: const IssuePullRequest(
                number: 1956,
                title: 'Show pull request diff',
                state: 'open',
                merged: false,
                branch: 'IMA-391',
              ),
              loadDiff: loadDiff,
              onMerge: null,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(find.text('再読み込み'), findsOneWidget);

      await tester.tap(find.text('再読み込み'));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();

      check(attempts).equals(2);
      check(tester.takeException()).isNull();
    });

    testWidgets('shows merge conflict status in pull request details', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PullRequestDiffSheet(
              issue: const Issue(
                id: 'issue-1',
                repo: 'openci-org/openci',
                title: 'Review PR in OpenCI',
                labels: [],
                comments: 0,
                priority: Priority.medium,
              ),
              pullRequest: const IssuePullRequest(
                number: 1977,
                title: 'PRの作成もOpenCI上で行いたい。',
                state: 'open',
                merged: false,
                branch: 'IMA-397',
              ),
              mergeConflictMessage:
                  'このPRはbase branchとconflictしています。GitHubでconflictを解消してから、もう一度マージしてください。',
              loadDiff: () async => const IssuePullRequestDiff(
                repository: 'openci-org/openci',
                pullRequestNumber: 1977,
                title: 'PRの作成もOpenCI上で行いたい。',
                url: 'https://github.com/openci-org/openci/pull/1977',
                state: 'open',
                merged: false,
                branch: 'IMA-397',
                additions: 0,
                deletions: 0,
                changedFiles: 0,
                ci: PullRequestCiSummary(
                  status: PullRequestCiStatus.none,
                  total: 0,
                  passed: 0,
                  failed: 0,
                  pending: 0,
                  skipped: 0,
                  checksTruncated: false,
                ),
                comments: [],
                commentsTruncated: false,
                filesTruncated: false,
                files: [],
              ),
              onMerge: null,
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Conflictがあります'), findsOneWidget);
      expect(find.textContaining('GitHubでconflictを解消'), findsOneWidget);
      check(tester.takeException()).isNull();
    });

    testWidgets('shows conflict before merge when GitHub marks PR dirty', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PullRequestDiffSheet(
              issue: const Issue(
                id: 'issue-1',
                repo: 'openci-org/openci',
                title: 'Review PR in OpenCI',
                labels: [],
                comments: 0,
                priority: Priority.medium,
              ),
              pullRequest: const IssuePullRequest(
                number: 1977,
                title: 'PRの作成もOpenCI上で行いたい。',
                state: 'open',
                merged: false,
                branch: 'IMA-397',
              ),
              loadDiff: () async => const IssuePullRequestDiff(
                repository: 'openci-org/openci',
                pullRequestNumber: 1977,
                title: 'PRの作成もOpenCI上で行いたい。',
                url: 'https://github.com/openci-org/openci/pull/1977',
                state: 'open',
                merged: false,
                mergeable: false,
                mergeableState: 'dirty',
                branch: 'IMA-397',
                additions: 0,
                deletions: 0,
                changedFiles: 0,
                ci: PullRequestCiSummary(
                  status: PullRequestCiStatus.success,
                  total: 1,
                  passed: 1,
                  failed: 0,
                  pending: 0,
                  skipped: 0,
                  checksTruncated: false,
                ),
                comments: [],
                commentsTruncated: false,
                filesTruncated: false,
                files: [],
              ),
              onMerge: () async => true,
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Conflictがあります'), findsOneWidget);
      expect(find.text('Conflictあり'), findsOneWidget);
      expect(find.text('CI pass・マージ'), findsNothing);
      check(tester.widget<FilledButton>(find.byType(FilledButton).last).onPressed)
          .isNull();
      check(tester.takeException()).isNull();
    });

    testWidgets('opens pull request details inside the issue editor', (
      tester,
    ) async {
      const issue = Issue(
        id: 'issue-1',
        displayId: 'IMA-391',
        repo: 'openci-org/openci',
        title: 'Review PR in OpenCI',
        labels: [],
        comments: 0,
        priority: Priority.medium,
        githubUrl: 'https://github.com/openci-org/openci/issues/1956',
        pullRequests: [
          IssuePullRequest(
            number: 1956,
            title: 'PR details stay inside the issue editor',
            state: 'open',
            merged: false,
            branch: 'IMA-391',
          ),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AddIssueDialog(
              columns: [
                BoardColumn(
                  id: 'triage',
                  title: 'Triage',
                  description: 'New work',
                  color: Colors.blue,
                  issues: [issue],
                ),
              ],
              repositoryOptions: ['openci-org/openci'],
              initialIssue: issue,
              initialColumnId: 'triage',
            ),
          ),
        ),
      );

      final detailsButton = find.widgetWithText(FilledButton, 'PR詳細');
      await tester.ensureVisible(detailsButton);
      await tester.tap(detailsButton);
      await tester.pump();

      expect(find.byType(PullRequestDiffView), findsOneWidget);
      expect(find.byType(PullRequestDiffSheet), findsNothing);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pump();

      expect(find.byType(PullRequestDiffView), findsNothing);
      expect(detailsButton, findsOneWidget);
    });

    testWidgets('closes the issue editor when merge is confirmed', (
      tester,
    ) async {
      const issue = Issue(
        id: 'issue-1',
        displayId: 'IMA-391',
        repo: 'openci-org/openci',
        title: 'Review PR in OpenCI',
        labels: [],
        comments: 0,
        priority: Priority.medium,
        pullRequests: [
          IssuePullRequest(
            number: 1956,
            title: 'Close editor after merge starts',
            state: 'open',
            merged: false,
            branch: 'IMA-391',
          ),
        ],
      );
      Object? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  dialogResult = await showDialog<Object?>(
                    context: context,
                    builder: (context) => const AddIssueDialog(
                      columns: [
                        BoardColumn(
                          id: 'review',
                          title: 'レビュー',
                          description: 'Review',
                          color: Colors.blue,
                          issues: [issue],
                        ),
                      ],
                      repositoryOptions: ['openci-org/openci'],
                      initialIssue: issue,
                      initialColumnId: 'review',
                    ),
                  );
                },
                child: const Text('open editor'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open editor'));
      await tester.pumpAndSettle();
      expect(find.byType(AddIssueDialog), findsOneWidget);

      final mergeButton = find.widgetWithText(OutlinedButton, 'マージ');
      await tester.ensureVisible(mergeButton);
      await tester.tap(mergeButton);
      await tester.pumpAndSettle();
      expect(find.text('PR #1956をマージしますか？'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'マージする'));
      await tester.pumpAndSettle();

      expect(find.byType(AddIssueDialog), findsNothing);
      check(dialogResult).isA<MergeIssuePullRequestDialogResult>();
      final mergeResult = dialogResult as MergeIssuePullRequestDialogResult;
      check(mergeResult.issueId).equals('issue-1');
      check(mergeResult.repository).equals('openci-org/openci');
      check(mergeResult.pullRequest.number).equals(1956);
    });
  });
}
