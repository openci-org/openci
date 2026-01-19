import 'package:dashboard/create_workflow/workflow_template.dart';
import 'package:flutter/material.dart';

class ChooseWorkflowTemplate extends StatelessWidget {
  const ChooseWorkflowTemplate({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
    );
  }
}
