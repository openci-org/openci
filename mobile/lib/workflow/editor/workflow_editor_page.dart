import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:dashboard/workflow/editor/github_actions_search_provider.dart';
import 'package:dashboard/workflow/editor/workflow_editor_provider.dart';
import 'package:dashboard/workflow/yaml_workflow.dart';
import 'package:dashboard/workflow/yaml_workflow_converter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/yaml.dart' as yaml_lang;
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
    return state.when(
      data: (editorState) {
        return _EditorScaffold(
          editorState: editorState,
          workflowId: workflowId,
        );
      },
      error: (error, stackTrace) {
        return Scaffold(
          appBar: AppBar(title: const Text('Workflow Editor')),
          body: Center(child: Text('Error: $error')),
        );
      },
      loading: () {
        return Scaffold(
          appBar: AppBar(title: const Text('Workflow Editor')),
          body: const Center(child: CircularProgressIndicator.adaptive()),
        );
      },
    );
  }
}

class _EditorScaffold extends HookConsumerWidget {
  const _EditorScaffold({
    required this.editorState,
    required this.workflowId,
  });

  final WorkflowEditorState editorState;
  final String workflowId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabController = useTabController(initialLength: 2);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        toolbarHeight: 56,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  Icons.edit_note,
                  size: 18,
                  color: colorScheme.primary,
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
                    editorState.parsedWorkflow.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
                        editorState.branch,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                          color: colorScheme.primary,
                        ),
                      ),
                      Text(
                        ' · ',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Icon(
                        Icons.description_outlined,
                        size: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          editorState.filePath.split('/').last,
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Save Changes',
            onPressed: () => _showSaveDialog(context, ref),
          ),
        ],
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(text: 'Visual'),
            Tab(text: 'YAML'),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          _VisualEditorTab(
            editorState: editorState,
            workflowId: workflowId,
          ),
          _YamlEditorTab(
            editorState: editorState,
            workflowId: workflowId,
          ),
        ],
      ),
    );
  }

  void _showSaveDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => _SaveOptionsSheet(
        editorState: editorState,
        workflowId: workflowId,
      ),
    );
  }
}

class _SaveOptionsSheet extends HookConsumerWidget {
  const _SaveOptionsSheet({
    required this.editorState,
    required this.workflowId,
  });

  final WorkflowEditorState editorState;
  final String workflowId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saveMode = useState<String>('commit');
    final commitMessageController = useTextEditingController(
      text: 'Update ${editorState.filePath.split('/').last}',
    );
    final branchNameController = useTextEditingController(
      text:
          'workflow/${editorState.parsedWorkflow.name.toLowerCase().replaceAll(' ', '-')}',
    );
    final prTitleController = useTextEditingController(
      text: 'Update workflow: ${editorState.parsedWorkflow.name}',
    );
    final colorScheme = Theme.of(context).colorScheme;
    final isSaving = useState(false);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Save Changes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  FontAwesomeIcons.github,
                  size: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '${editorState.repository} / ${editorState.filePath}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'commit',
                  label: Text('Commit'),
                  icon: Icon(Icons.check_circle_outline, size: 18),
                ),
                ButtonSegment(
                  value: 'pr',
                  label: Text('Pull Request'),
                  icon: Icon(Icons.merge_type, size: 18),
                ),
              ],
              selected: {saveMode.value},
              onSelectionChanged: (v) => saveMode.value = v.first,
            ),
            const SizedBox(height: 16),
            if (saveMode.value == 'commit') ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.codeBranch,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Commit to ',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        editorState.branch,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onPrimaryContainer,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: commitMessageController,
                decoration: const InputDecoration(
                  labelText: 'Commit message',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ] else ...[
              TextFormField(
                controller: branchNameController,
                decoration: InputDecoration(
                  labelText: 'New branch name',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(FontAwesomeIcons.codeBranch, size: 14),
                  helperText: 'from ${editorState.branch}',
                ),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: prTitleController,
                decoration: const InputDecoration(
                  labelText: 'PR title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.merge_type,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${branchNameController.text} → ${editorState.branch}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isSaving.value
                    ? null
                    : () async {
                        isSaving.value = true;

                        await Future.delayed(const Duration(seconds: 1));

                        if (!context.mounted) return;

                        Navigator.of(context).pop();

                        final message = saveMode.value == 'commit'
                            ? 'Committed to ${editorState.branch}'
                            : 'PR created: ${prTitleController.text}';

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(message),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                icon: isSaving.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        saveMode.value == 'commit'
                            ? Icons.check_circle_outline
                            : Icons.merge_type,
                      ),
                label: Text(
                  saveMode.value == 'commit'
                      ? 'Commit Changes'
                      : 'Create Pull Request',
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _VisualEditorTab extends ConsumerWidget {
  const _VisualEditorTab({
    required this.editorState,
    required this.workflowId,
  });

  final WorkflowEditorState editorState;
  final String workflowId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workflow = editorState.parsedWorkflow;
    final steps = workflow.steps;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        _TriggerCard(
          trigger: workflow.on,
          workflowId: workflowId,
        ),
        if (steps.isNotEmpty)
          _StepConnector(
            workflowId: workflowId,
            insertAt: 0,
          ),
        for (int i = 0; i < steps.length; i++) ...[
          _StepCard(
            step: steps[i],
            stepIndex: i,
            workflowId: workflowId,
          ),
          if (i < steps.length - 1)
            _StepConnector(
              workflowId: workflowId,
              insertAt: i + 1,
            ),
        ],
        const SizedBox(height: 12),
        Center(
          child: IconButton.filled(
            onPressed: () => _showAddStepDialog(context, ref),
            icon: const Icon(Icons.add),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _showAddStepDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AddStepSheet(workflowId: workflowId),
    );
  }
}

class _TriggerCard extends ConsumerWidget {
  const _TriggerCard({
    required this.trigger,
    required this.workflowId,
  });

  final YamlWorkflowTrigger trigger;
  final String workflowId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = YamlWorkflowConverter.triggerSummary(trigger);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.primary.withValues(alpha: 0.4),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => _EditTriggerSheet(
              trigger: trigger,
              workflowId: workflowId,
            ),
          );
        },
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Icon(
                            FontAwesomeIcons.bolt,
                            color: colorScheme.onPrimaryContainer,
                            size: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Trigger',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              summary,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
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

class _StepCard extends ConsumerWidget {
  const _StepCard({
    required this.step,
    required this.stepIndex,
    required this.workflowId,
  });

  final YamlWorkflowStep step;
  final int stepIndex;
  final String workflowId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => _EditStepSheet(
              step: step,
              stepIndex: stepIndex,
              workflowId: workflowId,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${stepIndex + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
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
                      step.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          step.uses != null
                              ? FontAwesomeIcons.puzzlePiece
                              : FontAwesomeIcons.terminal,
                          size: 10,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            step.uses ?? step.run ?? '',
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: colorScheme.error.withValues(alpha: 0.7),
                  size: 18,
                ),
                visualDensity: VisualDensity.compact,
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Step'),
                      content: const Text(
                        'Are you sure you want to delete this step?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
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
                    await ref
                        .read(workflowEditorProvider(workflowId).notifier)
                        .removeStep(stepIndex);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector({
    required this.workflowId,
    required this.insertAt,
  });

  final String workflowId;
  final int insertAt;

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
            color: Theme.of(context).dividerColor,
          ),
          Consumer(
            builder: (context, ref, _) {
              return IconButton(
                iconSize: 14,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                ),
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  iconColor: WidgetStatePropertyAll(
                    Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (_) => _AddStepSheet(
                      workflowId: workflowId,
                      insertAt: insertAt,
                    ),
                  );
                },
                icon: const Icon(Icons.add),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _YamlEditorTab extends HookConsumerWidget {
  const _YamlEditorTab({
    required this.editorState,
    required this.workflowId,
  });

  final WorkflowEditorState editorState;
  final String workflowId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yamlText = editorState.yamlRaw.isEmpty
        ? YamlWorkflowConverter.toYamlString(editorState.parsedWorkflow)
        : editorState.yamlRaw;

    final codeController = useState(
      CodeLineEditingController.fromText(yamlText),
    );
    final hasChanges = useState(false);

    return Column(
      children: [
        if (editorState.parseError != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.errorContainer,
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'YAML parse error: ${editorState.parseError}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: CodeEditor(
            controller: codeController.value,
            wordWrap: true,
            borderRadius: BorderRadius.zero,
            padding: const EdgeInsets.all(16),
            style: CodeEditorStyle(
              fontSize: 14,
              backgroundColor: const Color(0xFF1E1E1E),
              textColor: Colors.white,
              codeTheme: CodeHighlightTheme(
                languages: {
                  'yaml': CodeHighlightThemeMode(mode: yaml_lang.langYaml),
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
            onChanged: (controller) {
              hasChanges.value = true;
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: hasChanges.value
                  ? () async {
                      try {
                        await ref
                            .read(
                              workflowEditorProvider(workflowId).notifier,
                            )
                            .updateYaml(codeController.value.text);
                        hasChanges.value = false;
                        if (!context.mounted) return;
                        context.showSnackBarMessage('YAML saved');
                      } catch (e) {
                        if (!context.mounted) return;
                        context.showSnackBarMessage('Failed to save: $e');
                      }
                    }
                  : null,
              icon: const Icon(Icons.save),
              label: const Text('Save YAML'),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddStepSheet extends HookConsumerWidget {
  const _AddStepSheet({
    required this.workflowId,
    this.insertAt,
  });

  final String workflowId;
  final int? insertAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final commandController = useTextEditingController();
    final usesController = useTextEditingController();
    final stepType = useState('run');
    final withParams = useState(<String, String>{});
    final withKeyController = useTextEditingController();
    final withValueController = useTextEditingController();
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Add Step',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Step Name',
                    hintText: 'e.g. Build iOS App',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'run',
                      label: Text('Run'),
                      icon: Icon(FontAwesomeIcons.terminal, size: 14),
                    ),
                    ButtonSegment(
                      value: 'uses',
                      label: Text('Uses'),
                      icon: Icon(FontAwesomeIcons.puzzlePiece, size: 14),
                    ),
                  ],
                  selected: {stepType.value},
                  onSelectionChanged: (v) => stepType.value = v.first,
                ),
                const SizedBox(height: 16),
                if (stepType.value == 'run')
                  TextFormField(
                    controller: commandController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Command',
                      hintText: 'e.g. flutter build ipa',
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  )
                else ...[
                  TextFormField(
                    controller: usesController,
                    decoration: InputDecoration(
                      labelText: 'Action',
                      hintText: 'e.g. actions/checkout@v4',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () async {
                          final result =
                              await showModalBottomSheet<GitHubAction>(
                                context: context,
                                isScrollControlled: true,
                                showDragHandle: true,
                                builder: (_) => const _ActionSearchSheet(),
                              );
                          if (result != null) {
                            usesController.text = result.usesString;
                          }
                        },
                      ),
                    ),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('with:', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  ...withParams.value.entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${e.key}: ${e.value}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              final updated = Map<String, String>.from(
                                withParams.value,
                              );
                              updated.remove(e.key);
                              withParams.value = updated;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: withKeyController,
                          decoration: const InputDecoration(
                            hintText: 'key',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: withValueController,
                          decoration: const InputDecoration(
                            hintText: 'value',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        onPressed: () {
                          if (withKeyController.text.isEmpty) return;
                          final updated = Map<String, String>.from(
                            withParams.value,
                          );
                          updated[withKeyController.text] =
                              withValueController.text;
                          withParams.value = updated;
                          withKeyController.clear();
                          withValueController.clear();
                        },
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: () async {
                    if (nameController.text.isEmpty) return;
                    final step = stepType.value == 'run'
                        ? YamlWorkflowStep(
                            name: nameController.text,
                            run: commandController.text,
                          )
                        : YamlWorkflowStep(
                            name: nameController.text,
                            uses: usesController.text,
                            withParams: Map<String, String>.from(
                              withParams.value,
                            ),
                          );
                    await ref
                        .read(workflowEditorProvider(workflowId).notifier)
                        .addStep(step, insertAt: insertAt);
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditStepSheet extends HookConsumerWidget {
  const _EditStepSheet({
    required this.step,
    required this.stepIndex,
    required this.workflowId,
  });

  final YamlWorkflowStep step;
  final int stepIndex;
  final String workflowId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController(text: step.name);
    final commandController = useTextEditingController(text: step.run ?? '');
    final usesController = useTextEditingController(text: step.uses ?? '');
    final stepType = useState(step.uses != null ? 'uses' : 'run');
    final withParams = useState(Map<String, String>.from(step.withParams));
    final withKeyController = useTextEditingController();
    final withValueController = useTextEditingController();
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Edit Step',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Step Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'run',
                      label: Text('Run'),
                      icon: Icon(FontAwesomeIcons.terminal, size: 14),
                    ),
                    ButtonSegment(
                      value: 'uses',
                      label: Text('Uses'),
                      icon: Icon(FontAwesomeIcons.puzzlePiece, size: 14),
                    ),
                  ],
                  selected: {stepType.value},
                  onSelectionChanged: (v) => stepType.value = v.first,
                ),
                const SizedBox(height: 16),
                if (stepType.value == 'run')
                  TextFormField(
                    controller: commandController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Command',
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  )
                else ...[
                  TextFormField(
                    controller: usesController,
                    decoration: InputDecoration(
                      labelText: 'Action',
                      hintText: 'e.g. actions/checkout@v4',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () async {
                          final result =
                              await showModalBottomSheet<GitHubAction>(
                                context: context,
                                isScrollControlled: true,
                                showDragHandle: true,
                                builder: (_) => const _ActionSearchSheet(),
                              );
                          if (result != null) {
                            usesController.text = result.usesString;
                          }
                        },
                      ),
                    ),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('with:', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  ...withParams.value.entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${e.key}: ${e.value}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              final updated = Map<String, String>.from(
                                withParams.value,
                              );
                              updated.remove(e.key);
                              withParams.value = updated;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: withKeyController,
                          decoration: const InputDecoration(
                            hintText: 'key',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: withValueController,
                          decoration: const InputDecoration(
                            hintText: 'value',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        onPressed: () {
                          if (withKeyController.text.isEmpty) return;
                          final updated = Map<String, String>.from(
                            withParams.value,
                          );
                          updated[withKeyController.text] =
                              withValueController.text;
                          withParams.value = updated;
                          withKeyController.clear();
                          withValueController.clear();
                        },
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: () async {
                    final updated = stepType.value == 'run'
                        ? YamlWorkflowStep(
                            name: nameController.text,
                            run: commandController.text,
                          )
                        : YamlWorkflowStep(
                            name: nameController.text,
                            uses: usesController.text,
                            withParams: Map<String, String>.from(
                              withParams.value,
                            ),
                          );
                    await ref
                        .read(workflowEditorProvider(workflowId).notifier)
                        .updateStep(stepIndex, updated);
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditTriggerSheet extends HookConsumerWidget {
  const _EditTriggerSheet({
    required this.trigger,
    required this.workflowId,
  });

  final YamlWorkflowTrigger trigger;
  final String workflowId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pushEnabled = useState(trigger.push != null);
    final prEnabled = useState(trigger.pullRequest != null);
    final tagEnabled = useState(trigger.tag == true);
    final releaseEnabled = useState(trigger.release != null);
    final pushBranchController = useTextEditingController(
      text: trigger.push?.branches.join(', ') ?? '',
    );
    final prBranchController = useTextEditingController(
      text: trigger.pullRequest?.branches.join(', ') ?? '',
    );
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Edit Trigger',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SwitchListTile(
                  title: const Text('Push'),
                  value: pushEnabled.value,
                  onChanged: (v) => pushEnabled.value = v,
                ),
                if (pushEnabled.value)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 8,
                    ),
                    child: TextFormField(
                      controller: pushBranchController,
                      decoration: const InputDecoration(
                        labelText: 'Branches (comma separated)',
                        hintText: 'e.g. main, develop',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                SwitchListTile(
                  title: const Text('Pull Request'),
                  value: prEnabled.value,
                  onChanged: (v) => prEnabled.value = v,
                ),
                if (prEnabled.value)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 8,
                    ),
                    child: TextFormField(
                      controller: prBranchController,
                      decoration: const InputDecoration(
                        labelText: 'Base branches (comma separated)',
                        hintText: 'e.g. main, develop',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                SwitchListTile(
                  title: const Text('Tag'),
                  value: tagEnabled.value,
                  onChanged: (v) => tagEnabled.value = v,
                ),
                SwitchListTile(
                  title: const Text('Release'),
                  value: releaseEnabled.value,
                  onChanged: (v) => releaseEnabled.value = v,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: () async {
                    List<String> parseBranches(String text) {
                      return text
                          .split(',')
                          .map((b) => b.trim())
                          .where((b) => b.isNotEmpty)
                          .toList();
                    }

                    final newTrigger = YamlWorkflowTrigger(
                      push: pushEnabled.value
                          ? YamlTriggerConfig(
                              branches: parseBranches(
                                pushBranchController.text,
                              ),
                            )
                          : null,
                      pullRequest: prEnabled.value
                          ? YamlTriggerConfig(
                              branches: parseBranches(prBranchController.text),
                            )
                          : null,
                      tag: tagEnabled.value ? true : null,
                      release: releaseEnabled.value
                          ? const YamlReleaseTriggerConfig()
                          : null,
                    );

                    await ref
                        .read(workflowEditorProvider(workflowId).notifier)
                        .updateTrigger(newTrigger);
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionSearchSheet extends HookConsumerWidget {
  const _ActionSearchSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final searchQuery = useState('');
    final debounceTimer = useRef<Future<void>?>(null);

    useEffect(() {
      void listener() {
        final text = searchController.text;
        debounceTimer.value = Future.delayed(
          const Duration(milliseconds: 400),
          () {
            if (searchController.text == text) {
              searchQuery.value = text;
            }
          },
        );
      }

      searchController.addListener(listener);
      return () => searchController.removeListener(listener);
    }, [searchController]);

    final actionsAsync = ref.watch(
      searchGitHubActionsProvider(query: searchQuery.value),
    );

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Search Actions',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search GitHub Actions...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: actionsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (e, _) => Center(
                  child: Text('Error: $e'),
                ),
                data: (actions) {
                  if (actions.isEmpty) {
                    return const Center(
                      child: Text('No actions found'),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: actions.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final action = actions[index];
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          child: Icon(
                            FontAwesomeIcons.puzzlePiece,
                            size: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        title: Text(
                          action.fullName,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          action.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: Colors.amber.shade600,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              _formatStars(action.stars),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        onTap: () => Navigator.of(context).pop(action),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatStars(int stars) {
    if (stars >= 1000) {
      return '${(stars / 1000).toStringAsFixed(1)}k';
    }
    return stars.toString();
  }
}
