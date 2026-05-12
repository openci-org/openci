import 'dart:async';

import 'package:dashboard/users/user_provider.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:dashboard/workflow/list/create_workflow_page.dart';
import 'package:dashboard/workflow/list/workflow_file_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

class WorkflowsPage extends ConsumerWidget {
  const WorkflowsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ワークフロー'),
        leading: IconButton(
          tooltip: 'ワークスペースに戻る',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/workspace'),
        ),
        actions: [
          IconButton(
            tooltip: 'ワークフローを同期',
            icon: const Icon(Icons.sync_rounded),
            onPressed: () => unawaited(_syncWorkflows(context, ref)),
          ),
        ],
      ),
      body: const WorkflowsBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openWorkflowEditor(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('ワークフロー作成'),
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
        return workflowFilesAsync.when(
          loading: () => const _WorkflowListSkeleton(),
          error: asyncErrorWidget,
          data: (files) {
            if (files.isEmpty) {
              return _EmptyWorkflowsView(
                icon: Icons.schema_outlined,
                title: 'Workflow がありません',
                message: '選択中の GitHub repo に .openci workflow が見つかりません。',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: files.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final file = files[index];
                return _WorkflowListItemFrame(
                  child: _WorkflowFileTile(
                    file: file,
                    repository: file.repository,
                    branch: file.branch,
                    onTap: () => _openWorkflowEditor(
                      context,
                      ref,
                      existingFile: file,
                    ),
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

class _WorkflowListSkeleton extends StatelessWidget {
  const _WorkflowListSkeleton();

  static const _files = [
    WorkflowFile(
      name: 'flutter-ci-cd.yaml',
      path: '.openci/flutter-ci-cd.yaml',
      content: '',
      repository: 'openci-org/openci',
      branch: 'develop',
    ),
    WorkflowFile(
      name: 'deploy.yaml',
      path: '.openci/deploy.yaml',
      content: '',
      repository: 'openci-org/dashboard',
      branch: 'main',
    ),
    WorkflowFile(
      name: 'release.yaml',
      path: '.openci/release.yaml',
      content: '',
      repository: 'openci-org/worker',
      branch: 'main',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        itemCount: _files.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final file = _files[index];
          return _WorkflowListItemFrame(
            child: _WorkflowFileTile(
              file: file,
              repository: file.repository,
              branch: file.branch,
              onTap: () {},
            ),
          );
        },
      ),
    );
  }
}

class _WorkflowListItemFrame extends StatelessWidget {
  const _WorkflowListItemFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: child,
      ),
    );
  }
}

Future<void> _syncWorkflows(BuildContext context, WidgetRef ref) async {
  ref.invalidate(workflowFilesProvider);
  if (context.mounted) {
    context.showSnackBarMessage('ワークフローを再読み込みしました');
  }
}

void _openWorkflowEditor(
  BuildContext context,
  WidgetRef ref, {
  WorkflowFile? existingFile,
}) {
  final user = ref.read(userProvider).value;
  final repository = existingFile?.repository ?? user?.selectedRepository;
  final branch = existingFile?.branch ?? user?.selectedBranch;

  if (user == null || repository == null || branch == null) {
    context.showSnackBarMessage('Repository と branch を選択してください');
    return;
  }

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => CreateWorkflowPage(
        repository: repository,
        branch: branch,
        teamId: user.selectedTeamId,
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
    final compact = MediaQuery.sizeOf(context).width < 520;
    final details = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            file.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '$repository · $branch · ${file.path}',
            maxLines: compact ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

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
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.schema_rounded,
                  color: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 14),
              details,
              SizedBox(width: compact ? 4 : 8),
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
