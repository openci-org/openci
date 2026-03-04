import 'package:dashboard/github/github_repository_provider.dart';
import 'package:dashboard/github/select_repository_bottom_sheet.dart';
import 'package:dashboard/team/create_team_bottom_sheet.dart';
import 'package:dashboard/team/edit_team_bottom_sheet.dart';
import 'package:dashboard/team/switch_team_bottom_sheet.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:dashboard/workflow/editor/initial_workflow_setup/initial_workflow_setup_bottom_sheet.dart';
import 'package:dashboard/workflow/editor/workflow_editor_page.dart';
import 'package:dashboard/workflow/list/workflow_list_provider.dart';
import 'package:dashboard/workflow/workflow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

String getInitials(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  if (words.length >= 2) {
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }
  return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
}

class WorkflowListPage extends ConsumerWidget {
  const WorkflowListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workflowList = ref.watch(workflowListProvider);
    final selectedRepo = ref.watch(selectedRepositoryProvider);
    final selectedBranch = ref.watch(selectedBranchProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Workflows'),
            if (selectedRepo != null)
              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showRepoSelector(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          FontAwesomeIcons.github,
                          size: 12,
                          color: Theme.of(context).hintColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          selectedRepo,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).hintColor,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (selectedBranch != null)
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _showBranchSelector(
                        context,
                        selectedRepo,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              FontAwesomeIcons.codeBranch,
                              size: 10,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              selectedBranch,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.arrow_drop_down,
                              size: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: MenuAnchor(
              menuChildren: [
                MenuItemButton(
                  leadingIcon: const Icon(Icons.swap_horiz),
                  onPressed: () {
                    showModalBottomSheet(
                      showDragHandle: true,
                      context: context,
                      isScrollControlled: true,
                      builder: (_) {
                        return const SwitchTeamBottomSheet();
                      },
                    );
                  },
                  child: const Text('Switch Team'),
                ),
                MenuItemButton(
                  leadingIcon: const Icon(Icons.edit),
                  onPressed: () {
                    showModalBottomSheet(
                      showDragHandle: true,
                      context: context,
                      isScrollControlled: true,
                      builder: (_) {
                        return const EditTeamBottomSheet();
                      },
                    );
                  },
                  child: const Text('Edit Team'),
                ),
                MenuItemButton(
                  leadingIcon: const Icon(Icons.add),
                  onPressed: () {
                    showModalBottomSheet(
                      showDragHandle: true,
                      context: context,
                      isScrollControlled: true,
                      builder: (_) {
                        return const CreateTeamBottomSheet();
                      },
                    );
                  },
                  child: const Text('Create Team'),
                ),
              ],
              builder: (context, controller, child) {
                return InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
                  child: Ink(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).primaryColorLight,
                    ),
                    child: Center(
                      child: Consumer(
                        builder: (context, ref, child) {
                          final team = ref.watch(teamStateProvider);
                          return team.when(
                            data: (team) {
                              return Text(
                                getInitials(team.name),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).primaryColor,
                                ),
                              );
                            },
                            error: asyncErrorWidget,
                            loading: () => const Center(
                              child: CircularProgressIndicator.adaptive(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: workflowList.value?.isNotEmpty == true
          ? FloatingActionButton(
              onPressed: () => _showSetupSheet(context),
              child: const Icon(Icons.add),
            )
          : null,
      body: selectedRepo == null
          ? _buildRepoSetup(context)
          : workflowList.when(
              data: (workflows) {
                if (workflows.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.layers_outlined,
                          size: 64,
                          color: Theme.of(context).disabledColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No workflows created yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: () => _showSetupSheet(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Create Workflow'),
                        ),
                      ],
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView.separated(
                    itemCount: workflows.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final workflow = workflows[index];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => WorkflowEditorPage(
                                  workflowId: workflow.documentId,
                                ),
                              ),
                            );
                          },
                          title: Text(
                            workflow.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      switch (workflow
                                          .workflowConfig
                                          .selectedTriggerType) {
                                        TriggerType.tag => FontAwesomeIcons.tag,
                                        TriggerType.push =>
                                          FontAwesomeIcons.codeCommit,
                                        TriggerType.pullRequest =>
                                          FontAwesomeIcons.codePullRequest,
                                        TriggerType.release =>
                                          Icons.new_releases_outlined,
                                      },
                                      size: 14,
                                      color: Theme.of(context).hintColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      workflow
                                                      .workflowConfig
                                                      .selectedTriggerType ==
                                                  TriggerType.tag ||
                                              workflow
                                                      .workflowConfig
                                                      .selectedTriggerType ==
                                                  TriggerType.release
                                          ? workflow
                                                .workflowConfig
                                                .selectedTriggerType
                                                .toString()
                                          : (workflow
                                                    .workflowConfig
                                                    .selectedTriggerBranch ??
                                                ''),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(
                                      FontAwesomeIcons.github,
                                      size: 16,
                                      color: Theme.of(context).hintColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      workflow
                                          .workflowConfig
                                          .selectedRepository,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert,
                              color: Theme.of(context).disabledColor,
                            ),
                            onSelected: (value) async {
                              switch (value) {
                                case 'duplicate':
                                  try {
                                    await ref
                                        .read(workflowListProvider.notifier)
                                        .duplicateWorkflow(workflow);
                                    if (!context.mounted) return;
                                    context.showSnackBarMessage(
                                      'Workflow duplicated successfully',
                                    );
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    context.showSnackBarMessage(
                                      'Failed to duplicate: $e',
                                    );
                                  }
                                  break;
                                case 'delete':
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Workflow'),
                                      content: Text(
                                        'Are you sure you want to delete "${workflow.name}"?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Theme.of(
                                              context,
                                            ).colorScheme.error,
                                          ),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) {
                                    try {
                                      await ref
                                          .read(workflowListProvider.notifier)
                                          .deleteWorkflow(workflow.documentId);
                                      if (!context.mounted) return;
                                      context.showSnackBarMessage(
                                        'Workflow deleted',
                                      );
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      context.showSnackBarMessage(
                                        'Failed to delete: $e',
                                      );
                                    }
                                  }
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'duplicate',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.copy,
                                      size: 20,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('Duplicate'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              error: asyncErrorWidget,
              loading: () =>
                  Center(child: CircularProgressIndicator.adaptive()),
            ),
    );
  }

  Widget _buildRepoSetup(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.github,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 24),
            Text(
              'Select a repository',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a GitHub repository to manage workflows.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showRepoSelector(context),
              icon: const Icon(FontAwesomeIcons.github, size: 18),
              label: const Text('Select Repository'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRepoSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const SelectRepositoryBottomSheet(),
    );
  }

  void _showBranchSelector(BuildContext context, String repoFullName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SelectBranchBottomSheet(repoFullName: repoFullName),
    );
  }

  void _showSetupSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => InitialWorkflowSetupBottomSheet(),
    );
  }
}
