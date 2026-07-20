import 'package:dashboard/cicd_log/cicd_mock_data.dart';
import 'package:dashboard/cicd_log/workflow_overview.dart';
import 'package:flutter/material.dart';

class CicdLogsPage extends StatelessWidget {
  const CicdLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'CI/CDログ (プレビュー)',
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: mockCommits.length,
        itemBuilder: (context, index) {
          final commit = mockCommits[index];
          return _Card(commit: commit);
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final MockCommitData commit;

  const _Card({required this.commit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    const desktopMaxWidth = 640.0;

    final statusWidget = switch (commit.status) {
      MockStatus.success => Icon(Icons.check, color: Colors.green, size: 20),
      MockStatus.failure => Icon(
        Icons.close,
        color: Colors.red,
        size: 20,
      ),
      MockStatus.inProgress => Transform.scale(
        scale: 0.8,
        child: CircularProgressIndicator.adaptive(),
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
              color: Colors.grey.shade400,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              collapsedBackgroundColor: theme.colorScheme.surface,
              backgroundColor: theme.colorScheme.surfaceContainerLow,
              leading: statusWidget,
              title: Text(
                commit.commitMessage,
              ),
              subtitle: _Subtitle(commit: commit),
              childrenPadding: const EdgeInsets.only(
                bottom: 6,
                left: 12,
                right: 12,
              ),
              children: commit.workflows.map((wf) {
                return WorkflowOverview(workflow: wf);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _Subtitle extends StatelessWidget {
  const _Subtitle({
    required this.commit,
  });

  final MockCommitData commit;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8.0,
      children: [
        Icon(
          commit.triggerType == 'push' ? Icons.arrow_upward : Icons.merge,
          color: Colors.black54,
          size: 16,
        ),
        Text(
          commit.branch,
          style: TextStyle(
            color: Colors.black54,

            fontSize: 14,
          ),
        ),
        Text(
          commit.commitSha,
          style: TextStyle(
            color: Colors.black54,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
