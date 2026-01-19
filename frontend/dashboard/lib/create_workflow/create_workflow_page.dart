import 'package:dashboard/create_workflow/create_workflow_provider.dart';
import 'package:dashboard/create_workflow/workflow_template.dart';
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
          ? WorkflowList()
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
        onPressed: () {},
        child: Icon(Icons.add),
      ),
    );
  }
}

class WorkflowList extends StatelessWidget {
  const WorkflowList({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: ListView(
        children: [
          BasicInformationWorkflowCard(),
          SizedBox(height: 20.0),
          Center(
            child: IconButton.filled(
              onPressed: () {
                showModalBottomSheet(
                  isScrollControlled: true,
                  context: context,
                  builder: (_) => SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: Text(
                            "Choose a Workflow Template",
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),

                        Expanded(
                          child: GridView.builder(
                            itemCount: workflowTemplateList.length,
                            shrinkWrap: true,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 1,
                                ),
                            itemBuilder: (_, index) {
                              return Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: InkWell(
                                  onTap: () {},
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    width: 100,
                                    height: 100,
                                    child: Center(
                                      child: Text(
                                        workflowTemplateList[index].title,
                                        style: TextStyle(
                                          fontSize: 20,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}

class BasicInformationWorkflowCard extends StatelessWidget {
  const BasicInformationWorkflowCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.check_circle_outline, color: Colors.green),
        title: Text('Basic Information'),
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
