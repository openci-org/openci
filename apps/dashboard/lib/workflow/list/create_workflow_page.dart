import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/theme/app_colors.dart';

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
    final jobs = useState<List<WorkflowYamlJob>>(
      initialConfig?.jobs.isNotEmpty == true
          ? initialConfig!.jobs
          : [
              WorkflowYamlJob(
                id: 'build',
                steps: [
                  WorkflowYamlStep(
                    name: 'Build',
                    run: 'echo "Hello, OpenCI!"',
                  ),
                ],
              ),
            ],
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
                jobs: [
                  WorkflowYamlJob(
                    id: 'build',
                    steps: [
                      WorkflowYamlStep(
                        name: 'Build',
                        run: 'echo "Hello, OpenCI!"',
                      ),
                    ],
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
          jobs: jobs.value,
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
                  color: AppColors.of(context).divider,
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icons[index],
                              size: 15,
                              color: isSelected
                                  ? AppColors.of(context).textSecondary
                                  : AppColors.of(context).textTertiary,
                            ),
                            const SizedBox(width: 6),
                            Text(
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
                      jobs: jobs,
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
            jobs: jobs,
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
                jobs.value = config.jobs;
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
    required ValueNotifier<List<WorkflowYamlJob>> jobs,
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
          jobs: jobs.value,
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
                  jobs: jobs.value,
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
    required this.jobs,
    required this.onChanged,
    required this.teamId,
    this.existingFile,
  });

  final String repository;
  final ValueNotifier<String> workflowName;
  final ValueNotifier<Map<String, String?>> triggers;
  final ValueNotifier<List<WorkflowYamlJob>> jobs;
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
                  color: AppColors.of(context).border,
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
                      color: AppColors.of(context).textTertiary,
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
                        color: AppColors.of(context).textTertiary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColors.of(context).border,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColors.of(context).border,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColors.of(context).textTertiary,
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
                      color: AppColors.of(context).textTertiary,
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
                                ? AppColors.of(context).border
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.of(context).border
                                  : AppColors.of(context).border,
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
                                    ? AppColors.of(context).textPrimary
                                    : AppColors.of(context).textTertiary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                type,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.of(context).textPrimary
                                      : AppColors.of(context).textTertiary,
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
                              color: AppColors.of(context).textTertiary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: AppColors.of(context).border,
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
                                color: AppColors.of(context).border,
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
                                  color: AppColors.of(context).textTertiary,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.of(context).border,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.of(context).border,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.of(context).textTertiary,
                                  ),
                                ),
                                suffixIcon: Icon(
                                  Icons.search,
                                  size: 18,
                                  color: AppColors.of(context).textTertiary,
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
                        color: AppColors.of(context).border,
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
                                  color: AppColors.of(context).textTertiary,
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
                    color: AppColors.of(context).border,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Symbols.key_rounded,
                      size: 18,
                      color: AppColors.of(context).textTertiary,
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
                              color: AppColors.of(context).textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.of(context).textTertiary,
                    ),
                  ],
                ),
              ),
            ),
            ...List.generate(jobs.value.length, (jobIndex) {
              final job = jobs.value[jobIndex];
              final isParallel = job.needs.isEmpty && jobIndex > 0;
              return Column(
                children: [
                  if (jobIndex > 0) ...[
                    // ── Job connector ──
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        children: [
                          Container(
                            width: 1,
                            height: 16,
                            color: isParallel
                                ? Colors.amber.withValues(alpha: 0.3)
                                : AppColors.of(context).border,
                          ),
                          if (job.needs.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.of(context).borderSubtle,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: AppColors.of(context).border,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.arrow_downward,
                                    size: 10,
                                    color: AppColors.of(context).textTertiary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'needs: ${job.needs.join(', ')}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                      color:
                                          AppColors.of(context).textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.amber.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.bolt,
                                    size: 10,
                                    color: Colors.amber.withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    t.workflow.editor.parallel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          Colors.amber.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Container(
                            width: 1,
                            height: 8,
                            color: isParallel
                                ? Colors.amber.withValues(alpha: 0.3)
                                : AppColors.of(context).border,
                          ),
                        ],
                      ),
                    ),
                  ],
                  // ── Job section ──
                  _JobSectionCard(
                    job: job,
                    jobIndex: jobIndex,
                    totalJobs: jobs.value.length,
                    allJobIds: jobs.value.map((j) => j.id).toList(),
                    teamId: teamId,
                    onUpdateJob: (updated) {
                      final newJobs =
                          List<WorkflowYamlJob>.from(jobs.value);
                      newJobs[jobIndex] = updated;
                      jobs.value = newJobs;
                      onChanged();
                    },
                    onDeleteJob: jobs.value.length > 1
                        ? () {
                            final newJobs =
                                List<WorkflowYamlJob>.from(jobs.value);
                            final removedId = newJobs[jobIndex].id;
                            newJobs.removeAt(jobIndex);
                            // Clean up needs references
                            for (var i = 0; i < newJobs.length; i++) {
                              if (newJobs[i].needs.contains(removedId)) {
                                newJobs[i] = newJobs[i].copyWith(
                                  needs: newJobs[i]
                                      .needs
                                      .where((n) => n != removedId)
                                      .toList(),
                                );
                              }
                            }
                            jobs.value = newJobs;
                            onChanged();
                          }
                        : null,
                    onChanged: onChanged,
                  ),
                ],
              );
            }),
            const SizedBox(height: 16),
            Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  final existingIds =
                      jobs.value.map((j) => j.id).toSet();
                  var newId = 'job_${jobs.value.length + 1}';
                  var counter = 1;
                  while (existingIds.contains(newId)) {
                    counter++;
                    newId = 'job_$counter';
                  }
                  final lastJobId = jobs.value.last.id;
                  final newJobs =
                      List<WorkflowYamlJob>.from(jobs.value);
                  newJobs.add(
                    WorkflowYamlJob(
                      id: newId,
                      needs: [lastJobId],
                      steps: [
                        WorkflowYamlStep(
                          name: 'New Step',
                          run: 'echo "hello"',
                        ),
                      ],
                    ),
                  );
                  jobs.value = newJobs;
                  onChanged();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.of(context).border,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add,
                        size: 15,
                        color: AppColors.of(context).textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        t.workflow.editor.addJob,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.of(context).textSecondary,
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

class _JobSectionCard extends HookWidget {
  const _JobSectionCard({
    required this.job,
    required this.jobIndex,
    required this.totalJobs,
    required this.allJobIds,
    required this.teamId,
    required this.onUpdateJob,
    required this.onChanged,
    this.onDeleteJob,
  });

  final WorkflowYamlJob job;
  final int jobIndex;
  final int totalJobs;
  final List<String> allJobIds;
  final String teamId;
  final ValueChanged<WorkflowYamlJob> onUpdateJob;
  final VoidCallback onChanged;
  final VoidCallback? onDeleteJob;

  @override
  Widget build(BuildContext context) {
    final isExpanded = useState(true);
    final isEditingId = useState(false);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.of(context).border,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // ── Job header ──
          InkWell(
            borderRadius: isExpanded.value
                ? const BorderRadius.vertical(top: Radius.circular(10))
                : BorderRadius.circular(10),
            onTap: () => isExpanded.value = !isExpanded.value,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.of(context).borderSubtle,
                borderRadius: isExpanded.value
                    ? const BorderRadius.vertical(
                        top: Radius.circular(10),
                      )
                    : BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  // Job icon
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${jobIndex + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.blue.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Job ID
                  if (isEditingId.value)
                    SizedBox(
                      width: 120,
                      child: TextField(
                        autofocus: true,
                        controller: TextEditingController(text: job.id),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(
                              color: AppColors.of(context).border,
                            ),
                          ),
                        ),
                        onSubmitted: (value) {
                          if (value.isNotEmpty && !allJobIds.contains(value)) {
                            onUpdateJob(job.copyWith(id: value));
                          }
                          isEditingId.value = false;
                        },
                      ),
                    )
                  else
                    GestureDetector(
                      onDoubleTap: () => isEditingId.value = true,
                      child: Text(
                        job.id,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  if (job.name != null && job.name!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      job.name!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.of(context).textTertiary,
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Step count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.of(context).borderSubtle,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${job.steps.length}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.of(context).textTertiary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Needs selector
                  if (jobIndex > 0)
                    PopupMenuButton<String>(
                      tooltip: 'needs',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        Icons.link,
                        size: 14,
                        color: AppColors.of(context).textTertiary,
                      ),
                      onSelected: (selectedJobId) {
                        final currentNeeds = List<String>.from(job.needs);
                        if (currentNeeds.contains(selectedJobId)) {
                          currentNeeds.remove(selectedJobId);
                        } else {
                          currentNeeds.add(selectedJobId);
                        }
                        onUpdateJob(job.copyWith(needs: currentNeeds));
                      },
                      itemBuilder: (_) {
                        return allJobIds
                            .where((id) => id != job.id)
                            .map(
                              (id) => PopupMenuItem(
                                value: id,
                                child: Row(
                                  children: [
                                    Icon(
                                      job.needs.contains(id)
                                          ? Icons.check_box
                                          : Icons.check_box_outline_blank,
                                      size: 16,
                                      color: job.needs.contains(id)
                                          ? Colors.blue
                                          : AppColors.of(context).textPrimary.withValues(
                                              alpha: 0.3,
                                            ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      id,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList();
                      },
                    ),
                  if (onDeleteJob != null) ...[
                    const SizedBox(width: 4),
                    InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: onDeleteJob,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.delete_outline,
                          size: 14,
                          color: AppColors.of(context).textTertiary,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: isExpanded.value ? 0 : -0.25,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: AppColors.of(context).textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Steps content ──
          if (isExpanded.value) ...[
            Container(
              width: double.infinity,
              height: 1,
              color: AppColors.of(context).divider,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                children: [
                  ...List.generate(job.steps.length, (stepIndex) {
                    final step = job.steps[stepIndex];
                    return Column(
                      children: [
                        if (stepIndex > 0)
                          _StepConnectorLine(
                            onInsert: () {
                              final newSteps =
                                  List<WorkflowYamlStep>.from(job.steps);
                              newSteps.insert(
                                stepIndex,
                                WorkflowYamlStep(
                                  name: 'New Step',
                                  run: 'echo "hello"',
                                ),
                              );
                              onUpdateJob(job.copyWith(steps: newSteps));
                            },
                          ),
                        _StepEditorCard(
                          step: step,
                          stepIndex: stepIndex,
                          teamId: teamId,
                          onUpdate: (updated) {
                            final newSteps =
                                List<WorkflowYamlStep>.from(job.steps);
                            newSteps[stepIndex] = updated;
                            onUpdateJob(job.copyWith(steps: newSteps));
                          },
                          onDelete: () {
                            final newSteps =
                                List<WorkflowYamlStep>.from(job.steps);
                            newSteps.removeAt(stepIndex);
                            onUpdateJob(job.copyWith(steps: newSteps));
                          },
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () {
                      final newSteps =
                          List<WorkflowYamlStep>.from(job.steps);
                      newSteps.add(
                        WorkflowYamlStep(
                          name: 'New Step',
                          run: 'echo "hello"',
                        ),
                      );
                      onUpdateJob(job.copyWith(steps: newSteps));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.of(context).border,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add,
                            size: 13,
                            color: AppColors.of(context).textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            t.workflow.editor.addSteps,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.of(context).textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
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
            color: AppColors.of(context).border,
          ),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onInsert,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.of(context).divider,
                border: Border.all(
                  color: AppColors.of(context).border,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.add,
                size: 12,
                color: AppColors.of(context).textTertiary,
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
            color: AppColors.of(context).border,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.of(context).divider,
                borderRadius: BorderRadius.circular(7),
              ),
              alignment: Alignment.center,
              child: Text(
                '${stepIndex + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.of(context).textSecondary,
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
                              color: AppColors.of(context).textSecondary,
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
                              color: AppColors.of(context).textTertiary,
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
                                      AppColors.of(context).textTertiary,
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
                  color: AppColors.of(context).textTertiary,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: AppColors.of(context).border,
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
        color: AppColors.of(context).border,
      ),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: AppColors.of(context).textTertiary,
      ),
    );
    final labelStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.of(context).textTertiary,
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
                        color: AppColors.of(context).textTertiary,
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
                          color: AppColors.of(context).border,
                        ),
                        border: inputBorder,
                        enabledBorder: inputBorder,
                        focusedBorder: focusedBorder,
                        filled: true,
                        fillColor: AppColors.of(context).borderSubtle,
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
                        color: AppColors.of(context).borderSubtle,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.of(context).border,
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
                                      ? AppColors.of(context).border
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
                                          ? AppColors.of(context).textPrimary
                                              .withValues(alpha: 0.7)
                                          : AppColors.of(context).textPrimary
                                              .withValues(alpha: 0.3),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      type == StepType.run ? 'run' : 'uses',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isSelected
                                            ? AppColors.of(context).textPrimary
                                                .withValues(alpha: 0.8)
                                            : AppColors.of(context).textPrimary
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
                            color: AppColors.of(context).border,
                          ),
                          border: inputBorder,
                          enabledBorder: inputBorder,
                          focusedBorder: focusedBorder,
                          filled: true,
                          fillColor: AppColors.of(context).borderSubtle,
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
                            color: AppColors.of(context).border,
                          ),
                          border: inputBorder,
                          enabledBorder: inputBorder,
                          focusedBorder: focusedBorder,
                          filled: true,
                          fillColor: AppColors.of(context).borderSubtle,
                          suffixIcon: Icon(
                            Icons.search,
                            size: 16,
                            color: AppColors.of(context).textTertiary,
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
                                  color: AppColors.of(context).textTertiary,
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
                                        AppColors.of(context).borderSubtle,
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
                                  color: AppColors.of(context).textTertiary,
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
                                color: AppColors.of(context).textTertiary,
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
                                        AppColors.of(context).textTertiary,
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
                                                color: AppColors.of(context).textPrimary
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
                                              color: AppColors.of(context).textPrimary
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
                                                color: AppColors.of(context).textPrimary
                                                    .withValues(alpha: 0.2),
                                              ),
                                              border: inputBorder,
                                              enabledBorder: inputBorder,
                                              focusedBorder: focusedBorder,
                                              filled: true,
                                              fillColor: AppColors.of(context).textPrimary
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
                            color: AppColors.of(context).textTertiary,
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
                backgroundColor: AppColors.of(context).surfaceSecondary,
                textColor: AppColors.of(context).textPrimary,
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
        color: AppColors.of(context).border,
      ),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: AppColors.of(context).textTertiary,
      ),
    );
    final labelStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.of(context).textTertiary,
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
                        color: AppColors.of(context).textTertiary,
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
                          color: AppColors.of(context).border,
                        ),
                        border: inputBorder,
                        enabledBorder: inputBorder,
                        focusedBorder: focusedBorder,
                        filled: true,
                        fillColor: AppColors.of(context).borderSubtle,
                        prefixText: '.openci/',
                        prefixStyle: TextStyle(
                          fontSize: 13,
                          color: AppColors.of(context).textTertiary,
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
                          ? AppColors.of(context).borderSubtle
                          : Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.15),
                      border: Border.all(
                        color: isLoading.value
                            ? AppColors.of(context).border
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
                              color: AppColors.of(context).textSecondary,
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
                : AppColors.of(context).border,
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
                  : AppColors.of(context).textTertiary,
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
                          ? AppColors.of(context).textPrimary
                          : AppColors.of(context).textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.of(context).textTertiary,
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
                      : AppColors.of(context).border,
                  width: isSelected ? 0 : 1.5,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 12,
                      color: AppColors.of(context).textPrimary,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
