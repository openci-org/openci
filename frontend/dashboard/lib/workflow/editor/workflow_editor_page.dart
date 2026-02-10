import 'dart:ui';

import 'package:dashboard/workflow/editor/workflow_editor_provider.dart';
import 'package:dashboard/workflow/editor/workflow_template/choose_workflow_template.dart';
import 'package:dashboard/workflow/workflow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:highlight/languages/shell.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class WorkflowEditorPage extends ConsumerWidget {
  const WorkflowEditorPage({
    super.key,
    required this.workflowId,
  });

  final String workflowId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workflowEditorProvider(workflowId));
    return Scaffold(
      appBar: AppBar(
        title: Text('Workflow Editor'),
      ),
      body: state.when(
        data: (workflow) {
          return StepList(
            steps: workflow.workflowSteps,
            workflowConfig: workflow.workflowConfig,
            documentId: workflow.documentId,
            workflowName: workflow.name,
            workflowId: workflowId,
          );
        },
        error: (error, stackTrace) {
          return Center(
            child: Text('Error: $error'),
          );
        },
        loading: () {
          return Center(
            child: CircularProgressIndicator.adaptive(),
          );
        },
      ),
    );
  }
}

class StepList extends ConsumerWidget {
  const StepList({
    super.key,
    required this.steps,
    required this.workflowConfig,
    required this.documentId,
    required this.workflowName,
    required this.workflowId,
  });
  final List<WorkflowStep> steps;
  final WorkflowConfig workflowConfig;
  final String documentId;
  final String workflowName;
  final String workflowId;

  Widget proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final animValue = Curves.easeInOut.transform(animation.value);
        final scale = lerpDouble(1, 1.04, animValue)!;
        return Transform.scale(
          scale: scale,
          child: Material(
            color: Colors.transparent,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(12),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      // TODO(someone): Use ReorderableListView.separated once the issue is resolved
      // https://github.com/flutter/flutter/issues/76706
      child: ReorderableListView.builder(
        proxyDecorator: proxyDecorator,
        header: Column(
          children: [
            Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (_) => EditBasicInfoBottomSheet(
                      workflowName: workflowName,
                      workflowConfig: workflowConfig,
                      workflowId: workflowId,
                    ),
                  );
                },
                title: Text(
                  workflowName,
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
                            workflowConfig.selectedTriggerType ==
                                    TriggerType.tag
                                ? Icons.label_outline
                                : Icons.merge,
                            size: 16,
                            color: Theme.of(context).hintColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            workflowConfig.selectedTriggerType ==
                                    TriggerType.tag
                                ? 'Tag'
                                : (workflowConfig.selectedTriggerBranch ??
                                    'Tag'),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.folder_outlined,
                            size: 16,
                            color: Theme.of(context).hintColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            workflowConfig.selectedRepository,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (steps.isNotEmpty)
              StepConnector(documentId: documentId, insertAt: 0),
          ],
        ),
        footer: Column(
          children: [
            SizedBox(height: 8),
            IconButton.filled(
              onPressed: () => showModalBottomSheet(
                showDragHandle: true,
                isScrollControlled: true,
                context: context,
                builder: (_) => SizedBox(
                  height: MediaQuery.of(context).size.height * 0.8,
                  child: ChooseWorkflowTemplate(documentId: documentId),
                ),
              ),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        itemBuilder: (context, index) {
          final step = steps[index];
          return Column(
            key: ValueKey('step_$index'),
            children: [
              StepCard(
                title: step.name,
                command: step.command,
                isCompleted: step.isCompleted,
                workflowId: workflowId,
                stepIndex: index,
              ),
              if (index < steps.length - 1)
                StepConnector(documentId: documentId, insertAt: index + 1),
            ],
          );
        },
        itemCount: steps.length,
        onReorder: (oldIndex, newIndex) {
          ref
              .read(workflowEditorProvider(workflowId).notifier)
              .reorderSteps(oldIndex, newIndex);
        },
      ),
    );
  }
}

class EditBasicInfoBottomSheet extends HookConsumerWidget {
  const EditBasicInfoBottomSheet({
    super.key,
    required this.workflowName,
    required this.workflowConfig,
    required this.workflowId,
  });

  final String workflowName;
  final WorkflowConfig workflowConfig;
  final String workflowId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController(text: workflowName);
    final repositoryController = useTextEditingController(
      text: workflowConfig.selectedRepository,
    );
    final workingDirectoryController = useTextEditingController(
      text: workflowConfig.selectedWorkingDirectory,
    );
    final triggerBranchController = useTextEditingController(
      text: workflowConfig.selectedTriggerBranch ?? '',
    );
    final selectedTriggerType = useState(workflowConfig.selectedTriggerType);
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  Text(
                    'Edit Basic Information',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Workflow Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: repositoryController,
                    decoration: InputDecoration(
                      labelText: 'Repository',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: workingDirectoryController,
                    decoration: InputDecoration(
                      labelText: 'Current Working Directory',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  DropdownMenu(
                    expandedInsets: EdgeInsets.zero,
                    controller: TextEditingController(
                      text: selectedTriggerType.value.toString(),
                    ),
                    label: const Text('Trigger Type'),
                    dropdownMenuEntries: [
                      DropdownMenuEntry(value: 'push', label: 'push'),
                      DropdownMenuEntry(
                        value: 'pullRequest',
                        label: 'pullRequest',
                      ),
                      DropdownMenuEntry(value: 'tag', label: 'tag'),
                    ],
                    onSelected: (value) {
                      if (value == null) return;
                      selectedTriggerType.value = TriggerType.fromValue(value);
                    },
                  ),
                  if (selectedTriggerType.value != TriggerType.tag) ...[
                    SizedBox(height: 16),
                    TextFormField(
                      controller: triggerBranchController,
                      decoration: InputDecoration(
                        labelText: 'Trigger Branch',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  SizedBox(height: 24),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: Size(double.infinity, 48),
                    ),
                    onPressed: () async {
                      final notifier = ref.read(
                        workflowEditorProvider(workflowId).notifier,
                      );

                      await notifier.updateName(nameController.text);

                      final triggerBranch =
                          selectedTriggerType.value == TriggerType.tag
                              ? null
                              : triggerBranchController.text;

                      await notifier.updateWorkflowConfig(
                        WorkflowConfig(
                          selectedRepository: repositoryController.text,
                          selectedWorkingDirectory:
                              workingDirectoryController.text,
                          selectedTriggerType: selectedTriggerType.value,
                          selectedTriggerBranch: triggerBranch,
                        ),
                      );

                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                    },
                    icon: Icon(Icons.check),
                    label: Text('Save'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StepConnector extends StatelessWidget {
  const StepConnector({
    required this.documentId,
    required this.insertAt,
    super.key,
  });
  final String documentId;
  final int insertAt;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 2,
            height: 52,
            color: Colors.black26,
          ),
          IconButton(
            iconSize: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(
                Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              iconColor: WidgetStatePropertyAll(
                Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            onPressed: () => showModalBottomSheet(
              isScrollControlled: true,
              showDragHandle: true,
              context: context,
              builder: (_) => SizedBox(
                height: MediaQuery.of(context).size.height * 0.8,
                child: ChooseWorkflowTemplate(
                  documentId: documentId,
                  insertAt: insertAt,
                ),
              ),
            ),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class StepCard extends ConsumerWidget {
  const StepCard({
    required this.title,
    required this.command,
    required this.isCompleted,
    required this.workflowId,
    required this.stepIndex,
    super.key,
  });
  final bool isCompleted;
  final String title;
  final String command;
  final String workflowId;
  final int stepIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => EditStepBottomSheet(
              stepName: title,
              stepCommand: command,
              workflowId: workflowId,
              stepIndex: stepIndex,
            ),
          );
        },
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
                size: 20,
              ),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Step'),
                    content: Text('Are you sure you want to delete this step?'),
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
                  await ref
                      .read(workflowEditorProvider(workflowId).notifier)
                      .deleteStep(stepIndex);
                }
              },
            ),
            Icon(
              Icons.drag_handle,
              color: Theme.of(context).hintColor,
            ),
          ],
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              Icon(
                Symbols.deployed_code,
                size: 16,
                color: Theme.of(context).hintColor,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  command,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditStepBottomSheet extends HookConsumerWidget {
  const EditStepBottomSheet({
    super.key,
    required this.stepName,
    required this.stepCommand,
    required this.workflowId,
    required this.stepIndex,
  });

  final String stepName;
  final String stepCommand;
  final String workflowId;
  final int stepIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController(text: stepName);
    final codeController = useState(
      CodeController(
        text: stepCommand,
        language: shell,
      ),
    );

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        children: [
          Text(
            'Edit Step',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step Name',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Build iOS App',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Command',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CodeTheme(
                      data: CodeThemeData(),
                      child: CodeField(
                        controller: codeController.value,
                        minLines: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
              ),
              onPressed: () async {
                final notifier = ref.read(
                  workflowEditorProvider(workflowId).notifier,
                );

                await notifier.updateWorkflowStep(
                  index: stepIndex,
                  step: WorkflowStep(
                    name: nameController.text,
                    command: codeController.value.text,
                    isCompleted: false,
                  ),
                );

                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
              icon: Icon(Icons.check),
              label: Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
