import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/build_logs/build_logs_page.dart';
import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/settings/settings_page.dart';
import 'package:dashboard/store_release/store_release_page.dart';
import 'package:dashboard/team/create_team_bottom_sheet.dart';
import 'package:dashboard/team/edit_team_bottom_sheet.dart';
import 'package:dashboard/team/invite_team_member_bottom_sheet.dart';
import 'package:dashboard/team/switch_team_bottom_sheet.dart';
import 'package:dashboard/team/team_members_bottom_sheet.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/users/user_provider.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:dashboard/variables/variables_page.dart';
import 'package:dashboard/workflow/ai/ai_workflow_page.dart';
import 'package:dashboard/workflow/editor/initial_workflow_setup/github_connection_provider.dart';
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
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:yaml/yaml.dart';

import 'status_dot.dart';

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

List<String> _extractTriggerKeys(String yamlContent) {
  try {
    final doc = loadYaml(yamlContent);
    if (doc is YamlMap && doc['on'] is YamlMap) {
      return (doc['on'] as YamlMap).keys.cast<String>().toList();
    }
  } catch (_) {}
  return [];
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


    final isGitHubConnected = ref.watch(isGitHubConnectedProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: asyncErrorWidget,
      data: (user) {
        final selectedRepo = user.selectedRepository;
        final selectedBranch = user.selectedBranch;

        Widget buildRepoRequiredTab(Widget child) {
          if (!isGitHubConnected) return const ConnectGitHub();
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
              ? Consumer(
                  builder: (context, ref, _) {
                    final team = ref.watch(teamStateProvider).value;
                    final aiEnabled = team?.aiEnabled ?? true;
                    if (aiEnabled) {
                      return FloatingActionButton.extended(
                        onPressed: () {
                          Navigator.of(context).push(
                            SwipeablePageRoute(
                              fullscreenDialog: true,
                              builder: (_) => AiWorkflowPage(
                                repository: selectedRepo,
                                branch: selectedBranch,
                                teamId: team?.id ?? '',
                              ),
                            ),
                          );
                        },
                        label: Text(wfT.addWorkflow),
                        icon: const Icon(Icons.auto_awesome),
                      );
                    }
                    return FloatingActionButton.extended(
                      onPressed: () {
                        Navigator.of(context).push(
                          SwipeablePageRoute(
                            fullscreenDialog: true,
                            builder: (_) => CreateWorkflowPage(
                              repository: selectedRepo,
                              branch: selectedBranch,
                              teamId: team?.id ?? '',
                            ),
                          ),
                        );
                      },
                      label: Text(wfT.addWorkflow),
                      icon: const Icon(Icons.add),
                    );
                  },
                )
              : null,
          appBar: AppBar(
            title: const Text('OpenCI'),
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
                child: Consumer(
                  builder: (context, ref, child) {
                    final team = ref.watch(teamStateProvider);
                    final authUser = ref.watch(authProvider).value;
                    return team.when(
                      data: (teamData) {
                        return _TeamMenuButton(
                          teamName: teamData.name,
                          email: authUser?.email,
                          initials: getInitials(teamData.name),
                          membersCount: teamData.members.length,
                        );
                      },
                      error: asyncErrorWidget,
                      loading: () => const SizedBox(
                        width: 40,
                        height: 40,
                        child: Center(
                          child: CircularProgressIndicator.adaptive(),
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
                final colorScheme = Theme.of(context).colorScheme;
                final workflowName =
                    _extractWorkflowName(file.content) ?? file.name;
                final triggers = _extractTriggerKeys(file.content);

                return Opacity(
                  opacity: file.enabled ? 1.0 : 0.55,
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
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
                              teamId:
                                  ref.read(teamStateProvider).value?.id ?? '',
                              existingFile: file,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Title row ──
                            Row(
                              children: [
                                StatusDot(active: file.enabled),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    workflowName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // ── File name ──
                            Padding(
                              padding: const EdgeInsets.only(left: 18),
                              child: Text(
                                '.openci/${file.name}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontFamily: 'monospace',
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // ── Trigger chips ──
                            if (triggers.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.only(left: 18),
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: triggers.map((trigger) {
                                    final IconData icon = switch (trigger) {
                                      'push' => Icons.commit,
                                      'pull_request' => Icons.call_merge,
                                      'release' => Icons.new_releases_outlined,
                                      'tag' => Icons.label_outline,
                                      _ => Icons.play_arrow,
                                    };
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            icon,
                                            size: 12,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            trigger,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
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

class ConnectGitHub extends ConsumerWidget {
  const ConnectGitHub({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final githubT = t.github;
    final team = ref.watch(teamStateProvider).value;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: FaIcon(
                  FontAwesomeIcons.github,
                  size: 40,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              githubT.connectTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              githubT.connectDescription,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                final url = Uri.parse(
                  'https://github.com/apps/openci-org/installations/new',
                ).replace(
                  queryParameters: {'state': team?.id ?? ''},
                );
                await url_launcher.launchUrl(url);
              },
              icon: FaIcon(FontAwesomeIcons.github, size: 18),
              label: Text(githubT.connectButton),
            ),
          ],
        ),
      ),
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

class _TeamMenuButton extends StatelessWidget {
  const _TeamMenuButton({
    required this.teamName,
    required this.email,
    required this.initials,
    required this.membersCount,
  });

  final String teamName;
  final String? email;
  final String initials;
  final int membersCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () => _showTeamMenu(context),
      child: Ink(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(alpha: 0.15),
              colorScheme.tertiary.withValues(alpha: 0.15),
            ],
          ),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            initials,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  void _showTeamMenu(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (dialogContext) => Stack(
        children: [
          // Dismiss barrier
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(dialogContext).pop(),
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),
          // Menu popup
          Positioned(
            top: kToolbarHeight + MediaQuery.of(context).padding.top + 4,
            right: 8,
            child: Material(
              elevation: 8,
              shadowColor: colorScheme.shadow.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              color: colorScheme.surfaceContainerHigh,
              child: SizedBox(
                width: 260,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Header ──
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primary.withValues(alpha: 0.08),
                            colorScheme.tertiary.withValues(alpha: 0.05),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  colorScheme.primary.withValues(alpha: 0.2),
                                  colorScheme.tertiary.withValues(alpha: 0.2),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  teamName,
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (email != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    email!,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Team section ──
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _MenuItem(
                            icon: Icons.group_rounded,
                            label: t.team.members,
                            onTap: () {
                              Navigator.of(dialogContext).pop();
                              showModalBottomSheet(
                                showDragHandle: true,
                                context: context,
                                builder: (_) =>
                                    const TeamMembersBottomSheet(),
                              );
                            },
                          ),
                          _MenuItem(
                            icon: Icons.swap_horiz_rounded,
                            label: t.team.switchTeam,
                            onTap: () {
                              Navigator.of(dialogContext).pop();
                              showModalBottomSheet(
                                showDragHandle: true,
                                context: context,
                                isScrollControlled: true,
                                builder: (_) =>
                                    const SwitchTeamBottomSheet(),
                              );
                            },
                          ),
                          _MenuItem(
                            icon: Icons.edit_rounded,
                            label: t.team.editTeam,
                            onTap: () {
                              Navigator.of(dialogContext).pop();
                              showModalBottomSheet(
                                showDragHandle: true,
                                context: context,
                                isScrollControlled: true,
                                builder: (_) =>
                                    const EditTeamBottomSheet(),
                              );
                            },
                          ),
                          _MenuItem(
                            icon: Icons.person_add_rounded,
                            label: t.settings.inviteTeamMember,
                            onTap: () {
                              Navigator.of(dialogContext).pop();
                              showModalBottomSheet(
                                showDragHandle: true,
                                context: context,
                                builder: (_) => SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height *
                                          0.6,
                                  child:
                                      const InviteTeamMemberBottomSheet(),
                                ),
                              );
                            },
                          ),
                          _MenuItem(
                            icon: Icons.group_add_rounded,
                            label: t.team.createTeam,
                            onTap: () {
                              Navigator.of(dialogContext).pop();
                              showModalBottomSheet(
                                showDragHandle: true,
                                context: context,
                                isScrollControlled: true,
                                builder: (_) =>
                                    const CreateTeamBottomSheet(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // ── Divider ──
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),

                    // ── Settings section ──
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _MenuItem(
                        icon: Icons.settings_rounded,
                        label: t.nav.settings,
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          showModalBottomSheet(
                            showDragHandle: true,
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.85,
                              child: const SettingsPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
