import 'package:dashboard/issues/issue_board_ima_page.dart';
import 'package:flutter/material.dart';
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
    testWidgets('does not display issue labels on workspace cards', (
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
                    id: 'issue-1992',
                    displayId: 'IMA-1992',
                    repo: 'openci-org/openci',
                    title: 'Workspaceにラベル表示不要',
                    labels: ['Feature', 'mobile'],
                    comments: 0,
                    priority: Priority.medium,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Workspaceにラベル表示不要'), findsOneWidget);
      expect(find.text('Feature'), findsNothing);
      expect(find.text('mobile'), findsNothing);
    });

    testWidgets('renders the issue id chip with matching text styling', (
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
                    id: 'issue-407',
                    displayId: 'IMA-407',
                    repo: 'openci-org/openci',
                    title: 'Chipの見た目を揃える',
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

      expect(find.text('IMA-407'), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);

      final issueIdText = tester.widget<Text>(find.text('IMA-407'));
      expect(issueIdText.style?.color, const Color(0xFF475569));
      expect(issueIdText.style?.fontWeight, FontWeight.w700);
    });

    testWidgets('uses the same neutral chip styling in review cards', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: ReviewGroupIssueCard(
                  issue: Issue(
                    id: 'issue-407',
                    displayId: 'IMA-407',
                    repo: 'openci-org/openci',
                    title: 'レビュー側のChipも揃える',
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

      final issueIdText = tester.widget<Text>(find.text('IMA-407'));
      expect(issueIdText.style?.color, const Color(0xFF475569));
      expect(issueIdText.style?.fontWeight, FontWeight.w700);
    });

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
            'path': 'lib/issues/issue_board_ima_issue_editor.dart',
            'line': 42,
            'side': 'RIGHT',
          },
        ],
        'commentsTruncated': false,
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
      expect(diff.mergeable, isFalse);
      expect(diff.mergeableState, 'dirty');
      expect(diff.filesTruncated, isTrue);
      expect(diff.files.single.patchTruncated, isTrue);
      expect(diff.files.single.additions, 12);
      expect(diff.ci.allPassed, isTrue);
      expect(diff.ci.passed, 4);
      expect(diff.comments.single.author, 'coderabbitai');
      expect(diff.comments.single.kind, IssuePullRequestCommentKind.review);
      expect(
        diff.comments.single.path,
        'lib/issues/issue_board_ima_issue_editor.dart',
      );
      expect(diff.comments.single.line, 42);
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

      expect(diff.ci.status, PullRequestCiStatus.none);
      expect(diff.ci.total, 0);
      expect(diff.ci.allPassed, isFalse);
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

    test('detects syntax language from diff file names', () {
      expect(
        diffLanguageForFilename('lib/issues/issue_board_ima_page.dart'),
        'dart',
      );
      expect(diffLanguageForFilename('.openci/functions-ci.yaml'), 'yaml');
      expect(
        diffLanguageForFilename('firebase/functions/src/index.ts'),
        'typescript',
      );
      expect(diffLanguageForFilename('Dockerfile'), 'dockerfile');
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

      expect(lines[0].kind, DiffPatchLineKind.hunk);
      expect(lines[1].kind, DiffPatchLineKind.context);
      expect(lines[1].oldLineNumber, 10);
      expect(lines[1].newLineNumber, 10);
      expect(lines[2].kind, DiffPatchLineKind.removed);
      expect(lines[2].oldLineNumber, 11);
      expect(lines[2].newLineNumber, isNull);
      expect(lines[3].kind, DiffPatchLineKind.added);
      expect(lines[3].oldLineNumber, isNull);
      expect(lines[3].newLineNumber, 11);
      expect(lines[4].newLineNumber, 12);
      expect(lines[5].kind, DiffPatchLineKind.meta);
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

      expect(attempts, 2);
      expect(tester.takeException(), isNull);
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
      expect(tester.takeException(), isNull);
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
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton).last).onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
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

    testWidgets('creates a pull request from the recent branch dialog', (
      tester,
    ) async {
      String? createdHead;
      String? openedIssueId;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentRemoteBranchesMetric(
              isCompact: false,
              loadBranches: () async {
                return const WorkspaceRecentBranchList(
                  repositories: 1,
                  branches: [
                    WorkspaceRecentBranch(
                      repository: 'openci-org/openci',
                      name: 'IMA-1973-create-pr',
                      sha: 'abc123456789',
                      base: 'develop',
                      issueId: 'issue-1973',
                      issueKey: 'IMA-1973',
                      issueTitle: 'PRの作成もOpenCI上で行いたい。',
                      issueStatusId: 'review',
                    ),
                  ],
                );
              },
              onCreatePullRequest: (branch) async {
                createdHead = branch.name;
                return const IssuePullRequest(
                  number: 1974,
                  title: 'PRの作成もOpenCI上で行いたい。 IMA-1973',
                  state: 'open',
                  merged: false,
                  branch: 'IMA-1973-create-pr',
                );
              },
              onOpenIssue: (issueId) {
                openedIssueId = issueId;
              },
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('ブランチ'), findsOneWidget);
      expect(find.text('1個'), findsOneWidget);
      expect(find.text('IMA-1973-create-pr'), findsNothing);

      await tester.tap(find.text('ブランチ'));
      await tester.pumpAndSettle();

      expect(find.text('最近のブランチ'), findsOneWidget);
      expect(find.text('IMA-1973-create-pr'), findsOneWidget);

      await tester.tap(find.text('IMA-1973 PRの作成もOpenCI上で行いたい。'));
      await tester.pumpAndSettle();
      expect(openedIssueId, 'issue-1973');

      await tester.tap(find.text('ブランチ'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('PR作成'));
      await tester.pumpAndSettle();

      expect(createdHead, 'IMA-1973-create-pr');
      expect(find.text('作成済み'), findsOneWidget);
    });

    testWidgets('refreshes recent branches after a load error', (tester) async {
      var loadCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentRemoteBranchesMetric(
              isCompact: false,
              loadBranches: () async {
                loadCount += 1;
                if (loadCount == 1) {
                  throw StateError('temporary failure');
                }
                return const WorkspaceRecentBranchList(
                  repositories: 1,
                  branches: [
                    WorkspaceRecentBranch(
                      repository: 'openci-org/openci',
                      name: 'IMA-1973-create-pr',
                      sha: 'abc123456789',
                      base: 'develop',
                      issueId: 'issue-1973',
                      issueKey: 'IMA-1973',
                      issueTitle: 'PRの作成もOpenCI上で行いたい。',
                      issueStatusId: 'review',
                    ),
                  ],
                );
              },
              onCreatePullRequest: (branch) async {
                return const IssuePullRequest(
                  number: 1974,
                  title: 'PRの作成もOpenCI上で行いたい。 IMA-1973',
                  state: 'open',
                  merged: false,
                  branch: 'IMA-1973-create-pr',
                );
              },
              onOpenIssue: (_) {},
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('読み込みエラー'), findsOneWidget);

      await tester.tap(find.text('ブランチ'));
      await tester.pumpAndSettle();

      expect(find.text('ブランチを読み込めませんでした'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.refresh_rounded).first);
      await tester.pumpAndSettle();

      expect(loadCount, 2);
      expect(find.text('IMA-1973-create-pr'), findsOneWidget);
    });
  });
}
