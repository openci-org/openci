import 'dart:async';

import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/users/user_provider.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:dashboard/workflow/list/create_workflow_page.dart';
import 'package:dashboard/workflow/list/workflow_file_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class WorkflowsPage extends ConsumerWidget {
  const WorkflowsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workflows'),
        leading: IconButton(
          tooltip: 'Issues に戻る',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            tooltip: 'Workflows を同期',
            icon: const Icon(Icons.sync_rounded),
            onPressed: () => unawaited(_syncWorkflows(context, ref)),
          ),
        ],
      ),
      body: const WorkflowsBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openWorkflowEditor(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Workflow 作成'),
      ),
    );
  }
}

class WorkflowsBody extends ConsumerWidget {
  const WorkflowsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final workflowFilesAsync = ref.watch(workflowFilesProvider);

    return userAsync.when(
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: asyncErrorWidget,
      data: (user) {
        final selectedRepository = user.selectedRepository;
        final selectedBranch = user.selectedBranch;
        if (selectedRepository == null || selectedBranch == null) {
          return const _EmptyWorkflowsView(
            icon: Icons.account_tree_outlined,
            title: 'Repository が選択されていません',
            message: 'Issue board のボード設定から対象 repository を選んでください。',
          );
        }

        return workflowFilesAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator.adaptive()),
          error: asyncErrorWidget,
          data: (files) {
            if (files.isEmpty) {
              return _EmptyWorkflowsView(
                icon: Icons.schema_outlined,
                title: 'Workflow がありません',
                message:
                    '$selectedRepository / $selectedBranch に .openci workflow が見つかりません。',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: files.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final file = files[index];
                return _WorkflowFileTile(
                  file: file,
                  repository: selectedRepository,
                  branch: selectedBranch,
                  onTap: () => _openWorkflowEditor(
                    context,
                    ref,
                    existingFile: file,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

Future<void> _syncWorkflows(BuildContext context, WidgetRef ref) async {
  try {
    await ref.read(syncWorkflowFilesProvider.future);
    ref.invalidate(workflowFilesProvider);
    if (context.mounted) {
      context.showSnackBarMessage('Workflows を同期しました');
    }
  } catch (error) {
    if (context.mounted) {
      context.showSnackBarMessage('Workflows の同期に失敗しました: $error');
    }
  }
}

void _openWorkflowEditor(
  BuildContext context,
  WidgetRef ref, {
  WorkflowFile? existingFile,
}) {
  final user = ref.read(userProvider).value;
  final team = ref.read(teamStateProvider).value;
  final repository = user?.selectedRepository;
  final branch = user?.selectedBranch;

  if (user == null || team == null || repository == null || branch == null) {
    context.showSnackBarMessage('Repository と branch を選択してください');
    return;
  }

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => CreateWorkflowPage(
        repository: repository,
        branch: branch,
        teamId: team.id,
        existingFile: existingFile,
      ),
    ),
  );
}

class _WorkflowFileTile extends ConsumerWidget {
  const _WorkflowFileTile({
    required this.file,
    required this.repository,
    required this.branch,
    required this.onTap,
  });

  final WorkflowFile file;
  final String repository;
  final String branch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: file.enabled
                      ? const Color(0xFFEFF6FF)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.schema_rounded,
                  color: file.enabled
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$repository · $branch · ${file.path}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch(
                value: file.enabled,
                onChanged: (enabled) => unawaited(
                  ref.read(
                    toggleWorkflowEnabledProvider(
                      fileName: file.name,
                      enabled: enabled,
                    ).future,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyWorkflowsView extends StatelessWidget {
  const _EmptyWorkflowsView({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: const Color(0xFF94A3B8)),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
