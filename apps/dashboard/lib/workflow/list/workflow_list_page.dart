import 'package:dashboard/build_logs/build_logs_page.dart';
import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/settings/settings_page.dart';
import 'package:dashboard/store_release/store_release_page.dart';
import 'package:dashboard/team/create_team_bottom_sheet.dart';
import 'package:dashboard/team/edit_team_bottom_sheet.dart';
import 'package:dashboard/team/switch_team_bottom_sheet.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/users/user_provider.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:dashboard/variables/variables_page.dart';
import 'package:dashboard/workflow/ai/ai_workflow_page.dart';
import 'package:dashboard/workflow/list/create_workflow_page.dart';
import 'package:dashboard/workflow/list/select_branch_bottom_sheet.dart';
import 'package:dashboard/workflow/list/select_repository_bottom_sheet.dart';
import 'package:dashboard/workflow/list/workflow_file_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';
import 'package:yaml/yaml.dart';

String getInitials(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  if (words.length >= 2) {
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }
  return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
}

String? _extractWorkflowName(String yamlContent) {
  try {
    final doc = loadYaml(yamlContent);
    if (doc is YamlMap && doc['name'] is String) {
      return doc['name'] as String;
    }
  } catch (_) {}
  return null;
}

class WorkflowListPage extends HookConsumerWidget {
  const WorkflowListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final wfT = t.workflow;
    final tabController = useTabController(initialLength: 3);
    useListenable(tabController);
    final isWorkflowsTab = tabController.index == 0;

    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: asyncErrorWidget,
      data: (user) {
        final selectedRepo = user.selectedRepository;
        final selectedBranch = user.selectedBranch;

        Widget buildRepoRequiredTab(Widget child) {
          if (selectedRepo == null) return const SelectRepository();
          return Column(
            children: [
              // ── Chip row ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        avatar: FaIcon(FontAwesomeIcons.github, size: 16),
                        label: Text(
                          selectedRepo.split('/').last,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          showDragHandle: true,
                          builder: (_) => const SelectRepositoryBottomSheet(),
                        ),
                      ),
                      if (selectedBranch != null)
                        ActionChip(
                          avatar: FaIcon(FontAwesomeIcons.codeBranch, size: 14),
                          label: Text(
                            selectedBranch,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onPressed: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            showDragHandle: true,
                            builder: (_) => SelectBranchBottomSheet(
                              repoFullName: selectedRepo,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // ── Content ──
              Expanded(child: child),
            ],
          );
        }

        final tabChildren = [
          buildRepoRequiredTab(
            _WorkflowBody(
              selectedRepo: selectedRepo ?? '',
              selectedBranch: selectedBranch,
              onShowSetupSheet: () {
                // TODO(mafreud): fix
              },
              onSync: () {
                ref.invalidate(syncWorkflowFilesProvider);
              },
            ),
          ),
          buildRepoRequiredTab(const LogsBody()),
          const StoreReleaseBody(),
        ];

        return Scaffold(
          floatingActionButton:
              isWorkflowsTab && selectedRepo != null && selectedBranch != null
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.of(context).push(
                      SwipeablePageRoute(
                        fullscreenDialog: true,
                        builder: (_) => AiWorkflowPage(
                          repository: selectedRepo,
                          branch: selectedBranch,
                          teamId: ref.read(teamStateProvider).value?.id ?? '',
                        ),
                      ),
                    );
                  },
                  label: Text(wfT.addWorkflow),
                  icon: const Icon(Icons.auto_awesome),
                )
              : null,
          appBar: AppBar(
            title: Text('OpenCI'),
            bottom: TabBar(
              controller: tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: wfT.tabWorkflows),
                Tab(text: wfT.tabRuns),
                Tab(text: t.storeRelease.title),
              ],
            ),
            actions: [
              TextButton.icon(
                icon: Icon(Symbols.key_rounded),
                label: Text(t.variables.title),
                onPressed: () {
                  Navigator.of(context).push(
                    SwipeablePageRoute(
                      builder: (_) => const VariablesPage(),
                    ),
                  );
                },
              ),
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
                          builder: (_) => const SwitchTeamBottomSheet(),
                        );
                      },
                      child: Text(t.team.switchTeam),
                    ),
                    MenuItemButton(
                      leadingIcon: const Icon(Icons.edit),
                      onPressed: () {
                        showModalBottomSheet(
                          showDragHandle: true,
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => const EditTeamBottomSheet(),
                        );
                      },
                      child: Text(t.team.editTeam),
                    ),
                    MenuItemButton(
                      leadingIcon: const Icon(Icons.add),
                      onPressed: () {
                        showModalBottomSheet(
                          showDragHandle: true,
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => const CreateTeamBottomSheet(),
                        );
                      },
                      child: Text(t.team.createTeam),
                    ),
                    MenuItemButton(
                      leadingIcon: const Icon(Icons.settings),
                      onPressed: () {
                        Navigator.of(context).push(
                          SwipeablePageRoute(
                            builder: (_) => const SettingsPage(),
                          ),
                        );
                      },
                      child: Text(t.nav.settings),
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
          body: MediaQuery.sizeOf(context).width > 800
              ? IndexedStack(
                  index: tabController.index,
                  children: tabChildren,
                )
              : TabBarView(
                  controller: tabController,
                  children: tabChildren,
                ),
        );
      },
    );
  }
}

class _WorkflowBody extends ConsumerWidget {
  const _WorkflowBody({
    required this.selectedRepo,
    required this.selectedBranch,
    required this.onShowSetupSheet,
    required this.onSync,
  });

  final String selectedRepo;
  final String? selectedBranch;
  final VoidCallback onShowSetupSheet;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workflowFilesAsync = ref.watch(workflowFilesProvider);
    final wfT = t.workflow;

    return workflowFilesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: asyncErrorWidget,
      data: (files) {
        if (files.isEmpty) {
          final syncState = ref.watch(syncWorkflowFilesProvider);

          if (syncState.isLoading) {
            return const Center(
              child: CircularProgressIndicator.adaptive(),
            );
          }

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
                  wfT.noWorkflowFiles,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  wfT.addYamlHint,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: onSync,
                  icon: const Icon(Icons.sync),
                  label: const Text('Sync from GitHub'),
                ),
              ],
            ),
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              itemCount: files.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final file = files[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    onTap: () {
                      final branch = ref
                          .read(userProvider)
                          .value
                          ?.selectedBranch;
                      if (branch == null) return;
                      Navigator.of(context).push(
                        SwipeablePageRoute(
                          builder: (context) => CreateWorkflowPage(
                            repository: selectedRepo,
                            branch: branch,
                            teamId: ref.read(teamStateProvider).value?.id ?? '',
                            existingFile: file,
                          ),
                        ),
                      );
                    },
                    title: Text(
                      _extractWorkflowName(file.content) ?? file.name,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Text(
                            file.name,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            selected: file.enabled,
                            showCheckmark: false,
                            avatar: file.enabled
                                ? const Icon(Icons.check, size: 14)
                                : null,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            padding: EdgeInsets.zero,
                            labelPadding: EdgeInsets.only(
                              left: file.enabled ? 2 : 8,
                              right: 8,
                            ),
                            labelStyle: Theme.of(
                              context,
                            ).textTheme.labelSmall,
                            label: Text(
                              file.enabled
                                  ? t.workflow.enabled
                                  : t.workflow.disabled,
                            ),
                            onSelected: (value) {
                              ref.read(
                                toggleWorkflowEnabledProvider(
                                  fileName: file.name,
                                  enabled: value,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
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
    final wfT = t.workflow;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.github,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 24),
            Text(
              wfT.selectRepo,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              wfT.selectRepoHint,
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
              icon: FaIcon(FontAwesomeIcons.github, size: 18),
              label: Text(wfT.selectRepoButton),
            ),
          ],
        ),
      ),
    );
  }
}
