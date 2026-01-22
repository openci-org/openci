import 'package:dashboard/create_workflow/choose_workflow_template.dart';
import 'package:dashboard/workflow/editor/initial_workflow_setup/initial_workflow_setup_bottom_sheet.dart';
import 'package:dashboard/workflow/editor/workflow_editor_provider.dart';
import 'package:dashboard/workflow/workflow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkflowEditorPage extends ConsumerWidget {
  const WorkflowEditorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workflowEditorProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Workflow Editor'),
      ),
      body: state.when(
        data: (workflow) {
          if (workflow == null) {
            return Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Theme.of(context).secondaryHeaderColor,
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => InitialWorkflowSetupBottomSheet(),
                  );
                },
                child: Text('Start Initial Setup'),
              ),
            );
          }
          return WorkflowList(steps: workflow.workflowSteps);
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
      child: ListTile(
        leading: Icon(
          isCompleted ? Icons.check_circle : Icons.timelapse,
          color: isCompleted ? Colors.green : Colors.amber,
        ),
        title: Text(title),
        trailing: Icon(Icons.more_vert),
      ),
    );
  }
}
