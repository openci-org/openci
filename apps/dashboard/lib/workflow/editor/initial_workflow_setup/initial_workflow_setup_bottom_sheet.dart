import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:dashboard/workflow/editor/initial_workflow_setup/directories_provider.dart';
import 'package:dashboard/workflow/editor/initial_workflow_setup/github_connection_banner.dart';
import 'package:dashboard/workflow/editor/initial_workflow_setup/github_connection_provider.dart';
import 'package:dashboard/workflow/editor/initial_workflow_setup/initial_workflow_setup_provider.dart';
import 'package:dashboard/workflow/editor/initial_workflow_setup/repositories_provider.dart';
import 'package:dashboard/workflow/workflow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class InitialWorkflowSetupBottomSheet extends HookConsumerWidget {
  const InitialWorkflowSetupBottomSheet({super.key});

  static const _width = 260.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(initialWorkflowSetupProvider);
    final controller = ref.read(initialWorkflowSetupProvider.notifier);
    final team = ref.watch(teamStateProvider).value;
    final isGitHubConnected = ref.watch(isGitHubConnectedProvider);

    final nameController = useTextEditingController();

    final branchControllers = <String, TextEditingController>{};
    for (final type in ['push', 'pull_request']) {
      branchControllers[type] = useTextEditingController(
        text: state.triggers[type] ?? '',
      );
    }

    final hasBranchTrigger =
        state.triggers.containsKey('push') ||
        state.triggers.containsKey('pull_request');

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Initial Setup',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 20.0),
                if (state.selectedRepository.isNotEmpty &&
                    state.selectedWorkingDirectory.isNotEmpty &&
                    hasBranchTrigger)
                  InitialSetupSummary(state: state),
                SizedBox(
                  width: _width,
                  child: TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Workflow Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(height: 20.0),
                if (!isGitHubConnected)
                  SizedBox(
                    width: _width,
                    child: GitHubConnectionBanner(
                      onConnectPressed: () async {
                        final url = Uri.parse(
                          'https://github.com/apps/openci-org/installations/new',
                        ).replace(queryParameters: {'state': team?.id ?? ''});
                        await url_launcher.launchUrl(url);
                      },
                    ),
                  )
                else
                  SizedBox(
                    width: _width,
                    child: ref
                        .watch(repositoriesProvider)
                        .when(
                          loading: () => TextFormField(
                            enabled: false,
                            decoration: InputDecoration(
                              labelText: 'Repository',
                              border: OutlineInputBorder(),
                              suffixIcon: SizedBox(
                                width: 16,
                                height: 16,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          error: (e, _) => TextFormField(
                            enabled: false,
                            decoration: InputDecoration(
                              labelText: 'Repository',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(
                                Icons.error_outline,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                          data: (repos) => Autocomplete<GitHubRepository>(
                            displayStringForOption: (repo) => repo.fullName,
                            optionsBuilder: (textEditingValue) {
                              if (textEditingValue.text.isEmpty) {
                                return repos;
                              }
                              final query = textEditingValue.text.toLowerCase();
                              return repos.where(
                                (repo) =>
                                    repo.fullName.toLowerCase().contains(query),
                              );
                            },
                            onSelected: (repo) {
                              controller.updateSelectedRepository(
                                repo.fullName,
                              );
                            },
                            fieldViewBuilder:
                                (
                                  context,
                                  textController,
                                  focusNode,
                                  onFieldSubmitted,
                                ) {
                                  return TextFormField(
                                    controller: textController,
                                    focusNode: focusNode,
                                    decoration: InputDecoration(
                                      labelText: 'Repository',
                                      border: OutlineInputBorder(),
                                      suffixIcon: Icon(Icons.search, size: 20),
                                    ),
                                  );
                                },
                            optionsMaxHeight: 200,
                          ),
                        ),
                  ),
                SizedBox(height: 20.0),
                if (state.selectedRepository.isEmpty)
                  SizedBox(
                    width: _width,
                    child: TextFormField(
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Current Working Directory',
                        hintText: 'Select a repository first',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: _width,
                    child: ref
                        .watch(directoriesProvider)
                        .when(
                          loading: () => TextFormField(
                            enabled: false,
                            decoration: InputDecoration(
                              labelText: 'Current Working Directory',
                              border: OutlineInputBorder(),
                              suffixIcon: SizedBox(
                                width: 16,
                                height: 16,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          error: (e, _) => TextFormField(
                            enabled: false,
                            decoration: InputDecoration(
                              labelText: 'Current Working Directory',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(
                                Icons.error_outline,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                          data: (dirs) => Autocomplete<String>(
                            optionsBuilder: (textEditingValue) {
                              if (textEditingValue.text.isEmpty) {
                                return dirs;
                              }
                              final query = textEditingValue.text.toLowerCase();
                              return dirs.where(
                                (dir) => dir.toLowerCase().contains(query),
                              );
                            },
                            onSelected: (value) {
                              controller.updateSelectedWorkingDirectory(value);
                            },
                            fieldViewBuilder:
                                (
                                  context,
                                  textController,
                                  focusNode,
                                  onFieldSubmitted,
                                ) {
                                  return TextFormField(
                                    controller: textController,
                                    focusNode: focusNode,
                                    decoration: InputDecoration(
                                      labelText: 'Current Working Directory',
                                      border: OutlineInputBorder(),
                                      suffixIcon: Icon(
                                        Icons.folder_open,
                                        size: 20,
                                      ),
                                    ),
                                  );
                                },
                            optionsMaxHeight: 200,
                          ),
                        ),
                  ),
                SizedBox(height: 20.0),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: _width,
                    child: Text(
                      'Triggers',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: _width,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: TriggerType.values
                        .map(
                          (type) => FilterChip(
                            label: Text(type.toString()),
                            selected: state.triggers.containsKey(
                              type.toString(),
                            ),
                            onSelected: (selected) {
                              final current = Map<String, String?>.from(
                                state.triggers,
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
                              controller.updateTriggers(current);
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
                for (final type in ['push', 'pull_request'])
                  if (state.triggers.containsKey(type)) ...[
                    SizedBox(height: 12.0),
                    SizedBox(
                      width: _width,
                      child: TextFormField(
                        controller: branchControllers[type],
                        decoration: InputDecoration(
                          labelText: '$type branch',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          final current = Map<String, String?>.from(
                            state.triggers,
                          );
                          current[type] = value;
                          controller.updateTriggers(current);
                        },
                      ),
                    ),
                  ],
                SizedBox(height: 24.0),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(_width, 48),
                  ),
                  onPressed: () async {
                    await controller.save(
                      name: nameController.text,
                      selectedRepository: state.selectedRepository,
                      selectedWorkingDirectory: state.selectedWorkingDirectory,
                    );

                    if (!context.mounted) return;
                    context.showSnackBarMessage(
                      'Workflow created successfully',
                    );

                    Navigator.of(context).pop();
                  },
                  icon: Icon(Icons.check),
                  label: Text('OK, let\'s go!'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InitialSetupSummary extends StatelessWidget {
  const InitialSetupSummary({super.key, required this.state});
  final InitialWorkflowSetupState state;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: InitialWorkflowSetupBottomSheet._width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8.0,
        children: [
          Text(
            'Summary',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'In the '),
                TextSpan(
                  text: state.selectedRepository,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' repository, triggers: '),
                for (final entry in state.triggers.entries) ...[
                  TextSpan(
                    text: entry.key,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (entry.value != null && entry.value!.isNotEmpty) ...[
                    TextSpan(text: ' ('),
                    TextSpan(
                      text: entry.value,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: ')'),
                  ],
                  TextSpan(text: ' '),
                ],
                TextSpan(
                  text: 'using the ',
                ),
                TextSpan(
                  text: state.selectedWorkingDirectory,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' directory.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
