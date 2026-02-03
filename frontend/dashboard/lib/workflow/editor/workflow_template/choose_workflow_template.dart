import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard/firebase/firestore_paths.dart';
import 'package:dashboard/firebase/firestore_provider.dart';
import 'package:dashboard/workflow/editor/workflow_template/react_native_expo_android_cd_form.dart';
import 'package:dashboard/workflow/editor/workflow_template/react_native_expo_ios_cd_form.dart';
import 'package:dashboard/workflow/editor/workflow_template/workflow_template.dart';
import 'package:dashboard/workflow/workflow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:highlight/languages/shell.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ChooseWorkflowTemplate extends HookConsumerWidget {
  const ChooseWorkflowTemplate({
    super.key,
    required this.documentId,
  });

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codeController = useState(
      CodeController(
        text: 'echo "Hello World"',
        language: shell,
      ),
    );
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
                  final template = workflowTemplateList[index];
                  return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: InkWell(
                      onTap: () {
                        if (template.name == 'react_native_expo_cd_ios') {
                          _showReactNativeExpoIosCdForm(context);
                        } else if (template.name ==
                            'react_native_expo_cd_android') {
                          _showReactNativeExpoAndroidCdForm(context);
                        } else {
                          var script = 'echo "Hello World"';
                          if (template.name == 'set_version_ios_with_tag') {
                            script = '''
echo "Set version to \$OPENCI_TAG"
cd ios
xcrun agvtool new-marketing-version \$OPENCI_TAG
''';
                          } else if (template.name ==
                              'set_version_android_with_tag') {
                            script = '''
echo "Set version to \$OPENCI_TAG"
npm version \$OPENCI_TAG --no-git-tag-version --allow-same-version --force
npx -y react-native-version --never-amend
''';
                          }
                          codeController.value = CodeController(
                            text: script,
                            language: shell,
                          );
                          _showCodeEditorForm(
                            context,
                            codeController: codeController,
                            template: template,
                            ref: ref,
                          );
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        width: 100,
                        height: 100,
                        child: Center(
                          child: Text(
                            template.title,
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

  void _showReactNativeExpoIosCdForm(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return ReactNativeExpoIosCdForm(documentId: documentId);
      },
    );
  }

  void _showReactNativeExpoAndroidCdForm(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return ReactNativeExpoAndroidCdForm(documentId: documentId);
      },
    );
  }

  void _showCodeEditorForm(
    BuildContext context, {
    required ValueNotifier<CodeController> codeController,
    required WorkflowTemplate template,
    required WidgetRef ref,
  }) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  top: 12.0,
                  bottom: 12.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          "Write your code",
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
              CodeTheme(
                data: CodeThemeData(),
                child: SingleChildScrollView(
                  child: CodeField(
                    controller: codeController.value,
                  ),
                ),
              ),
              SizedBox(height: 12.0),
              ElevatedButton(
                onPressed: () async {
                  await ref
                      .watch(firestoreProvider)
                      .collection(workflowsCollection)
                      .doc(documentId)
                      .update({
                        'workflowSteps': FieldValue.arrayUnion([
                          WorkflowStep(
                            name: template.title,
                            command: codeController.value.text,
                            isCompleted: true,
                          ).toJson(),
                        ]),
                      });
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text("OK"),
              ),
            ],
          ),
        );
      },
    );
  }
}
