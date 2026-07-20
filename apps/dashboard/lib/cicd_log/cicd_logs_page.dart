import 'package:flutter/material.dart';

class CicdLogsPage extends StatelessWidget {
  const CicdLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // モックデータ定義
    final mockCommits = [
      _MockCommitData(
        branch: 'main',
        commitSha: 'a1c3e4f',
        commitMessage: 'feat: add apple sign-in support to iOS app',
        status: _MockStatus.success,
        timeAgo: '10分前',
        workflows: [
          _MockWorkflowData(
            fileName: 'ios.yaml',
            status: _MockStatus.success,
            duration: '4分20秒',
            jobs: ['build-ipa', 'deploy-testflight'],
          ),
          _MockWorkflowData(
            fileName: 'android.yaml',
            status: _MockStatus.success,
            duration: '3分15秒',
            jobs: ['build-apk'],
          ),
        ],
      ),
      _MockCommitData(
        branch: 'feat/google-login',
        commitSha: '8d2f91a',
        commitMessage: 'fix(android): resolve build crash on Android 14',
        status: _MockStatus.failure,
        timeAgo: '1時間前',
        workflows: [
          _MockWorkflowData(
            fileName: 'ios.yaml',
            status: _MockStatus.success,
            duration: '4分10秒',
            jobs: ['build-ipa'],
          ),
          _MockWorkflowData(
            fileName: 'android.yaml',
            status: _MockStatus.failure,
            duration: '1分45秒',
            jobs: ['build-apk', 'run-unit-tests'],
          ),
        ],
      ),
      _MockCommitData(
        branch: 'fix/typo',
        commitSha: '3c8e7b2',
        commitMessage: 'docs: update README.md instruction details',
        status: _MockStatus.inProgress,
        timeAgo: '実行中',
        workflows: [
          _MockWorkflowData(
            fileName: 'static-analysis.yaml',
            status: _MockStatus.success,
            duration: '45秒',
            jobs: ['linter', 'formatter-check'],
          ),
          _MockWorkflowData(
            fileName: 'ios.yaml',
            status: _MockStatus.inProgress,
            duration: '2分経過',
            jobs: ['build-ipa'],
          ),
        ],
      ),
    ];

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text(
          'CI/CDログ (プレビュー)',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shape: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: mockCommits.length,
        itemBuilder: (context, index) {
          final commit = mockCommits[index];
          return _CommitCard(commit: commit);
        },
      ),
    );
  }
}

enum _MockStatus { success, failure, inProgress }

class _MockCommitData {
  final String branch;
  final String commitSha;
  final String commitMessage;
  final _MockStatus status;
  final String timeAgo;
  final List<_MockWorkflowData> workflows;

  _MockCommitData({
    required this.branch,
    required this.commitSha,
    required this.commitMessage,
    required this.status,
    required this.timeAgo,
    required this.workflows,
  });
}

class _MockWorkflowData {
  final String fileName;
  final _MockStatus status;
  final String duration;
  final List<String> jobs;

  _MockWorkflowData({
    required this.fileName,
    required this.status,
    required this.duration,
    required this.jobs,
  });
}

class _CommitCard extends StatelessWidget {
  final _MockCommitData commit;

  const _CommitCard({required this.commit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    const desktopMaxWidth = 640.0;

    final statusWidget = switch (commit.status) {
      _MockStatus.success => Icon(Icons.check, color: Colors.green, size: 20),
      _MockStatus.failure => Icon(
        Icons.close,
        color: Colors.red,
        size: 20,
      ),
      _MockStatus.inProgress => SizedBox(
        height: 16,
        width: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          strokeAlign: -1.0,
        ),
      ),
    };

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: desktopMaxWidth),
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              collapsedBackgroundColor: theme.colorScheme.surface,
              backgroundColor: theme.colorScheme.surfaceContainerLow,
              leading: statusWidget,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      commit.branch,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    commit.commitSha,
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  commit.commitMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              childrenPadding: const EdgeInsets.only(
                bottom: 12,
                left: 12,
                right: 12,
              ),
              children: commit.workflows.map((wf) {
                return _WorkflowRow(workflow: wf);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkflowRow extends StatelessWidget {
  final _MockWorkflowData workflow;

  const _WorkflowRow({required this.workflow});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (statusColor, statusIcon) = switch (workflow.status) {
      _MockStatus.success => (const Color(0xFF3FB950), Icons.check_rounded),
      _MockStatus.failure => (const Color(0xFFF85149), Icons.close_rounded),
      _MockStatus.inProgress => (
        const Color(0xFF58A6FF),
        Icons.hourglass_empty_rounded,
      ),
    };

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 18),
              const SizedBox(width: 8),
              Text(
                workflow.fileName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                workflow.duration,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: workflow.jobs.map((job) {
              return InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ジョブ "$job" の詳細ログへ遷移します'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.article_outlined,
                        size: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        job,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
