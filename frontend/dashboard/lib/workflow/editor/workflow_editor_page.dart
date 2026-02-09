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
          return StepList(
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

class StepList extends StatelessWidget {
  const StepList({
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
    return SingleChildScrollView(
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
          if (steps.isNotEmpty) ...[
            StepConnector(documentId: documentId, insertAt: 0),
            ...steps.asMap().entries.expand((entry) {
              final index = entry.key;
              final step = entry.value;
              return [
                if (index > 0)
                  StepConnector(documentId: documentId, insertAt: index),
                StepCard(
                  title: step.name,
                  isCompleted: step.isCompleted,
                ),
              ];
            }),
          ],
          IconButton.filled(
            onPressed: () => showModalBottomSheet(
              isScrollControlled: true,
              context: context,
              builder: (_) => SizedBox(
                height: MediaQuery.of(context).size.height * 0.8,
                child: ChooseWorkflowTemplate(documentId: documentId),
              ),
            ),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class StepConnector extends StatelessWidget {
  const StepConnector({
    required this.documentId,
    required this.insertAt,
    super.key,
  });
  final String documentId;
  final int insertAt;

  @override
  Widget build(BuildContext context) {
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
            onPressed: () => showModalBottomSheet(
              isScrollControlled: true,
              context: context,
              builder: (_) => SizedBox(
                height: MediaQuery.of(context).size.height * 0.8,
                child: ChooseWorkflowTemplate(
                  documentId: documentId,
                  insertAt: insertAt,
                ),
              ),
            ),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
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
