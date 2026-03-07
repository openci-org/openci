import 'package:dashboard/team/create_team_bottom_sheet.dart';
import 'package:dashboard/team/edit_team_bottom_sheet.dart';
import 'package:dashboard/team/switch_team_bottom_sheet.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/users/user_provider.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:dashboard/workflow/list/create_workflow_page.dart';
import 'package:dashboard/workflow/list/select_branch_bottom_sheet.dart';
import 'package:dashboard/workflow/list/select_repository_bottom_sheet.dart';
import 'package:dashboard/workflow/list/workflow_file_provider.dart';
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
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: asyncErrorWidget,
      data: (user) {
        final selectedRepo = user.selectedRepository;
        final selectedBranch = user.selectedBranch;

        return Scaffold(
          floatingActionButton: selectedRepo != null && selectedBranch != null
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => CreateWorkflowPage(
                          repository: selectedRepo,
                          branch: selectedBranch,
                          teamId: ref.read(teamStateProvider).requireValue.id,
                        ),
                      ),
                    );
                  },
                  label: const Text('Add Workflow'),
                  icon: const Icon(Icons.add),
                )
              : null,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Workflows'),
                if (selectedRepo != null)
                  Row(
                    children: [
                      Flexible(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              showDragHandle: true,
                              builder: (_) =>
                                  const SelectRepositoryBottomSheet(),
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                FontAwesomeIcons.github,
                                size: 12,
                                color: Theme.of(context).hintColor,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  selectedRepo,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context).hintColor,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (selectedBranch != null)
                        Flexible(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              showDragHandle: true,
                              builder: (_) => SelectBranchBottomSheet(
                                repoFullName: selectedRepo,
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer.withValues(
                                      alpha: 0.5,
                                    ),
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
                                  Flexible(
                                    child: Text(
                                      selectedBranch,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onPrimaryContainer,
                                          ),
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

          body: selectedRepo == null
              ? SelectRepository()
              : _WorkflowBody(
                  onShowSetupSheet: () {
                    // TODO(mafreud): fix
                  },
                ),
        );
      },
    );
  }
}

class _WorkflowBody extends ConsumerWidget {
  const _WorkflowBody({required this.onShowSetupSheet});

  final VoidCallback onShowSetupSheet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workflowFilesAsync = ref.watch(workflowFilesProvider);

    return workflowFilesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: asyncErrorWidget,
      data: (files) {
        if (files.isEmpty) {
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
                  'No workflow files found',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Add YAML files to .openci/ in your repository.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: ListView.separated(
            itemCount: files.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final file = files[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  onTap: () {
                    final repo = ref
                        .read(userProvider)
                        .requireValue
                        .selectedRepository;
                    final branch = ref
                        .read(userProvider)
                        .requireValue
                        .selectedBranch;
                    if (repo == null || branch == null) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CreateWorkflowPage(
                          repository: repo,
                          branch: branch,
                          teamId: ref.read(teamStateProvider).requireValue.id,
                          existingFile: file,
                        ),
                      ),
                    );
                  },
                  leading: Icon(
                    Icons.description_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    file.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    file.path,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).disabledColor,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class SelectRepository extends StatelessWidget {
  const SelectRepository({super.key});

  @override
  Widget build(BuildContext context) {
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
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => const SelectRepositoryBottomSheet(),
              ),
              icon: const Icon(FontAwesomeIcons.github, size: 18),
              label: const Text('Select Repository'),
            ),
          ],
        ),
      ),
    );
  }
}
