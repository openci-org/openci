import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:dashboard/workflow/list/create_workflow_file_provider.dart';
import 'package:dashboard/workflow/list/github_actions_provider.dart';
import 'package:dashboard/workflow/list/github_repository_provider.dart';
import 'package:dashboard/workflow/list/search_actions_sheet.dart';
import 'package:dashboard/workflow/list/workflow_file_provider.dart';
import 'package:dashboard/workflow/list/workflow_yaml_converter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/yaml.dart';
import 'package:re_highlight/styles/monokai.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class CreateWorkflowPage extends HookConsumerWidget {
  const CreateWorkflowPage({
    super.key,
    required this.repository,
    required this.branch,
  });

  final String repository;
  final String branch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabController = useTabController(initialLength: 2);
    final workflowName = useState('my-workflow');
    final triggerType = useState('push');
    final triggerBranch = useState('main');
    final steps = useState<List<WorkflowYamlStep>>([
      WorkflowYamlStep(name: 'Build', run: 'echo "Hello, OpenCI!"'),
    ]);
    final yamlController = useState(
      CodeLineEditingController.fromText(
        stepsToYaml(
          WorkflowYamlConfig(
            name: 'my-workflow',
            triggerType: 'push',
            triggerBranches: ['main'],
            steps: [
              WorkflowYamlStep(name: 'Build', run: 'echo "Hello, OpenCI!"'),
            ],
          ),
        ),
      ),
    );
    final fileName = useState('workflow.yaml');
    final isLoading = useState(false);
    final isSyncingFromEditor = useState(false);
    final isSyncingFromYaml = useState(false);

    void syncEditorToYaml() {
      if (isSyncingFromYaml.value) return;
      isSyncingFromEditor.value = true;
      final yaml = stepsToYaml(
        WorkflowYamlConfig(
          name: workflowName.value,
          triggerType: triggerType.value,
          triggerBranches: [triggerBranch.value],
          steps: steps.value,
        ),
      );
      yamlController.value = CodeLineEditingController.fromText(yaml);
      isSyncingFromEditor.value = false;
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Create Workflow'),
            Text(
              '$repository ($branch)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(icon: Icon(Icons.view_list), text: 'Editor'),
            Tab(icon: Icon(Icons.code), text: 'YAML'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: isLoading.value
                  ? null
                  : () => _showCommitDialog(
                      context: context,
                      ref: ref,
                      yamlController: yamlController,
                      fileName: fileName,
                      isLoading: isLoading,
                      workflowName: workflowName,
                      triggerType: triggerType,
                      triggerBranch: triggerBranch,
                      steps: steps,
                      tabController: tabController,
                    ),
              icon: isLoading.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save, size: 18),
              label: const Text('Save'),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          _EditorTab(
            repository: repository,
            workflowName: workflowName,
            triggerType: triggerType,
            triggerBranch: triggerBranch,
            steps: steps,
            onChanged: syncEditorToYaml,
          ),
          _YamlTab(
            yamlController: yamlController,
            onChanged: () {
              if (isSyncingFromEditor.value) return;
              isSyncingFromYaml.value = true;
              final config = yamlToConfig(yamlController.value.text);
              if (config != null) {
                workflowName.value = config.name;
                triggerType.value = config.triggerType;
                triggerBranch.value = config.triggerBranches.isNotEmpty
                    ? config.triggerBranches.first
                    : 'main';
                steps.value = config.steps;
              }
              isSyncingFromYaml.value = false;
            },
          ),
        ],
      ),
    );
  }

  void _showCommitDialog({
    required BuildContext context,
    required WidgetRef ref,
    required ValueNotifier<CodeLineEditingController> yamlController,
    required ValueNotifier<String> fileName,
    required ValueNotifier<bool> isLoading,
    required ValueNotifier<String> workflowName,
    required ValueNotifier<String> triggerType,
    required ValueNotifier<String> triggerBranch,
    required ValueNotifier<List<WorkflowYamlStep>> steps,
    required TabController tabController,
  }) {
    final currentYaml = yamlController.value.text;

    if (tabController.index == 0) {
      final yaml = stepsToYaml(
        WorkflowYamlConfig(
          name: workflowName.value,
          triggerType: triggerType.value,
          triggerBranches: [triggerBranch.value],
          steps: steps.value,
        ),
      );
      yamlController.value = CodeLineEditingController.fromText(yaml);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CommitBottomSheet(
        repository: repository,
        branch: branch,
        yamlContent: tabController.index == 0
            ? stepsToYaml(
                WorkflowYamlConfig(
                  name: workflowName.value,
                  triggerType: triggerType.value,
                  triggerBranches: [triggerBranch.value],
                  steps: steps.value,
                ),
              )
            : currentYaml,
        fileName: fileName,
        isLoading: isLoading,
      ),
    );
  }
}

class _EditorTab extends HookConsumerWidget {
  const _EditorTab({
    required this.repository,
    required this.workflowName,
    required this.triggerType,
    required this.triggerBranch,
    required this.steps,
    required this.onChanged,
  });

  final String repository;
  final ValueNotifier<String> workflowName;
  final ValueNotifier<String> triggerType;
  final ValueNotifier<String> triggerBranch;
  final ValueNotifier<List<WorkflowYamlStep>> steps;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController(text: workflowName.value);
    final branchesAsync = ref.watch(gitHubBranchesProvider(repository));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Basic Info',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Workflow Name',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    workflowName.value = value;
                    onChanged();
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: triggerType.value,
                  decoration: const InputDecoration(
                    labelText: 'Trigger Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'push', child: Text('push')),
                    DropdownMenuItem(
                      value: 'pull_request',
                      child: Text('pull_request'),
                    ),
                    DropdownMenuItem(value: 'release', child: Text('release')),
                    DropdownMenuItem(value: 'tag', child: Text('tag')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      triggerType.value = value;
                      onChanged();
                    }
                  },
                ),
                if (triggerType.value != 'tag' &&
                    triggerType.value != 'release') ...[
                  const SizedBox(height: 12),
                  branchesAsync.when(
                    loading: () => TextFormField(
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Loading branches...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    error: (e, _) => TextFormField(
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Trigger Branch',
                        border: const OutlineInputBorder(),
                        suffixIcon: Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                    data: (branches) => Autocomplete<String>(
                      initialValue: TextEditingValue(
                        text: branches.contains(triggerBranch.value)
                            ? triggerBranch.value
                            : '',
                      ),
                      optionsBuilder: (textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return branches;
                        }
                        return branches.where(
                          (b) => b.toLowerCase().contains(
                            textEditingValue.text.toLowerCase(),
                          ),
                        );
                      },
                      fieldViewBuilder:
                          (
                            context,
                            controller,
                            focusNode,
                            onFieldSubmitted,
                          ) {
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                labelText: 'Trigger Branch',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.search, size: 20),
                              ),
                            );
                          },
                      onSelected: (value) {
                        triggerBranch.value = value;
                        onChanged();
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(steps.value.length, (index) {
          final step = steps.value[index];
          return Column(
            children: [
              _StepConnectorLine(
                onInsert: () {
                  final newSteps = List<WorkflowYamlStep>.from(steps.value);
                  newSteps.insert(
                    index,
                    WorkflowYamlStep(name: 'New Step', run: 'echo "hello"'),
                  );
                  steps.value = newSteps;
                  onChanged();
                },
              ),
              _StepEditorCard(
                step: step,
                stepIndex: index,
                onUpdate: (updated) {
                  final newSteps = List<WorkflowYamlStep>.from(steps.value);
                  newSteps[index] = updated;
                  steps.value = newSteps;
                  onChanged();
                },
                onDelete: () {
                  final newSteps = List<WorkflowYamlStep>.from(steps.value);
                  newSteps.removeAt(index);
                  steps.value = newSteps;
                  onChanged();
                },
              ),
            ],
          );
        }),
        const SizedBox(height: 8),
        Center(
          child: IconButton.filled(
            onPressed: () {
              final newSteps = List<WorkflowYamlStep>.from(steps.value);
              newSteps.add(
                WorkflowYamlStep(name: 'New Step', run: 'echo "hello"'),
              );
              steps.value = newSteps;
              onChanged();
            },
            icon: const Icon(Icons.add),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _StepConnectorLine extends StatelessWidget {
  const _StepConnectorLine({required this.onInsert});

  final VoidCallback onInsert;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 2,
            height: 44,
            color: Colors.black26,
          ),
          IconButton(
            iconSize: 14,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(
                Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              iconColor: WidgetStatePropertyAll(
                Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            onPressed: onInsert,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _StepEditorCard extends StatelessWidget {
  const _StepEditorCard({
    required this.step,
    required this.stepIndex,
    required this.onUpdate,
    required this.onDelete,
  });

  final WorkflowYamlStep step;
  final int stepIndex;
  final ValueChanged<WorkflowYamlStep> onUpdate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        onTap: () => _showEditSheet(context),
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            '${stepIndex + 1}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        title: Text(
          step.name,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(
                step.type == StepType.uses ? Icons.extension : Icons.terminal,
                size: 14,
                color: Theme.of(context).hintColor,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  step.type == StepType.uses ? step.uses : step.run,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: Theme.of(context).colorScheme.error,
            size: 20,
          ),
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete Step'),
                content: const Text(
                  'Are you sure you want to delete this step?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              onDelete();
            }
          },
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _EditStepSheet(
        step: step,
        onSave: onUpdate,
      ),
    );
  }
}

class _EditStepSheet extends HookConsumerWidget {
  const _EditStepSheet({
    required this.step,
    required this.onSave,
  });

  final WorkflowYamlStep step;
  final ValueChanged<WorkflowYamlStep> onSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController(text: step.name);
    final runController = useTextEditingController(text: step.run);
    final usesController = useTextEditingController(text: step.uses);
    final stepType = useState(step.type);
    final withParams = useState(Map<String, String>.from(step.withParams));
    final usesValue = useState(step.uses);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    final inputsAsync = usesValue.value.isNotEmpty
        ? ref.watch(
            actionInputsProvider(actionRef: usesValue.value),
          )
        : null;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Text(
              'Edit Step',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step Name',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Build iOS App',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Type',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<StepType>(
                      segments: const [
                        ButtonSegment(
                          value: StepType.run,
                          label: Text('run'),
                          icon: Icon(Icons.terminal, size: 16),
                        ),
                        ButtonSegment(
                          value: StepType.uses,
                          label: Text('uses'),
                          icon: Icon(Icons.extension, size: 16),
                        ),
                      ],
                      selected: {stepType.value},
                      onSelectionChanged: (v) => stepType.value = v.first,
                    ),
                    const SizedBox(height: 16),
                    if (stepType.value == StepType.run) ...[
                      Text(
                        'Command',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: runController,
                        maxLines: 5,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'echo "hello"',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Action',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: usesController,
                        readOnly: true,
                        onTap: () async {
                          final usesRef = await SearchActionsSheet.show(
                            context,
                          );
                          if (usesRef != null) {
                            usesController.text = usesRef;
                            usesValue.value = usesRef;
                            withParams.value = {};
                          }
                        },
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Tap to search actions',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.search),
                        ),
                      ),
                      if (usesValue.value.contains('@')) ...[
                        const SizedBox(height: 12),
                        Builder(
                          builder: (context) {
                            final parts = usesValue.value.split('@');
                            final fullName = parts.first;
                            final currentTag = parts.length > 1 ? parts[1] : '';
                            final tagsAsync = ref.watch(
                              actionTagsProvider(fullName: fullName),
                            );
                            return tagsAsync.when(
                              loading: () => const Text('Loading versions...'),
                              error: (_, _) => const SizedBox.shrink(),
                              data: (tags) {
                                if (tags.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                final effectiveTags = tags.contains(currentTag)
                                    ? tags
                                    : [currentTag, ...tags];
                                return DropdownButtonFormField<String>(
                                  initialValue: currentTag,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Version',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  items: effectiveTags
                                      .map(
                                        (tag) => DropdownMenuItem(
                                          value: tag,
                                          child: Text(
                                            tag,
                                            style: const TextStyle(
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (tag) {
                                    if (tag != null) {
                                      final newRef = '$fullName@$tag';
                                      usesController.text = newRef;
                                      usesValue.value = newRef;
                                    }
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        'with',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      if (inputsAsync != null)
                        inputsAsync.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: Text('Loading inputs...'),
                            ),
                          ),
                          error: (e, _) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Could not load inputs',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context).hintColor,
                                  ),
                            ),
                          ),
                          data: (inputs) {
                            if (inputs.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Text(
                                  'No inputs defined for this action',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context).hintColor,
                                      ),
                                ),
                              );
                            }
                            return Column(
                              children: inputs.map((input) {
                                final isEnabled = withParams.value.containsKey(
                                  input.key,
                                );
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: Checkbox(
                                              value: isEnabled,
                                              onChanged: (v) {
                                                final updated =
                                                    Map<String, String>.from(
                                                      withParams.value,
                                                    );
                                                if (v == true) {
                                                  updated[input.key] =
                                                      input.defaultValue ?? '';
                                                } else {
                                                  updated.remove(input.key);
                                                }
                                                withParams.value = updated;
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              input.key,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    fontFamily: 'monospace',
                                                    fontWeight: input.required_
                                                        ? FontWeight.bold
                                                        : null,
                                                  ),
                                            ),
                                          ),
                                          if (input.required_)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.errorContainer,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'required',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onErrorContainer,
                                                    ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (input.description.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 32,
                                            top: 2,
                                          ),
                                          child: Text(
                                            input.description,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Theme.of(
                                                    context,
                                                  ).hintColor,
                                                ),
                                          ),
                                        ),
                                      if (isEnabled)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 32,
                                            top: 6,
                                          ),
                                          child: TextFormField(
                                            initialValue:
                                                withParams.value[input.key],
                                            style: const TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 13,
                                            ),
                                            decoration: InputDecoration(
                                              isDense: true,
                                              hintText:
                                                  input.defaultValue ?? '',
                                              border:
                                                  const OutlineInputBorder(),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 10,
                                                  ),
                                            ),
                                            onChanged: (v) {
                                              withParams.value = {
                                                ...withParams.value,
                                                input.key: v,
                                              };
                                            },
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        )
                      else
                        Text(
                          'Enter an action to see available inputs',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Theme.of(context).hintColor),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: () {
                  onSave(
                    WorkflowYamlStep(
                      name: nameController.text,
                      type: stepType.value,
                      run: runController.text,
                      uses: usesController.text,
                      withParams: withParams.value,
                    ),
                  );
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.check),
                label: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YamlTab extends StatelessWidget {
  const _YamlTab({
    required this.yamlController,
    required this.onChanged,
  });

  final ValueNotifier<CodeLineEditingController> yamlController;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CodeEditor(
          padding: const EdgeInsets.all(12),
          controller: yamlController.value,
          wordWrap: true,
          borderRadius: BorderRadius.circular(12),
          onChanged: (_) => onChanged(),
          style: CodeEditorStyle(
            fontSize: 14,
            backgroundColor: const Color(0xFF1E1E1E),
            textColor: Colors.white,
            codeTheme: CodeHighlightTheme(
              languages: {
                'yaml': CodeHighlightThemeMode(mode: langYaml),
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
    );
  }
}

class _CommitBottomSheet extends HookConsumerWidget {
  const _CommitBottomSheet({
    required this.repository,
    required this.branch,
    required this.yamlContent,
    required this.fileName,
    required this.isLoading,
  });

  final String repository;
  final String branch;
  final String yamlContent;
  final ValueNotifier<String> fileName;
  final ValueNotifier<bool> isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileNameController = useTextEditingController(text: fileName.value);
    final commitMode = useState(CommitMode.direct);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          children: [
            Text(
              'Save to Repository',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'File Name',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: fileNameController,
                      decoration: InputDecoration(
                        hintText: 'e.g. build.yaml',
                        border: const OutlineInputBorder(),
                        prefixText: '.openci/',
                        prefixStyle: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: Theme.of(context).hintColor),
                      ),
                      onChanged: (value) => fileName.value = value,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'How to save',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    _CommitModeCard(
                      icon: Icons.commit,
                      title: 'Commit directly',
                      subtitle: 'Commit to the $branch branch',
                      isSelected: commitMode.value == CommitMode.direct,
                      onTap: () => commitMode.value = CommitMode.direct,
                    ),
                    const SizedBox(height: 8),
                    _CommitModeCard(
                      icon: Icons.call_merge,
                      title: 'Create a Pull Request',
                      subtitle: 'A new branch will be created and a PR opened',
                      isSelected: commitMode.value == CommitMode.pullRequest,
                      onTap: () => commitMode.value = CommitMode.pullRequest,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: isLoading.value
                    ? null
                    : () => _onSubmit(
                        context: context,
                        ref: ref,
                        fileName: fileNameController.text.trim(),
                        commitMode: commitMode.value,
                      ),
                icon: isLoading.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        commitMode.value == CommitMode.direct
                            ? Icons.commit
                            : Icons.call_merge,
                      ),
                label: Text(
                  commitMode.value == CommitMode.direct
                      ? 'Commit to $branch'
                      : 'Create Pull Request',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSubmit({
    required BuildContext context,
    required WidgetRef ref,
    required String fileName,
    required CommitMode commitMode,
  }) async {
    if (fileName.isEmpty) {
      context.showSnackBarMessage('Please enter a file name');
      return;
    }
    if (!fileName.endsWith('.yaml') && !fileName.endsWith('.yml')) {
      context.showSnackBarMessage('File name must end with .yaml or .yml');
      return;
    }

    isLoading.value = true;

    try {
      final notifier = ref.read(createWorkflowFileProvider.notifier);
      final result = await notifier.createWorkflowFile(
        repository: repository,
        branch: branch,
        fileName: fileName,
        content: yamlContent,
        commitMode: commitMode,
      );

      try {
        ref.invalidate(workflowFilesProvider);
      } catch (_) {}

      if (!context.mounted) return;

      if (commitMode == CommitMode.pullRequest) {
        final prUrl = result['pullRequestUrl'] as String?;
        if (prUrl != null) {
          Navigator.of(context).pop();
          if (!context.mounted) return;
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Pull Request Created'),
              content: Text('PR #${result['pullRequestNumber']} was created.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
                FilledButton(
                  onPressed: () {
                    url_launcher.launchUrl(Uri.parse(prUrl));
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Open in GitHub'),
                ),
              ],
            ),
          );
          return;
        }
      }

      if (!context.mounted) return;
      Navigator.of(context).pop();
      if (!context.mounted) return;
      context.showSnackBarMessage(
        commitMode == CommitMode.direct
            ? 'Workflow file committed to $branch'
            : 'Pull request created',
      );
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Create workflow error: $e');
      if (!context.mounted) return;
      context.showSnackBarMessage('Error: $e');
    } finally {
      isLoading.value = false;
    }
  }
}

class _CommitModeCard extends StatelessWidget {
  const _CommitModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: isSelected
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).hintColor,
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: colorScheme.primary)
            : Icon(Icons.circle_outlined, color: colorScheme.outlineVariant),
      ),
    );
  }
}
