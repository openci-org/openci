import 'package:dashboard/team/select_team_bottom_sheet.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/workflow/editor/initial_workflow_setup/initial_workflow_setup_bottom_sheet.dart';
import 'package:dashboard/workflow/editor/workflow_editor_page.dart';
import 'package:dashboard/workflow/workflow.dart';
import 'package:dashboard/workflow/workflow_list_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        title: const Text('Workflows'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                showModalBottomSheet(
                  showDragHandle: true,
                  context: context,
                  isScrollControlled: true,
                  builder: (_) {
                    return const SelectTeamBottomSheet();
                  },
                );
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
                        error: (error, stackTrace) => const Center(
                          child: Text('Error'),
                        ),
                        loading: () => const Center(
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      );
                    },
                  ),
                ),
              ),
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
              separatorBuilder: (context, index) => const SizedBox(height: 12),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                workflow.workflowConfig.selectedTriggerType ==
                                        TriggerType.tag
                                    ? Icons.label_outline
                                    : Icons.merge,
                                size: 16,
                                color: Theme.of(context).hintColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                workflow.workflowConfig.selectedTriggerType ==
                                        TriggerType.tag
                                    ? 'Tag'
                                    : (workflow
                                              .workflowConfig
                                              .selectedTriggerBranch ??
                                          'Tag'),
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium,
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.folder_outlined,
                                size: 16,
                                color: Theme.of(context).hintColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                workflow.workflowConfig.selectedRepository,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
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
        error: (error, _) => Center(child: Text('Error: $error')),
        loading: () => Center(child: CircularProgressIndicator.adaptive()),
      ),
    );
  }

  void _showSetupSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => InitialWorkflowSetupBottomSheet(),
    );
  }
}
