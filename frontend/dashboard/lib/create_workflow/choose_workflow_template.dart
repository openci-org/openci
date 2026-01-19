import 'package:dashboard/create_workflow/create_workflow_provider.dart';
import 'package:dashboard/create_workflow/workflow_template.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChooseWorkflowTemplate extends ConsumerWidget {
  const ChooseWorkflowTemplate({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(createWorkflowProvider.notifier);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    "Choose a Workflow Template",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close),
              ),
              SizedBox(width: 8.0),
            ],
          ),
        ),
        Expanded(
          child: Scrollbar(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: GridView.builder(
                itemCount: workflowTemplateList.length,
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1,
                ),
                itemBuilder: (_, index) {
                  return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: InkWell(
                      onTap: () {
                        controller.addStep(
                          WorkflowStep(
                            name: 'Flutter Analyze',
                            isCompleted: true,
                          ),
                        );
                        controller.addStep(
                          WorkflowStep(
                            name: 'Flutter Test',
                            isCompleted: true,
                          ),
                        );
                        controller.addStep(
                          WorkflowStep(
                            name: 'Flutter Build iOS',
                            isCompleted: true,
                          ),
                        );
                        controller.addStep(
                          WorkflowStep(
                            name: 'Flutter Build Android',
                            isCompleted: true,
                          ),
                        );
                        controller.addStep(
                          WorkflowStep(
                            name: 'Ship to Firebase App Distribution',
                            isCompleted: false,
                          ),
                        );

                        Navigator.pop(context);
                      },
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
          ),
        ),
      ],
    );
  }
}
