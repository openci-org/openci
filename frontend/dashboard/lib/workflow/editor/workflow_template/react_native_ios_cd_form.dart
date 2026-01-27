import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard/firebase/firestore_paths.dart';
import 'package:dashboard/workflow/workflow.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

const reactNativeIosCdTemplateId = 'loremIpsum';

class ReactNativeIosCdForm extends HookWidget {
  const ReactNativeIosCdForm({
    super.key,
    required this.documentId,
  });

  final String documentId;

  @override
  Widget build(BuildContext context) {
    final formKey = useMemoized(() => GlobalKey<FormState>());

    final issuerIdController = useTextEditingController();
    final keyIdController = useTextEditingController();
    final privateKeyController = useTextEditingController();
    final teamIdController = useTextEditingController();
    final bundleIdController = useTextEditingController();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
            child: Row(
              children: [
                const SizedBox(width: 48),
                Expanded(
                  child: Text(
                    "React Native CD (iOS)",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
                const SizedBox(width: 8.0),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: issuerIdController,
                      decoration: InputDecoration(
                        labelText: "Issuer id",
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: keyIdController,
                      decoration: InputDecoration(
                        labelText: "Key id",
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: privateKeyController,
                      decoration: InputDecoration(
                        labelText: "Private Key (.p8)",
                        helperText: "Base64 encoded string",
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.upload_file),
                          onPressed: () async {
                            final result = await FilePicker.pickFiles(
                              type: FileType.any,
                              withData: true,
                            );

                            if (result != null) {
                              if (!result.files.single.name
                                  .toLowerCase()
                                  .endsWith('.p8')) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please select a .p8 file'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                                return;
                              }

                              try {
                                Uint8List? fileBytes;
                                if (kIsWeb) {
                                  fileBytes = result.files.single.bytes;
                                } else if (result.files.single.path != null) {
                                  fileBytes = await File(
                                    result.files.single.path!,
                                  ).readAsBytes();
                                }

                                if (fileBytes != null) {
                                  final base64String = base64Encode(fileBytes);
                                  privateKeyController.text = base64String;
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to read file: $e'),
                                    ),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: teamIdController,
                      decoration: InputDecoration(
                        labelText: "Team id",
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: bundleIdController,
                      decoration: InputDecoration(
                        labelText: "Bundle id",
                      ),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          // final functions = FirebaseFunctions.instanceFor(
                          //   region: 'asia-northeast1',
                          // );
                          // final createSecret = functions.httpsCallable(
                          //   'createSecretV1',
                          // );

                          // await Future.wait([
                          //   createSecret.call({
                          //     'name': 'APP_STORE_CONNECT_ISSUER_ID',
                          //     'value': issuerIdController.text,
                          //   }),
                          //   createSecret.call({
                          //     'name': 'APP_STORE_CONNECT_KEY_ID',
                          //     'value': keyIdController.text,
                          //   }),
                          //   createSecret.call({
                          //     'name': 'APP_STORE_CONNECT_PRIVATE_KEY_BASE64',
                          //     'value': privateKeyController.text,
                          //   }),
                          // ]);

                          await FirebaseFirestore.instance
                              .collection(workflowsCollection)
                              .doc(documentId)
                              .update({
                                'workflowSteps': FieldValue.arrayUnion([
                                  WorkflowStep(
                                    name: 'Start React Native iOS CD',
                                    commands: [
                                      "echo 'Start React Native iOS CD'",
                                    ],
                                    isCompleted: true,
                                  ).toJson(),
                                  WorkflowStep(
                                    name: 'Start React Native iOS CD',
                                    commands: [
                                      "echo 'Start React Native iOS CD'",
                                    ],
                                    isCompleted: true,
                                  ).toJson(),
                                ]),
                              });
                        },
                        child: const Text("Add Workflow"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
