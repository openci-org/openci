import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/theme/app_colors.dart';
import 'package:dashboard/theme/theme_provider.dart';

import 'package:dashboard/build_logs/build_logs_page.dart';

import 'package:dashboard/firebase/firebase_config_provider.dart';

import 'package:dashboard/i18n/strings.g.dart';

import 'package:dashboard/settings/settings_page.dart';

import 'package:dashboard/store_release/store_release_page.dart';

import 'package:dashboard/variables/variables_page.dart';

import 'package:dashboard/team/create_team_bottom_sheet.dart';

import 'package:dashboard/team/delete_team_bottom_sheet.dart';

import 'package:dashboard/team/edit_team_bottom_sheet.dart';

import 'package:dashboard/team/invite_team_member_bottom_sheet.dart';

import 'package:dashboard/team/switch_team_bottom_sheet.dart';

import 'package:dashboard/team/team_members_bottom_sheet.dart';

import 'package:dashboard/team/team_provider.dart';

import 'package:dashboard/users/user_provider.dart';

import 'package:dashboard/utilities/async_error_widget.dart';

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
    final tabController = useTabController(initialLength: 4);
    useListenable(tabController);
    final isWorkflowsTab = tabController.index == 2;

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
          return child;
        }

        final tabChildren = [
          buildRepoRequiredTab(const LogsBody()),
          const StoreReleaseBody(),
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
          const VariablesBody(),
        ];

        return Scaffold(
          floatingActionButton:
              isWorkflowsTab && selectedRepo != null && selectedBranch != null
              ? Consumer(
                  builder: (context, ref, _) {
                    final team = ref.watch(teamStateProvider).value;
                    final aiEnabled = team?.aiEnabled ?? true;
                    final fabIcon = aiEnabled ? Icons.auto_awesome : Icons.add;
                    return FloatingActionButton.extended(
                      backgroundColor: AppColors.of(context).surface,
                      foregroundColor: AppColors.of(context).textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: AppColors.of(context).border,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          SwipeablePageRoute(
                            fullscreenDialog: true,
                            builder: (_) => aiEnabled
                                ? AiWorkflowPage(
                                    repository: selectedRepo,
                                    branch: selectedBranch,
                                    teamId: team?.id ?? '',
                                  )
                                : CreateWorkflowPage(
                                    repository: selectedRepo,
                                    branch: selectedBranch,
                                    teamId: team?.id ?? '',
                                  ),
                          ),
                        );
                      },
                      label: Text(
                        wfT.addWorkflow,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      icon: Icon(fabIcon, size: 18),
                    );
                  },
                )
              : null,
          appBar: AppBar(
            titleSpacing: 16,
            title: selectedRepo != null
                ? Row(
                    children: [
                      Flexible(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            showDragHandle: true,
                            backgroundColor: AppColors.of(context).scaffold,
                            builder: (_) => const SelectRepositoryBottomSheet(),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.of(context).borderSubtle,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.of(context).border,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.github,
                                  size: 16,
                                  color: AppColors.of(context).textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    selectedRepo.split('/').last,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.of(context).textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.unfold_more,
                                  size: 14,
                                  color: AppColors.of(context).textTertiary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (selectedBranch != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            '/',
                            style: TextStyle(
                              color: AppColors.of(context).border,
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                        Flexible(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              showDragHandle: true,
                              backgroundColor: AppColors.of(context).scaffold,
                              builder: (_) => SelectBranchBottomSheet(
                                repoFullName: selectedRepo,
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.of(context).borderSubtle,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.of(context).border,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.codeBranch,
                                    size: 12,
                                    color: AppColors.of(context).accent,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      selectedBranch,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.of(context).accent,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.unfold_more,
                                    size: 12,
                                    color: const Color(
                                      0xFF58A6FF,
                                    ).withValues(alpha: 0.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  )
                : null,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.of(context).divider,
                    ),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(4, (index) {
                      final labels = [
                        wfT.tabRuns,
                        t.storeRelease.title,
                        wfT.tabWorkflows,
                        t.variables.title,
                      ];
                      final isSelected = tabController.index == index;
                      return Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => tabController.animateTo(index),
                            hoverColor: AppColors.of(context).borderSubtle,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              curve: Curves.easeOut,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.of(context).border
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                labels[index],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.of(context).textPrimary
                                      : AppColors.of(context).textTertiary,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
            actions: [
              Consumer(
                builder: (context, ref, _) {
                  final configAsync = ref.watch(selfHostedConfigProvider);
                  return configAsync.maybeWhen(
                    data: (config) {
                      if (config == null) return const SizedBox.shrink();
                      return Tooltip(
                        message: 'Self-Hosted: ${config.projectId}',
                        child: Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFD29922,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(
                                0xFFD29922,
                              ).withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.cloud_outlined,
                                size: 12,
                                color: Color(0xFFD29922),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                config.projectId,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFD29922),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
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
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.of(context).borderSubtle,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.of(context).divider,
                    ),
                  ),
                  child: Icon(
                    Icons.layers_outlined,
                    size: 32,
                    color: AppColors.of(context).textTertiary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  wfT.noWorkflowFiles,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.of(context).textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  wfT.addYamlHint,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.of(context).textTertiary,
                  ),
                ),
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: onSync,
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.of(context).divider,
                    foregroundColor: AppColors.of(context).textPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: AppColors.of(context).border,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.sync, size: 16),
                  label: const Text(
                    'Sync from GitHub',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: files.length,
              itemBuilder: (context, index) {
                final file = files[index];
                final workflowName =
                    _extractWorkflowName(file.content) ?? file.name;
                final triggers = _extractTriggerKeys(file.content);

                return Opacity(
                  opacity: file.enabled ? 1.0 : 0.5,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.of(context).surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.of(context).border,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        hoverColor: AppColors.of(context).borderSubtle,
                        splashColor: AppColors.of(context).borderSubtle,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
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
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.of(context).textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: AppColors.of(context).textTertiary,
                                    size: 18,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // ── File name ──
                              Padding(
                                padding: const EdgeInsets.only(left: 18),
                                child: Text(
                                  '.openci/${file.name}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    color: AppColors.of(context).textTertiary,
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
                                        'release' =>
                                          Icons.new_releases_outlined,
                                        'tag' => Icons.label_outline,
                                        _ => Icons.play_arrow,
                                      };
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.of(context).borderSubtle,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: AppColors.of(context).border,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              icon,
                                              size: 11,
                                              color: AppColors.of(context).textTertiary,
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                trigger,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  fontFamily: 'monospace',
                                                  color: AppColors.of(context).textSecondary,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
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

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.of(context).borderSubtle,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.of(context).divider,
                ),
              ),
              child: Center(
                child: FaIcon(
                  FontAwesomeIcons.github,
                  size: 32,
                  color: AppColors.of(context).textTertiary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              githubT.connectTitle,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.of(context).textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              githubT.connectDescription,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.of(context).textTertiary,
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () async {
                final url =
                    Uri.parse(
                      'https://github.com/apps/openci-org/installations/new',
                    ).replace(
                      queryParameters: {'state': team?.id ?? ''},
                    );
                await url_launcher.launchUrl(url);
              },
              style: TextButton.styleFrom(
                backgroundColor: AppColors.of(context).divider,
                foregroundColor: AppColors.of(context).textPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: AppColors.of(context).border,
                  ),
                ),
              ),
              icon: FaIcon(
                FontAwesomeIcons.github,
                size: 16,
                color: AppColors.of(context).textPrimary,
              ),
              label: Text(
                githubT.connectButton,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.of(context).borderSubtle,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.of(context).divider,
                ),
              ),
              child: Center(
                child: FaIcon(
                  FontAwesomeIcons.github,
                  size: 32,
                  color: AppColors.of(context).textTertiary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              wfT.selectRepo,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.of(context).textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              wfT.selectRepoHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.of(context).textTertiary,
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                backgroundColor: AppColors.of(context).scaffold,
                builder: (_) => const SelectRepositoryBottomSheet(),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.of(context).divider,
                foregroundColor: AppColors.of(context).textPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: AppColors.of(context).border,
                  ),
                ),
              ),
              icon: FaIcon(
                FontAwesomeIcons.github,
                size: 16,
                color: AppColors.of(context).textPrimary,
              ),
              label: Text(
                wfT.selectRepoButton,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
    return InkWell(
      customBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      onTap: () => _showTeamMenu(context),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColors.of(context).surfaceHover,
          border: Border.all(
            color: AppColors.of(context).border,
          ),
        ),
        child: Center(
          child: Text(
            initials,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.of(context).textSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  void _showTeamMenu(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
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
          // Menu popup — dark surface, inset ring, no shadow
          Positioned(
            top: kToolbarHeight + MediaQuery.of(context).padding.top + 4,
            right: 8,
            child: Material(
              elevation: 0,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              color: AppColors.of(context).surfaceHover,
              child: Container(
                width: 256,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.of(context).border,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Header ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: AppColors.of(context).surfaceTertiary,
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.of(context).textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  teamName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.of(context).textPrimary,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (email != null) ...[
                                  const SizedBox(height: 1),
                                  Text(
                                    email!,
                                    style: TextStyle(
                                      color: AppColors.of(context).textTertiary,
                                      fontSize: 11,
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

                    // ── Divider ──
                    Divider(
                      height: 1,
                      color: AppColors.of(context).divider,
                    ),

                    // ── Team section ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 6, 6, 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
                            child: Text(
                              'Team',
                              style: TextStyle(
                                color: AppColors.of(context).textTertiary,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          _MenuItem(
                            icon: Icons.group_outlined,
                            label: t.team.members,
                            onTap: () {
                              Navigator.of(dialogContext).pop();
                              showModalBottomSheet(
                                showDragHandle: true,
                                context: context,
                                builder: (_) => const TeamMembersBottomSheet(),
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
                                builder: (_) => const SwitchTeamBottomSheet(),
                              );
                            },
                          ),
                          _MenuItem(
                            icon: Icons.edit_outlined,
                            label: t.team.editTeam,
                            onTap: () {
                              Navigator.of(dialogContext).pop();
                              showModalBottomSheet(
                                showDragHandle: true,
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => const EditTeamBottomSheet(),
                              );
                            },
                          ),
                          _MenuItem(
                            icon: Icons.person_add_outlined,
                            label: t.settings.inviteTeamMember,
                            onTap: () {
                              Navigator.of(dialogContext).pop();
                              showModalBottomSheet(
                                showDragHandle: true,
                                context: context,
                                isScrollControlled: true,
                                builder: (_) =>
                                    const InviteTeamMemberBottomSheet(),
                              );
                            },
                          ),
                          _MenuItem(
                            icon: Icons.group_add_outlined,
                            label: t.team.createTeam,
                            onTap: () {
                              Navigator.of(dialogContext).pop();
                              showModalBottomSheet(
                                showDragHandle: true,
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => const CreateTeamBottomSheet(),
                              );
                            },
                          ),
                          _MenuItem(
                            icon: Icons.delete_outline_rounded,
                            label: t.team.deleteTeam,
                            isDestructive: true,
                            onTap: () {
                              Navigator.of(dialogContext).pop();
                              showModalBottomSheet(
                                showDragHandle: true,
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => const DeleteTeamBottomSheet(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // ── Divider ──
                    Divider(
                      height: 1,
                      color: AppColors.of(context).divider,
                    ),

                    // ── Appearance & Settings section ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Theme toggle
                          Consumer(
                            builder: (ctx, ref, _) {
                              final mode = ref.watch(themeModeProvider);
                              final isDark = mode == ThemeMode.dark;
                              return InkWell(
                                onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                                borderRadius: BorderRadius.circular(8),
                                hoverColor: AppColors.of(context).divider,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                                        size: 18,
                                        color: AppColors.of(context).textPrimary.withValues(alpha: 0.6),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          isDark ? 'Dark Mode' : 'Light Mode',
                                          style: TextStyle(
                                            color: AppColors.of(context).textPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 36,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          color: isDark ? AppColors.of(context).accent : AppColors.of(context).border,
                                        ),
                                        child: AnimatedAlign(
                                          duration: const Duration(milliseconds: 200),
                                          curve: Curves.easeInOut,
                                          alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
                                          child: Container(
                                            width: 16,
                                            height: 16,
                                            margin: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColors.of(context).textPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          _MenuItem(
                            icon: Icons.settings_outlined,
                            label: t.nav.settings,
                            onTap: () {
                              Navigator.of(dialogContext).pop();
                              showModalBottomSheet(
                                showDragHandle: true,
                                context: context,
                                isScrollControlled: true,
                                builder: (sheetContext) => SizedBox(
                                  height:
                                      MediaQuery.of(sheetContext).size.height *
                                      0.85,
                                  child: const SettingsPage(),
                                ),
                              );
                            },
                          ),
                        ],
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
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final itemColor = isDestructive
        ? Colors.red.withValues(alpha: 0.9)
        : AppColors.of(context).textPrimary;
    final hoverColor = isDestructive
        ? Colors.red.withValues(alpha: 0.08)
        : AppColors.of(context).divider;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      hoverColor: hoverColor,
      splashColor: hoverColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: itemColor.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: itemColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
