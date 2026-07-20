import 'package:dashboard/cicd_log/cicd_log_providers.dart';
import 'package:dashboard/cicd_log/workflow_overview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openci_shared/openci_shared.dart';

class CicdLogsPage extends ConsumerWidget {
  const CicdLogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commitGroupsAsync = ref.watch(cicdCommitGroupsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'CI/CDログ',
        ),
      ),
      body: commitGroupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return const Center(
              child: Text(
                'アクティブなCI/CDログはありません',
                style: TextStyle(color: Colors.black54),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final commit = groups[index];
              return _Card(
                key: ValueKey(commit.commitSha),
                commit: commit,
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator.adaptive(),
        ),
        error: (err, stack) => Center(
          child: Text(
            'ログの取得中にエラーが発生しました: $err',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final CicdCommitGroup commit;

  const _Card({super.key, required this.commit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    const desktopMaxWidth = 640.0;

    final statusWidget = switch (commit.status) {
      BuildJobStatus.SUCCESS => Icon(
        Icons.check,
        color: Colors.green,
        size: 20,
      ),
      BuildJobStatus.FAILURE ||
      BuildJobStatus.CANCELLED ||
      BuildJobStatus.TIMED_OUT => Icon(
        Icons.close,
        color: Colors.red,
        size: 20,
      ),
      _ => Transform.scale(
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
