import 'package:dashboard/create_workflow/choose_workflow_template.dart';
import 'package:dashboard/create_workflow/create_workflow_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateWorkflowPage extends ConsumerWidget {
  const CreateWorkflowPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createWorkflowProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Workflow'),
      ),
      body: state.isCreated
          ? WorkflowList(
              steps: state.selectedWorkflowSteps,
            )
          : Center(
              child: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => CreateWorkflowBottomSheet(),
                  );
                },
                child: Text('Start Initial Setup'),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => state.isCreated
            ? _showChooseWorkflowTemplate(context)
            : _showCreateWorkflowBottomSheet(context),
        child: Icon(Icons.add),
      ),
    );
  }
}

Future<void> _showChooseWorkflowTemplate(
  BuildContext context,
) {
  return showModalBottomSheet(
    isScrollControlled: true,
    context: context,
    builder: (_) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: ChooseWorkflowTemplate(),
    ),
  );
}

Future<void> _showCreateWorkflowBottomSheet(
  BuildContext context,
) {
  return showModalBottomSheet(
    isScrollControlled: true,
    context: context,
    builder: (_) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: CreateWorkflowBottomSheet(),
    ),
  );
}

class WorkflowList extends StatelessWidget {
  const WorkflowList({super.key, required this.steps});
  final List<WorkflowStep> steps;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: ListView.separated(
        itemCount: steps.length,
        separatorBuilder: (_, _) => SizedBox(height: 12.0),
        itemBuilder: (_, index) {
          final step = steps[index];
          return Column(
            children: [
              BasicInformationWorkflowCard(
                title: step.name,
                isCompleted: step.isCompleted,
              ),
              if (index == steps.length - 1) ..._addButton(context),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _addButton(BuildContext context) {
    return [
      SizedBox(height: 20.0),
      Center(
        child: IconButton.filled(
          onPressed: () => _showChooseWorkflowTemplate(context),
          icon: const Icon(Icons.add),
        ),
      ),
    ];
  }
}

class BasicInformationWorkflowCard extends StatelessWidget {
  const BasicInformationWorkflowCard({
    required this.title,
    required this.isCompleted,
    super.key,
  });
  final bool isCompleted;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isCompleted ? Colors.blue.shade100 : Colors.amber.shade100,
      child: ListTile(
        leading: Icon(
          isCompleted ? Icons.check_circle : Icons.edit,
          color: isCompleted ? Colors.blue : Colors.amber,
        ),
        title: Text(title),
        trailing: Icon(Icons.more_vert),
      ),
    );
  }
}

class CreateWorkflowBottomSheet extends ConsumerWidget {
  const CreateWorkflowBottomSheet({super.key});

  static const _width = 260.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createWorkflowProvider);
    final controller = ref.read(createWorkflowProvider.notifier);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 30.0,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: Text(
                    'Initial Setup',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
            if (state.selectedRepository.isNotEmpty &&
                state.selectedWorkingDirectory.isNotEmpty &&
                state.selectedTriggerBranch.isNotEmpty)
              InitialSetupSummary(
                state: state,
              ),
            DropdownMenu(
              width: _width,
              controller: TextEditingController(text: state.selectedRepository),
              label: const Text('Repository'),
              dropdownMenuEntries: [
                DropdownMenuEntry(
                  value: 'open-ci-io/openci',
                  label: 'open-ci-io/openci',
                ),
                DropdownMenuEntry(value: 'mafreud/test', label: 'mafreud/test'),
              ],
              onSelected: (value) {
                if (value == null) return;
                controller.updateSelectedRepository(value);
              },
            ),
            DropdownMenu(
              width: _width,
              controller: TextEditingController(
                text: state.selectedWorkingDirectory,
              ),
              label: const Text('Current Working Directory'),
              helperText: 'Use default if you don\'t use monorepo',
              dropdownMenuEntries: [
                DropdownMenuEntry(value: '/', label: '/'),
                DropdownMenuEntry(value: '/frontend', label: '/frontend'),
                DropdownMenuEntry(
                  value: '/frontend/dashboard',
                  label: '/frontend/dashboard',
                ),
              ],
              onSelected: (value) {
                if (value == null) return;
                controller.updateSelectedWorkingDirectory(value);
              },
            ),
            DropdownMenu(
              width: _width,
              controller: TextEditingController(
                text: state.selectedTriggerType.toString(),
              ),
              label: const Text('Trigger Type'),
              dropdownMenuEntries: [
                DropdownMenuEntry(value: 'push', label: 'push'),
                DropdownMenuEntry(value: 'pull_request', label: 'pull_request'),
              ],
              onSelected: (value) {
                if (value == null) return;
                controller.updateSelectedTriggerType(
                  TriggerType.fromValue(value),
                );
              },
            ),
            DropdownMenu(
              width: _width,
              controller: TextEditingController(
                text: state.selectedTriggerBranch,
              ),
              label: const Text('Trigger Branch'),
              dropdownMenuEntries: [
                DropdownMenuEntry(value: 'main', label: 'main'),
                DropdownMenuEntry(value: 'develop', label: 'develop'),
              ],
              onSelected: (value) {
                if (value == null) return;
                controller.updateSelectedTriggerBranch(value);
              },
            ),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(_width, 48),
              ),
              onPressed: () {
                controller.updateIsCreated(true);
                controller.addStep(
                  WorkflowStep(
                    name: 'Basic Information',
                    isCompleted: true,
                  ),
                );
                Navigator.of(context).pop();
              },
              icon: Icon(Icons.check),
              label: Text('OK, let\'s go!'),
            ),
          ],
        ),
      ),
    );
  }
}

class InitialSetupSummary extends StatelessWidget {
  const InitialSetupSummary({super.key, required this.state});
  final CreateWorkflowState state;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CreateWorkflowBottomSheet._width,
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
                TextSpan(text: ' repository, when a '),
                TextSpan(
                  text: state.selectedTriggerType.toString(),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' is created to the '),
                TextSpan(
                  text: state.selectedTriggerBranch,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: ' branch, the workflow will run using the ',
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
