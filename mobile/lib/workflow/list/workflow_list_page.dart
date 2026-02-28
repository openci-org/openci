import 'package:dashboard/extensions/date_time_extensions.dart';
import 'package:dashboard/team/create_team_bottom_sheet.dart';
import 'package:dashboard/team/edit_team_bottom_sheet.dart';
import 'package:dashboard/team/switch_team_bottom_sheet.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:dashboard/workflow/editor/initial_workflow_setup/initial_workflow_setup_bottom_sheet.dart';
import 'package:dashboard/workflow/editor/workflow_editor_page.dart';
import 'package:dashboard/workflow/list/git_context_provider.dart';
import 'package:dashboard/workflow/list/workflow_list_provider.dart';
import 'package:dashboard/workflow/mock_workflow_data.dart';
import 'package:dashboard/workflow/yaml_workflow_converter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:yaml/yaml.dart';

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

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        toolbarHeight: 56,
        title: Consumer(
          builder: (context, ref, _) {
            final gitContext = ref.watch(gitContextProvider);
            final colorScheme = Theme.of(context).colorScheme;
            final shortSha = gitContext.commitSha != null
                ? (gitContext.commitSha!.length > 7
                      ? gitContext.commitSha!.substring(0, 7)
                      : gitContext.commitSha!)
                : null;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  showDragHandle: true,
                  isScrollControlled: true,
                  builder: (_) => const FractionallySizedBox(
                    heightFactor: 0.7,
                    child: _GitContextSheet(),
                  ),
                );
              },
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withValues(alpha: 0.12),
                          colorScheme.surfaceContainerHighest,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(
                        FontAwesomeIcons.github,
                        size: 18,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          gitContext.repository,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              FontAwesomeIcons.codeBranch,
                              size: 9,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              gitContext.branch,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'monospace',
                                color: colorScheme.primary,
                              ),
                            ),
                            if (shortSha != null) ...[
                              Text(
                                ' · ',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                shortSha,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.unfold_more,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            );
          },
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
                          if (useMockData) {
                            return Text(
                              'OC',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).primaryColor,
                              ),
                            );
                          }
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
      body: workflowList.when(
        data: (workflows) {
          if (workflows.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Theme.of(context).colorScheme.primaryContainer
                                .withValues(alpha: 0.5),
                            Theme.of(context).colorScheme.primaryContainer
                                .withValues(alpha: 0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.rocket_launch_outlined,
                        size: 36,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No workflows yet',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first CI/CD workflow to start\nautomating builds and deployments.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      onPressed: () => _showSetupSheet(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Workflow'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              final branch = ref.read(gitContextProvider).branch;
              ref.invalidate(workflowListProvider);
              ref.invalidate(gitBranchesProvider);
              ref.invalidate(gitCommitsProvider(branch));
              await ref.read(workflowListProvider.future);
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: workflows.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final workflow = workflows[index];
                return _WorkflowCard(workflow: workflow);
              },
            ),
          );
        },
        error: asyncErrorWidget,
        loading: () => Center(child: CircularProgressIndicator.adaptive()),
      ),
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

class _WorkflowCard extends ConsumerWidget {
  const _WorkflowCard({required this.workflow});
  final WorkflowListItem workflow;

  Color _statusColor(String? status) {
    return switch (status) {
      'success' => Colors.green,
      'failure' => Colors.red,
      'in_progress' => Colors.blue,
      'queued' => Colors.orange,
      'cancelled' => Colors.grey,
      _ => Colors.transparent,
    };
  }

  List<String> _parseTriggerTypes() {
    if (workflow.yamlDefinition.isEmpty) return [];
    try {
      final yamlMap = loadYaml(workflow.yamlDefinition);
      if (yamlMap is Map) {
        final parsed = YamlWorkflowConverter.fromYamlMap(
          Map<String, dynamic>.from(yamlMap),
        );
        final types = <String>[];
        if (parsed.on.push != null) types.add('push');
        if (parsed.on.pullRequest != null) types.add('pr');
        if (parsed.on.tag == true) types.add('tag');
        if (parsed.on.release != null) types.add('release');
        return types;
      }
    } catch (_) {}
    return [];
  }

  int _parseStepCount() {
    if (workflow.yamlDefinition.isEmpty) return 0;
    try {
      final yamlMap = loadYaml(workflow.yamlDefinition);
      if (yamlMap is Map) {
        final parsed = YamlWorkflowConverter.fromYamlMap(
          Map<String, dynamic>.from(yamlMap),
        );
        return parsed.steps.length;
      }
    } catch (_) {}
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasStatus = workflow.lastBuildStatus != null;
    final triggerTypes = _parseTriggerTypes();
    final stepCount = _parseStepCount();

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => WorkflowEditorPage(
                workflowId: workflow.id,
              ),
            ),
          );
        },
        child: IntrinsicHeight(
          child: Row(
            children: [
              if (hasStatus)
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: _statusColor(workflow.lastBuildStatus),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: hasStatus ? 12 : 16,
                    right: 4,
                    top: 12,
                    bottom: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              workflow.name,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (hasStatus)
                            _BuildStatusBadge(
                              status: workflow.lastBuildStatus!,
                            ),
                          _CardMenu(
                            workflow: workflow,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.description_outlined,
                                  size: 10,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  workflow.filePath.split('/').last,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (stepCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.layers_outlined,
                                    size: 10,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '$stepCount steps',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (triggerTypes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: triggerTypes.map((type) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer.withValues(
                                  alpha: 0.5,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    FontAwesomeIcons.bolt,
                                    size: 8,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    type,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      if (workflow.lastBuildAt != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 11,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              workflow.lastBuildAt!.toTimeAgoEn(),
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
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

class _CardMenu extends ConsumerWidget {
  const _CardMenu({required this.workflow});
  final WorkflowListItem workflow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz,
        size: 20,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onSelected: (value) async {
        switch (value) {
          case 'duplicate':
            try {
              await ref
                  .read(workflowListProvider.notifier)
                  .duplicateWorkflow(workflow);
              if (!context.mounted) return;
              context.showSnackBarMessage('Workflow duplicated');
            } catch (e) {
              if (!context.mounted) return;
              context.showSnackBarMessage('Failed to duplicate: $e');
            }
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
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
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
                    .deleteWorkflow(workflow.id);
                if (!context.mounted) return;
                context.showSnackBarMessage('Workflow deleted');
              } catch (e) {
                if (!context.mounted) return;
                context.showSnackBarMessage('Failed to delete: $e');
              }
            }
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'duplicate',
          child: Row(
            children: [
              Icon(
                Icons.copy,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                size: 18,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 12),
              Text(
                'Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GitContextSheet extends HookConsumerWidget {
  const _GitContextSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gitContext = ref.watch(gitContextProvider);
    final branches = ref.watch(gitBranchesProvider);
    final selectedBranch = useState(gitContext.branch);
    final commits = ref.watch(gitCommitsProvider(selectedBranch.value));
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Switch Branch & Commit',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            gitContext.repository,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Branch',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: branches.when(
            data: (branchList) => ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: branchList.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final branch = branchList[index];
                final isSelected = branch.name == selectedBranch.value;
                return FilterChip(
                  selected: isSelected,
                  label: Text(
                    branch.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      fontWeight: isSelected ? FontWeight.w600 : null,
                    ),
                  ),
                  avatar: Icon(FontAwesomeIcons.codeBranch, size: 12),
                  onSelected: (_) {
                    selectedBranch.value = branch.name;
                  },
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
            error: (e, _) => Text('Error: $e'),
            loading: () => const Center(
              child: CircularProgressIndicator.adaptive(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Commits',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: commits.when(
            data: (commitList) => ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: commitList.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final commit = commitList[index];
                final shortSha = commit.sha.length > 7
                    ? commit.sha.substring(0, 7)
                    : commit.sha;
                final isSelected =
                    gitContext.commitSha != null &&
                    commit.sha.startsWith(
                      gitContext.commitSha!.length > 7
                          ? gitContext.commitSha!.substring(0, 7)
                          : gitContext.commitSha!,
                    ) &&
                    gitContext.branch == selectedBranch.value;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  selected: isSelected,
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                    ),
                    child: Center(
                      child: Icon(
                        isSelected ? Icons.check : Icons.commit,
                        size: 16,
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  title: Text(
                    commit.message,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '$shortSha · ${commit.author} · ${commit.date.toTimeAgoEn()}',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onTap: () {
                    ref
                        .read(gitContextProvider.notifier)
                        .switchBranch(
                          selectedBranch.value,
                          commitSha: commit.sha,
                          commitMessage: commit.message,
                        );
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
            error: (e, _) => Center(child: Text('Error: $e')),
            loading: () => const Center(
              child: CircularProgressIndicator.adaptive(),
            ),
          ),
        ),
      ],
    );
  }
}

class _BuildStatusBadge extends StatelessWidget {
  const _BuildStatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (status) {
      'success' => (Icons.check_circle, Colors.green, 'Passed'),
      'failure' => (Icons.cancel, Colors.red, 'Failed'),
      'in_progress' => (Icons.sync, Colors.blue, 'Running'),
      'queued' => (Icons.schedule, Colors.orange, 'Queued'),
      'cancelled' => (Icons.block, Colors.grey, 'Cancelled'),
      _ => (Icons.help_outline, Colors.grey, 'Unknown'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == 'in_progress')
            SizedBox(
              width: 11,
              height: 11,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: color,
              ),
            )
          else
            Icon(icon, color: color, size: 11),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
