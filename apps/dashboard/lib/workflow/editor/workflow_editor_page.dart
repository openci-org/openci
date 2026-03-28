import 'dart:ui';

import 'package:dashboard/workflow/editor/workflow_editor_provider.dart';
import 'package:dashboard/workflow/workflow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/bash.dart';
import 'package:re_highlight/styles/monokai.dart';

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
    required this.workflowName,
    required this.workflowId,
  });
  final List<WorkflowStep> steps;
  final WorkflowConfig workflowConfig;
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
                          for (final entry
                              in workflowConfig.triggers.entries) ...[
                            Icon(
                              switch (entry.key) {
                                'tag' => Icons.label_outline,
                                'push' => FontAwesomeIcons.codeCommit,
                                'pull_request' || 'pullRequest' =>
                                  FontAwesomeIcons.codePullRequest,
                                'release' => Icons.new_releases_outlined,
                                _ => Icons.play_arrow,
                              },
                              size: 16,
                              color: Theme.of(context).hintColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              entry.value != null && entry.value!.isNotEmpty
                                  ? '${entry.key}:${entry.value}'
                                  : entry.key,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(width: 12),
                          ],
                          Icon(
                            FontAwesomeIcons.github,
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
              StepConnector(workflowId: workflowId, insertAt: 0),
          ],
        ),
        footer: Column(
          children: [
            SizedBox(height: 8),
            IconButton.filled(
              onPressed: () => ref
                  .read(workflowEditorProvider(workflowId).notifier)
                  .addStep(),
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
                step: step,
                workflowId: workflowId,
                stepIndex: index,
              ),
              if (index < steps.length - 1)
                StepConnector(workflowId: workflowId, insertAt: index + 1),
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
    final triggers = useState(
      Map<String, String?>.from(workflowConfig.triggers),
    );

    final pushBranchController = useTextEditingController(
      text: workflowConfig.triggers['push'] ?? '',
    );
    final prBranchController = useTextEditingController(
      text: workflowConfig.triggers['pull_request'] ?? '',
    );

    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: SizedBox(
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Triggers',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: TriggerType.values
                          .map(
                            (type) => FilterChip(
                              label: Text(type.toString()),
                              selected: triggers.value.containsKey(
                                type.toString(),
                              ),
                              onSelected: (selected) {
                                final current = Map<String, String?>.from(
                                  triggers.value,
                                );
                                final key = type.toString();
                                if (selected) {
                                  final needsBranch =
                                      type == TriggerType.push ||
                                      type == TriggerType.pullRequest;
                                  current[key] = needsBranch ? 'main' : null;
                                } else {
                                  current.remove(key);
                                }
                                if (current.isEmpty) return;
                                triggers.value = current;
                              },
                            ),
                          )
                          .toList(),
                    ),
                    if (triggers.value.containsKey('push')) ...[
                      SizedBox(height: 12),
                      TextFormField(
                        controller: pushBranchController,
                        decoration: InputDecoration(
                          labelText: 'push branch',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          final current = Map<String, String?>.from(
                            triggers.value,
                          );
                          current['push'] = value;
                          triggers.value = current;
                        },
                      ),
                    ],
                    if (triggers.value.containsKey('pull_request')) ...[
                      SizedBox(height: 12),
                      TextFormField(
                        controller: prBranchController,
                        decoration: InputDecoration(
                          labelText: 'pull_request branch',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          final current = Map<String, String?>.from(
                            triggers.value,
                          );
                          current['pull_request'] = value;
                          triggers.value = current;
                        },
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

                        await notifier.updateWorkflowConfig(
                          WorkflowConfig(
                            selectedRepository: repositoryController.text,
                            selectedWorkingDirectory:
                                workingDirectoryController.text,
                            triggers: triggers.value,
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
      ),
    );
  }
}

class StepConnector extends ConsumerWidget {
  const StepConnector({
    required this.workflowId,
    required this.insertAt,
    super.key,
  });
  final String workflowId;
  final int insertAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            onPressed: () => ref
                .read(workflowEditorProvider(workflowId).notifier)
                .addStep(insertAt: insertAt),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class StepCard extends ConsumerWidget {
  const StepCard({
    required this.step,
    required this.workflowId,
    required this.stepIndex,
    super.key,
  });
  final WorkflowStep step;
  final String workflowId;
  final int stepIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
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
              stepName: step.name,
              stepCommand: step.command,
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
                FontAwesomeIcons.trashCan,
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
          ],
        ),
        title: Text(
          step.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              Icon(
                FontAwesomeIcons.code,
                size: 16,
                color: Theme.of(context).hintColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  step.command,
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
      CodeLineEditingController.fromText(stepCommand),
    );

    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: SizedBox(
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
                      child: SizedBox(
                        height: 200,
                        child: CodeEditor(
                          padding: EdgeInsets.only(
                            top: 12,
                            left: 12,
                            right: 12,
                            bottom: 12,
                          ),
                          controller: codeController.value,
                          wordWrap: true,
                          borderRadius: BorderRadius.circular(12),
                          style: CodeEditorStyle(
                            fontSize: 14,
                            backgroundColor: const Color(0xFF1E1E1E),
                            textColor: Colors.white,
                            codeTheme: CodeHighlightTheme(
                              languages: {
                                'bash': CodeHighlightThemeMode(mode: langBash),
                              },
                              theme: monokaiTheme,
                            ),
                          ),
                          indicatorBuilder:
                              (
                                context,
                                editingController,
                                chunkController,
                                notifier,
                              ) {
                                return Row(
                                  children: [
                                    DefaultCodeLineNumber(
                                      controller: editingController,
                                      notifier: notifier,
                                    ),
                                  ],
                                );
                              },
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
      ),
    );
  }
}
