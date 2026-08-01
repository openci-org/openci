import 'package:dashboard/cicd_log/widgets/cicd_log_summary_card.dart';
import 'package:dashboard/cicd_log/cicd_log_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
            itemBuilder: (_, index) {
              final commit = groups[index];
              return CicdLogSummaryCard(
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
