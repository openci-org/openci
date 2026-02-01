import 'package:dashboard/workflow/editor/workflow_editor_provider.dart';
import 'package:dashboard/workflow/editor/workflow_template/choose_workflow_template.dart';
import 'package:dashboard/workflow/workflow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
          return WorkflowList(
            steps: workflow.workflowSteps,
            workflowConfig: workflow.workflowConfig,
            documentId: workflow.documentId,
            workflowName: workflow.name,
            onNameChanged: (name) {
              ref
                  .read(workflowEditorProvider(workflowId).notifier)
                  .updateName(name);
            },
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

Future<void> _showChooseWorkflowTemplate(
  BuildContext context,
  String documentId,
) {
  return showModalBottomSheet(
    isScrollControlled: true,
    context: context,
    builder: (_) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: ChooseWorkflowTemplate(documentId: documentId),
    ),
  );
}

class WorkflowList extends StatelessWidget {
  const WorkflowList({
    super.key,
    required this.steps,
    required this.workflowConfig,
    required this.documentId,
    required this.workflowName,
    required this.onNameChanged,
  });
  final List<WorkflowStep> steps;
  final WorkflowConfig workflowConfig;
  final String documentId;
  final String workflowName;
  final ValueChanged<String> onNameChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        children: [
          Card(
            child: ListTile(
              leading: Icon(
                Icons.check_circle,
                color: Colors.green,
              ),
              title: Text('Basic Information'),
            ),
          ),
          if (steps.isNotEmpty)
            SizedBox(
              height: 24,
              child: Icon(Icons.arrow_downward),
            ),
          if (steps.isEmpty) ..._addButton(context, documentId),
          if (steps.isNotEmpty)
            Expanded(
              child: ListView.separated(
                itemCount: steps.length,
                separatorBuilder: (_, _) => SizedBox(
                  height: 24.0,
                  child: Icon(Icons.arrow_downward),
                ),
                itemBuilder: (_, index) {
                  final step = steps[index];

                  return Column(
                    children: [
                      StepCard(
                        title: step.name,
                        isCompleted: step.isCompleted,
                      ),
                      if (index == steps.length - 1)
                        ..._addButton(context, documentId),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _addButton(BuildContext context, String documentId) {
    return [
      SizedBox(height: 20.0),
      Center(
        child: IconButton.filled(
          onPressed: () => _showChooseWorkflowTemplate(context, documentId),
          icon: const Icon(Icons.add),
        ),
      ),
    ];
  }
}

class StepCard extends StatelessWidget {
  const StepCard({
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
      ),
    );
  }
}
