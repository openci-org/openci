import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:dashboard/variables/variables_page.dart';
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
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import 'status_dot.dart';

class CreateWorkflowPage extends HookConsumerWidget {
  const CreateWorkflowPage({
    super.key,
    required this.repository,
    required this.branch,
    required this.teamId,
    this.existingFile,
    this.initialYaml,
  });

  final String repository;
  final String branch;
  final String teamId;
  final WorkflowFile? existingFile;
  final String? initialYaml;

  bool get isEditing => existingFile != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabController = useTabController(initialLength: 2);
    useListenable(tabController);

    final sourceYaml = existingFile?.content ?? initialYaml;
    final initialConfig = sourceYaml != null ? yamlToConfig(sourceYaml) : null;

    final workflowName = useState(initialConfig?.name ?? 'my-workflow');
    final triggers = useState<Map<String, String?>>(() {
      if (initialConfig == null) return {'push': 'main'};
      final result = <String, String?>{};
      for (final entry in initialConfig.triggers.entries) {
        result[entry.key] = entry.value.isNotEmpty ? entry.value.first : null;
      }
      return result;
    }());
    final steps = useState<List<WorkflowYamlStep>>(
      initialConfig?.steps ??
          [WorkflowYamlStep(name: 'Build', run: 'echo "Hello, OpenCI!"')],
    );
    final yamlController = useState(
      CodeLineEditingController.fromText(
        sourceYaml ??
            stepsToYaml(
              WorkflowYamlConfig(
                name: 'my-workflow',
                triggers: {
                  'push': ['main'],
                },
                steps: [
                  WorkflowYamlStep(
                    name: 'Build',
                    run: 'echo "Hello, OpenCI!"',
                  ),
                ],
              ),
            ),
      ),
    );
    final existingFileName = existingFile?.name ?? 'workflow.yaml';
    final fileName = useState(existingFileName);
    final isLoading = useState(false);
    final isSyncingFromEditor = useState(false);
    final isSyncingFromYaml = useState(false);

    void syncEditorToYaml() {
      if (isSyncingFromYaml.value) return;
      isSyncingFromEditor.value = true;
      final triggersForYaml = <String, List<String>>{};
      for (final entry in triggers.value.entries) {
        triggersForYaml[entry.key] = entry.value != null ? [entry.value!] : [];
      }
      final yaml = stepsToYaml(
        WorkflowYamlConfig(
          name: workflowName.value,
          triggers: triggersForYaml,
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
            Text(
              isEditing
                  ? t.workflow.editor.editTitle
                  : t.workflow.editor.createTitle,
            ),
            Text(
              '$repository ($branch)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: List.generate(2, (index) {
                final labels = [
                  t.workflow.editor.editorTab,
                  t.workflow.editor.yamlTab,
                ];
                final icons = [Icons.view_list, Icons.code];
                final isSelected = tabController.index == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => tabController.animateTo(index),
                      hoverColor: Colors.white.withValues(alpha: 0.04),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icons[index],
                              size: 15,
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : Colors.white.withValues(alpha: 0.35),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              labels[index],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.45),
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
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
                      triggers: triggers,
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
              label: Text(t.common.save),
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
            triggers: triggers,
            steps: steps,
            teamId: teamId,
            existingFile: existingFile,
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
                final parsedTriggers = <String, String?>{};
                for (final entry in config.triggers.entries) {
                  parsedTriggers[entry.key] = entry.value.isNotEmpty
                      ? entry.value.first
                      : null;
                }
                triggers.value = parsedTriggers;
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
    required ValueNotifier<Map<String, String?>> triggers,
    required ValueNotifier<List<WorkflowYamlStep>> steps,
    required TabController tabController,
  }) {
    final currentYaml = yamlController.value.text;

    Map<String, List<String>> triggersForYaml() {
      final result = <String, List<String>>{};
      for (final entry in triggers.value.entries) {
        result[entry.key] = entry.value != null ? [entry.value!] : [];
      }
      return result;
    }

    if (tabController.index == 0) {
      final yaml = stepsToYaml(
        WorkflowYamlConfig(
          name: workflowName.value,
          triggers: triggersForYaml(),
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
                  triggers: triggersForYaml(),
                  steps: steps.value,
                ),
              )
            : currentYaml,
        fileName: fileName,
        isLoading: isLoading,
        isEditing: isEditing,
      ),
    );
  }
}

class _EditorTab extends HookConsumerWidget {
  const _EditorTab({
    required this.repository,
    required this.workflowName,
    required this.triggers,
    required this.steps,
    required this.onChanged,
    required this.teamId,
    this.existingFile,
  });

  final String repository;
  final ValueNotifier<String> workflowName;
  final ValueNotifier<Map<String, String?>> triggers;
  final ValueNotifier<List<WorkflowYamlStep>> steps;
  final VoidCallback onChanged;
  final String teamId;
  final WorkflowFile? existingFile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController(text: workflowName.value);
    final branchesAsync = ref.watch(gitHubBranchesProvider(repository));

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          children: [
            // ── Basic Info Section ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.workflow.editor.basicInfo,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.4),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameController,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: t.workflow.editor.workflowName,
                      labelStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      workflowName.value = value;
                      onChanged();
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'TRIGGERS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.4),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children:
                        ['push', 'pull_request', 'release', 'tag'].map((type) {
                      IconData icon;
                      switch (type) {
                        case 'push':
                          icon = Icons.publish_rounded;
                          break;
                        case 'pull_request':
                          icon = Icons.merge_type_rounded;
                          break;
                        case 'release':
                          icon = Icons.new_releases_rounded;
                          break;
                        case 'tag':
                          icon = Icons.local_offer_rounded;
                          break;
                        default:
                          icon = Icons.bolt_rounded;
                      }

                      final isSelected = triggers.value.containsKey(type);

                      return InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () {
                          final current = Map<String, String?>.from(
                            triggers.value,
                          );
                          if (!isSelected) {
                            final needsBranch =
                                type == 'push' || type == 'pull_request';
                            current[type] = needsBranch ? 'main' : null;
                          } else {
                            current.remove(type);
                          }
                          if (current.isEmpty) return;
                          triggers.value = current;
                          onChanged();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.08),
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icon,
                                size: 14,
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : Colors.white.withValues(alpha: 0.35),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                type,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : Colors.white.withValues(alpha: 0.45),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  for (final type in ['push', 'pull_request'])
                    if (triggers.value.containsKey(type)) ...[
                      const SizedBox(height: 12),
                      branchesAsync.when(
                        loading: () => TextFormField(
                          enabled: false,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            labelText: t.workflow.triggerBranchLoading(
                              type: type,
                            ),
                            labelStyle: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                        error: (e, _) => TextFormField(
                          enabled: false,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            labelText: t.workflow.triggerBranch(type: type),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            suffixIcon: Icon(
                              Icons.error_outline,
                              size: 18,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                        data: (branches) => Autocomplete<String>(
                          initialValue: TextEditingValue(
                            text: triggers.value[type] ?? '',
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
                          fieldViewBuilder: (
                            context,
                            controller,
                            focusNode,
                            onFieldSubmitted,
                          ) {
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                labelText: t.workflow.triggerBranch(
                                  type: type,
                                ),
                                labelStyle: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.45),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                ),
                                suffixIcon: Icon(
                                  Icons.search,
                                  size: 18,
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                            );
                          },
                          onSelected: (value) {
                            final current = Map<String, String?>.from(
                              triggers.value,
                            );
                            current[type] = value;
                            triggers.value = current;
                            onChanged();
                          },
                        ),
                      ),
                    ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (existingFile != null)
              HookConsumer(
                builder: (context, ref, child) {
                  final isEnabled = useState(existingFile!.enabled);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        StatusDot(
                          active: isEnabled.value,
                          size: 8,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEnabled.value
                                    ? t.workflow.enabled
                                    : t.workflow.disabled,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isEnabled.value
                                    ? t.workflow.enabledDescription
                                    : t.workflow.disabledDescription,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isEnabled.value,
                          onChanged: (value) {
                            isEnabled.value = value;
                            ref.read(
                              toggleWorkflowEnabledProvider(
                                fileName: existingFile!.name,
                                enabled: value,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 12),
            // ── Variables shortcut ──
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const VariablesPage(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Symbols.key_rounded,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.variables.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${t.variables.secretsTab} / ${t.variables.envVarsTab}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ],
                ),
              ),
            ),
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
                    teamId: teamId,
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
            const SizedBox(height: 12),
            Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  final newSteps = List<WorkflowYamlStep>.from(steps.value);
                  newSteps.add(
                    WorkflowYamlStep(name: 'New Step', run: 'echo "hello"'),
                  );
                  steps.value = newSteps;
                  onChanged();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add,
                        size: 15,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        t.workflow.editor.addSteps,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _StepConnectorLine extends StatelessWidget {
  const _StepConnectorLine({required this.onInsert});

  final VoidCallback onInsert;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onInsert,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.add,
                size: 12,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
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
    required this.teamId,
  });

  final WorkflowYamlStep step;
  final int stepIndex;
  final ValueChanged<WorkflowYamlStep> onUpdate;
  final VoidCallback onDelete;
  final String teamId;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _showEditSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(7),
              ),
              alignment: Alignment.center,
              child: Text(
                '${stepIndex + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: step.name.isEmpty
                  ? Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: step.type == StepType.uses
                                ? Colors.purple.withValues(alpha: 0.12)
                                : Colors.blue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: step.type == StepType.uses
                                  ? Colors.purple.withValues(alpha: 0.25)
                                  : Colors.blue.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                step.type == StepType.uses
                                    ? Icons.extension
                                    : Icons.terminal,
                                size: 10,
                                color: step.type == StepType.uses
                                    ? Colors.purple.withValues(alpha: 0.7)
                                    : Colors.blue.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                step.type == StepType.uses
                                    ? t.workflow.editor.action
                                    : t.workflow.editor.command,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: step.type == StepType.uses
                                      ? Colors.purple.withValues(alpha: 0.7)
                                      : Colors.blue.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            step.type == StepType.uses
                                ? step.uses
                                : step.run,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.7),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              step.type == StepType.uses
                                  ? Icons.extension
                                  : Icons.terminal,
                              size: 12,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                step.type == StepType.uses
                                    ? step.uses
                                    : step.run,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      Colors.white.withValues(alpha: 0.35),
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(width: 8),
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(t.workflow.editor.deleteStep),
                    content: Text(
                      t.workflow.editor.deleteStepConfirm,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(t.common.cancel),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.error,
                        ),
                        child: Text(t.common.delete),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  onDelete();
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.25),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ],
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
        teamId: teamId,
      ),
    );
  }
}

class _EditStepSheet extends HookConsumerWidget {
  const _EditStepSheet({
    required this.step,
    required this.onSave,
    required this.teamId,
  });

  final WorkflowYamlStep step;
  final ValueChanged<WorkflowYamlStep> onSave;
  final String teamId;

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

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: Colors.white.withValues(alpha: 0.1),
      ),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: Colors.white.withValues(alpha: 0.25),
      ),
    );
    final labelStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: Colors.white.withValues(alpha: 0.45),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(
                    t.workflow.editor.editStep,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => Navigator.of(context).pop(),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.workflow.editor.stepName, style: labelStyle),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: nameController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: t.workflow.editor.stepNameHint,
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        border: inputBorder,
                        enabledBorder: inputBorder,
                        focusedBorder: focusedBorder,
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.03),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(t.workflow.editor.type, style: labelStyle),
                    const SizedBox(height: 6),
                    // ── Custom pill toggle ──
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Row(
                        children: StepType.values.map((type) {
                          final isSelected = stepType.value == type;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => stepType.value = type,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      type == StepType.run
                                          ? Icons.terminal
                                          : Icons.extension,
                                      size: 14,
                                      color: isSelected
                                          ? Colors.white
                                              .withValues(alpha: 0.7)
                                          : Colors.white
                                              .withValues(alpha: 0.3),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      type == StepType.run ? 'run' : 'uses',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isSelected
                                            ? Colors.white
                                                .withValues(alpha: 0.8)
                                            : Colors.white
                                                .withValues(alpha: 0.35),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (stepType.value == StepType.run) ...[
                      Text(t.workflow.editor.command, style: labelStyle),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: runController,
                        maxLines: 5,
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                        decoration: InputDecoration(
                          hintText: 'echo "hello"',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            fontFamily: 'monospace',
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          border: inputBorder,
                          enabledBorder: inputBorder,
                          focusedBorder: focusedBorder,
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.03),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ] else ...[
                      Text(t.workflow.editor.action, style: labelStyle),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: usesController,
                        readOnly: true,
                        onTap: () async {
                          final usesRef = await SearchActionsSheet.show(
                            context,
                            teamId: teamId,
                          );
                          if (usesRef != null) {
                            usesController.text = usesRef;
                            usesValue.value = usesRef;
                            withParams.value = {};
                          }
                        },
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: t.workflow.editor.actionHint,
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          border: inputBorder,
                          enabledBorder: inputBorder,
                          focusedBorder: focusedBorder,
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.03),
                          suffixIcon: Icon(
                            Icons.search,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
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
                              actionTagsProvider(
                                fullName: fullName,
                                teamId: teamId,
                              ),
                            );
                            return tagsAsync.when(
                              loading: () => Text(
                                t.workflow.editor.loadingVersions,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
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
                                  style: const TextStyle(fontSize: 13),
                                  decoration: InputDecoration(
                                    labelText: t.workflow.editor.version,
                                    labelStyle: labelStyle,
                                    border: inputBorder,
                                    enabledBorder: inputBorder,
                                    focusedBorder: focusedBorder,
                                    filled: true,
                                    fillColor:
                                        Colors.white.withValues(alpha: 0.03),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                  ),
                                  items: effectiveTags
                                      .map(
                                        (tag) => DropdownMenuItem(
                                          value: tag,
                                          child: Text(tag),
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
                      Text(t.workflow.editor.kWith, style: labelStyle),
                      const SizedBox(height: 6),
                      if (inputsAsync != null)
                        inputsAsync.when(
                          loading: () => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: Text(
                                t.workflow.editor.loadingInputs,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                          ),
                          error: (e, _) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              t.workflow.editor.couldNotLoadInputs,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.35),
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
                                  t.workflow.editor.noInputs,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Colors.white.withValues(alpha: 0.35),
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
                                            width: 20,
                                            height: 20,
                                            child: Checkbox(
                                              value: isEnabled,
                                              side: BorderSide(
                                                color: Colors.white
                                                    .withValues(alpha: 0.2),
                                              ),
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
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: input.required_
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                                fontFamily: 'monospace',
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
                                                color: Colors.red
                                                    .withValues(alpha: 0.12),
                                                border: Border.all(
                                                  color: Colors.red
                                                      .withValues(alpha: 0.2),
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                t.workflow.editor.required,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.red
                                                      .withValues(alpha: 0.7),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (input.description.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 28,
                                            top: 2,
                                          ),
                                          child: Text(
                                            input.description,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.white
                                                  .withValues(alpha: 0.35),
                                            ),
                                          ),
                                        ),
                                      if (isEnabled)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 28,
                                            top: 6,
                                          ),
                                          child: TextFormField(
                                            initialValue:
                                                withParams.value[input.key],
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontFamily: 'monospace',
                                            ),
                                            decoration: InputDecoration(
                                              isDense: true,
                                              hintText:
                                                  input.defaultValue ?? '',
                                              hintStyle: TextStyle(
                                                fontSize: 13,
                                                color: Colors.white
                                                    .withValues(alpha: 0.2),
                                              ),
                                              border: inputBorder,
                                              enabledBorder: inputBorder,
                                              focusedBorder: focusedBorder,
                                              filled: true,
                                              fillColor: Colors.white
                                                  .withValues(alpha: 0.03),
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
                          t.workflow.editor.enterAction,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            // ── Save button ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.15),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      t.common.save,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Padding(
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
    this.isEditing = false,
  });

  final String repository;
  final String branch;
  final String yamlContent;
  final ValueNotifier<String> fileName;
  final ValueNotifier<bool> isLoading;
  final bool isEditing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileNameController = useTextEditingController(text: fileName.value);
    final commitMode = useState(CommitMode.direct);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: Colors.white.withValues(alpha: 0.1),
      ),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: Colors.white.withValues(alpha: 0.25),
      ),
    );
    final labelStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: Colors.white.withValues(alpha: 0.45),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(
                    t.workflow.editor.saveToRepo,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => Navigator.of(context).pop(),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.workflow.editor.fileName, style: labelStyle),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: fileNameController,
                      readOnly: isEditing,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: t.workflow.editor.fileNameHint,
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        border: inputBorder,
                        enabledBorder: inputBorder,
                        focusedBorder: focusedBorder,
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.03),
                        prefixText: '.openci/',
                        prefixStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      onChanged: isEditing
                          ? null
                          : (value) => fileName.value = value,
                    ),
                    const SizedBox(height: 20),
                    Text(t.workflow.editor.howToSave, style: labelStyle),
                    const SizedBox(height: 8),
                    _CommitModeCard(
                      icon: Icons.commit,
                      title: t.workflow.editor.commitDirectly,
                      subtitle: t.workflow.editor.commitToBranch(
                        branch: branch,
                      ),
                      isSelected: commitMode.value == CommitMode.direct,
                      onTap: () => commitMode.value = CommitMode.direct,
                    ),
                    const SizedBox(height: 8),
                    _CommitModeCard(
                      icon: Icons.call_merge,
                      title: t.workflow.editor.createPR,
                      subtitle: t.workflow.editor.createPRSubtitle,
                      isSelected: commitMode.value == CommitMode.pullRequest,
                      onTap: () => commitMode.value = CommitMode.pullRequest,
                    ),
                  ],
                ),
              ),
            ),
            // ── Submit button ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: isLoading.value
                      ? null
                      : () => _onSubmit(
                            context: context,
                            ref: ref,
                            fileName: fileNameController.text.trim(),
                            commitMode: commitMode.value,
                          ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isLoading.value
                          ? Colors.white.withValues(alpha: 0.04)
                          : Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.15),
                      border: Border.all(
                        color: isLoading.value
                            ? Colors.white.withValues(alpha: 0.08)
                            : Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: isLoading.value
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                commitMode.value == CommitMode.direct
                                    ? Icons.commit
                                    : Icons.call_merge,
                                size: 16,
                                color:
                                    Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                commitMode.value == CommitMode.direct
                                    ? t.workflow.editor
                                        .commitToBranchButton(branch: branch)
                                    : t.workflow.editor.createPRButton,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary,
                                ),
                              ),
                            ],
                          ),
                  ),
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
      context.showSnackBarMessage(t.workflow.editor.enterFileName);
      return;
    }
    if (!fileName.endsWith('.yaml') && !fileName.endsWith('.yml')) {
      context.showSnackBarMessage(t.workflow.editor.fileNameMustEndYaml);
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
          final parentNavigator = Navigator.of(context, rootNavigator: true);
          Navigator.of(context).pop();
          if (!context.mounted || !parentNavigator.mounted) return;
          await showDialog(
            context: parentNavigator.context,
            builder: (ctx) => AlertDialog(
              title: Text(t.workflow.editor.prCreated),
              content: Text(
                t.workflow.editor.prNumber(
                  number: result['pullRequestNumber'].toString(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                  child: Text(t.workflow.editor.close),
                ),
                FilledButton(
                  onPressed: () {
                    url_launcher.launchUrl(Uri.parse(prUrl));
                    Navigator.of(ctx).pop();
                  },
                  child: Text(t.workflow.editor.openInGitHub),
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
            ? t.workflow.editor.committedToBranch(branch: branch)
            : t.workflow.editor.prCreatedSuccess,
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
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withValues(alpha: 0.06)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? primary.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.08),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? primary.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? primary
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? primary
                      : Colors.white.withValues(alpha: 0.15),
                  width: isSelected ? 0 : 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
