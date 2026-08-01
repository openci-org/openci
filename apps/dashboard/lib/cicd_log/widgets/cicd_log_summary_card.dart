import 'package:dashboard/cicd_log/widgets/cicd_job_status.dart';
import 'package:dashboard/cicd_log/widgets/workflow_overview.dart';
import 'package:dashboard/responsive/desktop_max_width.dart';
import 'package:flutter/material.dart';
import 'package:openci_shared/openci_shared.dart';

class CicdLogSummaryCard extends StatelessWidget {
  final CicdCommitGroup commit;

  const CicdLogSummaryCard({super.key, required this.commit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              leading: cicdJobStatus(commit.status),
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

  final CicdCommitGroup commit;

  @override
  Widget build(BuildContext context) {
    final shortSha = commit.commitSha.length > 7
        ? commit.commitSha.substring(0, 7)
        : commit.commitSha;

    return Row(
      spacing: 8.0,
      children: [
        const Icon(
          Icons.arrow_upward,
          color: Colors.black54,
          size: 16,
        ),
        Flexible(
          child: Text(
            commit.branch,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          shortSha,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 14,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
