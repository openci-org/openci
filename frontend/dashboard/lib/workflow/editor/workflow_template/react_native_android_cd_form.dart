import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/firebase/firestore_paths.dart';
import 'package:dashboard/workflow/workflow.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ReactNativeAndroidCdForm extends HookWidget {
  const ReactNativeAndroidCdForm({
    super.key,
    required this.documentId,
  });

  final String documentId;

  @override
  Widget build(BuildContext context) {
    final formKey = useMemoized(() => GlobalKey<FormState>());

    // Google Play Console Service Account
    final serviceAccountJsonController = useTextEditingController();

    // Keystore settings
    final keystoreController = useTextEditingController();
    final keystorePasswordController = useTextEditingController();
    final keyAliasController = useTextEditingController();
    final keyPasswordController = useTextEditingController();

    // App settings
    final packageNameController = useTextEditingController();
    final trackController = useTextEditingController(text: 'internal');

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
                    "React Native CD (Android)",
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
                    // Section: Google Play Console
                    Text(
                      "Google Play Console",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: serviceAccountJsonController,
                      decoration: InputDecoration(
                        labelText: "Service Account JSON",
                        helperText: "Base64 encoded JSON key file",
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
                                  .endsWith('.json')) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please select a .json file',
                                      ),
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
                                  serviceAccountJsonController.text =
                                      base64String;
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

                    const SizedBox(height: 24),

                    // Section: Signing Key
                    Text(
                      "Signing Key (Keystore)",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: keystoreController,
                      decoration: InputDecoration(
                        labelText: "Keystore (.jks or .keystore)",
                        helperText: "Base64 encoded keystore file",
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.upload_file),
                          onPressed: () async {
                            final result = await FilePicker.pickFiles(
                              type: FileType.any,
                              withData: true,
                            );

                            if (result != null) {
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
                                  keystoreController.text = base64String;
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
                      controller: keystorePasswordController,
                      decoration: const InputDecoration(
                        labelText: "Keystore Password",
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: keyAliasController,
                      decoration: const InputDecoration(
                        labelText: "Key Alias",
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: keyPasswordController,
                      decoration: const InputDecoration(
                        labelText: "Key Password",
                      ),
                      obscureText: true,
                    ),

                    const SizedBox(height: 24),

                    // Section: App Settings
                    Text(
                      "App Settings",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: packageNameController,
                      decoration: const InputDecoration(
                        labelText: "Package Name",
                        helperText: "e.g. com.example.app",
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: trackController,
                      decoration: const InputDecoration(
                        labelText: "Track",
                        helperText: "internal, alpha, beta, or production",
                      ),
                    ),

                    const SizedBox(height: 32),
                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            final functions = FirebaseFunctions.instanceFor(
                              region: 'asia-northeast1',
                            );
                            final createSecret = functions.httpsCallable(
                              'createSecretV1',
                            );

                            // Create secrets
                            final serviceAccountSecretId =
                                (await createSecret.call({
                                  'name': 'GOOGLE_PLAY_SERVICE_ACCOUNT_JSON',
                                  'value': serviceAccountJsonController.text,
                                })).data['documentId'];

                            final keystoreSecretId = (await createSecret.call({
                              'name': 'ANDROID_KEYSTORE_BASE64',
                              'value': keystoreController.text,
                            })).data['documentId'];

                            final keystorePasswordSecretId =
                                (await createSecret.call({
                                  'name': 'ANDROID_KEYSTORE_PASSWORD',
                                  'value': keystorePasswordController.text,
                                })).data['documentId'];

                            final keyAliasSecretId = (await createSecret.call({
                              'name': 'ANDROID_KEY_ALIAS',
                              'value': keyAliasController.text,
                            })).data['documentId'];

                            final keyPasswordSecretId =
                                (await createSecret.call({
                                  'name': 'ANDROID_KEY_PASSWORD',
                                  'value': keyPasswordController.text,
                                })).data['documentId'];

                            final packageNameSecretId =
                                (await createSecret.call({
                                  'name': 'ANDROID_PACKAGE_NAME',
                                  'value': packageNameController.text,
                                })).data['documentId'];

                            await FirebaseFirestore.instance
                                .collection(workflowsCollection)
                                .doc(documentId)
                                .update({
                                  'workflowSteps': FieldValue.arrayUnion([
                                    WorkflowStep(
                                      name: 'Install Node.js',
                                      command: "brew install node",
                                      isCompleted: true,
                                    ).toJson(),
                                    WorkflowStep(
                                      name: 'Install Dependencies (npm)',
                                      command: "npm install",
                                      isCompleted: true,
                                    ).toJson(),
                                    WorkflowStep(
                                      name: 'Prebuild (Expo)',
                                      command:
                                          "npx expo prebuild --platform android",
                                      isCompleted: true,
                                    ).toJson(),
                                    WorkflowStep(
                                      name: 'Create Keystore File',
                                      command:
                                          "echo \$ANDROID_KEYSTORE_BASE64 | base64 -D > android/app/release.keystore",
                                      isCompleted: true,
                                      requiredSecrets: [
                                        WorkflowStepRequiredSecret(
                                          key: 'ANDROID_KEYSTORE_BASE64',
                                          secretDocumentId: keystoreSecretId,
                                        ),
                                      ],
                                    ).toJson(),
                                    WorkflowStep(
                                      name:
                                          'Create Google Play Service Account',
                                      command:
                                          "echo \$GOOGLE_PLAY_SERVICE_ACCOUNT_JSON | base64 -D > android/play-store-credentials.json",
                                      isCompleted: true,
                                      requiredSecrets: [
                                        WorkflowStepRequiredSecret(
                                          key:
                                              'GOOGLE_PLAY_SERVICE_ACCOUNT_JSON',
                                          secretDocumentId:
                                              serviceAccountSecretId,
                                        ),
                                      ],
                                    ).toJson(),
                                    WorkflowStep(
                                      name: 'Configure Signing',
                                      command:
                                          "cat >> android/gradle.properties << EOF\nMYAPP_UPLOAD_STORE_FILE=release.keystore\nMYAPP_UPLOAD_KEY_ALIAS=\$ANDROID_KEY_ALIAS\nMYAPP_UPLOAD_STORE_PASSWORD=\$ANDROID_KEYSTORE_PASSWORD\nMYAPP_UPLOAD_KEY_PASSWORD=\$ANDROID_KEY_PASSWORD\nEOF",
                                      isCompleted: true,
                                      requiredSecrets: [
                                        WorkflowStepRequiredSecret(
                                          key: 'ANDROID_KEYSTORE_PASSWORD',
                                          secretDocumentId:
                                              keystorePasswordSecretId,
                                        ),
                                        WorkflowStepRequiredSecret(
                                          key: 'ANDROID_KEY_ALIAS',
                                          secretDocumentId: keyAliasSecretId,
                                        ),
                                        WorkflowStepRequiredSecret(
                                          key: 'ANDROID_KEY_PASSWORD',
                                          secretDocumentId: keyPasswordSecretId,
                                        ),
                                      ],
                                    ).toJson(),
                                    WorkflowStep(
                                      name:
                                          'Configure build.gradle for signing',
                                      command:
                                          '''sed -i '' 's/signingConfigs {/signingConfigs { release { storeFile file("release.keystore"); storePassword System.getenv("ANDROID_KEYSTORE_PASSWORD") ?: project.findProperty("MYAPP_UPLOAD_STORE_PASSWORD"); keyAlias System.getenv("ANDROID_KEY_ALIAS") ?: project.findProperty("MYAPP_UPLOAD_KEY_ALIAS"); keyPassword System.getenv("ANDROID_KEY_PASSWORD") ?: project.findProperty("MYAPP_UPLOAD_KEY_PASSWORD") }/' android/app/build.gradle && sed -i '' 's/signingConfig signingConfigs.debug/signingConfig signingConfigs.release/' android/app/build.gradle''',
                                      isCompleted: true,
                                    ).toJson(),
                                    WorkflowStep(
                                      name: 'Build Release AAB',
                                      command:
                                          "cd android && ./gradlew bundleRelease > /tmp/gradle.log 2>&1 || (tail -n 200 /tmp/gradle.log && exit 1)",
                                      isCompleted: true,
                                      requiredSecrets: [
                                        WorkflowStepRequiredSecret(
                                          key: 'ANDROID_KEYSTORE_PASSWORD',
                                          secretDocumentId:
                                              keystorePasswordSecretId,
                                        ),
                                        WorkflowStepRequiredSecret(
                                          key: 'ANDROID_KEY_ALIAS',
                                          secretDocumentId: keyAliasSecretId,
                                        ),
                                        WorkflowStepRequiredSecret(
                                          key: 'ANDROID_KEY_PASSWORD',
                                          secretDocumentId: keyPasswordSecretId,
                                        ),
                                      ],
                                    ).toJson(),
                                    WorkflowStep(
                                      name: 'Install fastlane',
                                      command:
                                          "gem install fastlane --no-document",
                                      isCompleted: true,
                                    ).toJson(),
                                    WorkflowStep(
                                      name:
                                          'Upload to Google Play (${trackController.text})',
                                      command:
                                          "fastlane supply --aab android/app/build/outputs/bundle/release/app-release.aab --json_key android/play-store-credentials.json --package_name \$ANDROID_PACKAGE_NAME --track ${trackController.text} --skip_upload_metadata --skip_upload_images --skip_upload_screenshots 2>&1 || exit 1",
                                      isCompleted: true,
                                      requiredSecrets: [
                                        WorkflowStepRequiredSecret(
                                          key: 'ANDROID_PACKAGE_NAME',
                                          secretDocumentId: packageNameSecretId,
                                        ),
                                      ],
                                    ).toJson(),
                                  ]),
                                });
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to add workflow: $e'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } finally {
                            if (context.mounted) {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            }
                          }
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
