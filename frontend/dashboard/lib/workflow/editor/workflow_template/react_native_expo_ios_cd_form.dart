import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard/firebase/firestore_paths.dart';
import 'package:dashboard/firebase/firestore_provider.dart';
import 'package:dashboard/firebase/functions_provider.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:dashboard/workflow/workflow.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ReactNativeExpoIosCdForm extends HookConsumerWidget {
  const ReactNativeExpoIosCdForm({
    super.key,
    required this.documentId,
  });

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());

    final issuerIdController = useTextEditingController();
    final keyIdController = useTextEditingController();
    final privateKeyController = useTextEditingController();
    final teamIdController = useTextEditingController();
    final schemeNameController = useTextEditingController();

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
                    "React Native (Expo) CD (iOS)",
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
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.any,
                              withData: true,
                            );

                            if (result != null) {
                              if (!result.files.single.name
                                  .toLowerCase()
                                  .endsWith('.p8')) {
                                if (context.mounted) {
                                  context.showSnackBarMessage(
                                    'Please select a .p8 file',
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
                                  context.showSnackBarMessage(
                                    'Failed to read file: $e',
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
                      controller: schemeNameController,
                      decoration: InputDecoration(
                        labelText: "Scheme Name",
                        helperText: "e.g. YourAppName",
                      ),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            final functions = ref.read(functionsProvider);
                            final teamId =
                                ref.read(teamStateProvider).requireValue.id;
                            final createSecret = functions.httpsCallable(
                              'createSecretV1',
                            );

                            final issuerIdSecretDocumentId =
                                (await createSecret.call({
                              'name': 'APP_STORE_CONNECT_ISSUER_ID',
                              'value': issuerIdController.text,
                              'teamId': teamId,
                            }))
                                    .data['documentId'];

                            final keyIdSecretDocumentId =
                                (await createSecret.call({
                              'name': 'APP_STORE_CONNECT_KEY_ID',
                              'value': keyIdController.text,
                              'teamId': teamId,
                            }))
                                    .data['documentId'];

                            final privateKeySecretDocumentId =
                                (await createSecret.call({
                              'name': 'APP_STORE_CONNECT_PRIVATE_KEY_BASE64',
                              'value': privateKeyController.text,
                              'teamId': teamId,
                            }))
                                    .data['documentId'];

                            final teamIdSecretDocumentId =
                                (await createSecret.call({
                              'name': 'TEAM_ID',
                              'value': teamIdController.text,
                              'teamId': teamId,
                            }))
                                    .data['documentId'];

                            await ref
                                .watch(firestoreProvider)
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
                                  command: "npx expo prebuild --platform ios",
                                  isCompleted: true,
                                ).toJson(),
                                WorkflowStep(
                                  name: 'Create API Key File',
                                  command:
                                      "echo \$APP_STORE_CONNECT_PRIVATE_KEY_BASE64 | base64 -D > ios/AuthKey_\$APP_STORE_CONNECT_KEY_ID.p8",
                                  isCompleted: true,
                                  requiredSecrets: [
                                    WorkflowStepRequiredSecret(
                                      key:
                                          'APP_STORE_CONNECT_PRIVATE_KEY_BASE64',
                                      secretDocumentId:
                                          privateKeySecretDocumentId,
                                    ),
                                    WorkflowStepRequiredSecret(
                                      key: 'APP_STORE_CONNECT_KEY_ID',
                                      secretDocumentId: keyIdSecretDocumentId,
                                    ),
                                  ],
                                ).toJson(),
                                WorkflowStep(
                                  name: 'Debug: Verify API Key File',
                                  command:
                                      "echo '=== API Key File ===' && ls -la ios/AuthKey_*.p8 && echo '=== First 2 lines ===' && head -n 2 ios/AuthKey_\$APP_STORE_CONNECT_KEY_ID.p8 && echo '=== Last line ===' && tail -n 1 ios/AuthKey_\$APP_STORE_CONNECT_KEY_ID.p8",
                                  isCompleted: true,
                                  requiredSecrets: [
                                    WorkflowStepRequiredSecret(
                                      key: 'APP_STORE_CONNECT_KEY_ID',
                                      secretDocumentId: keyIdSecretDocumentId,
                                    ),
                                  ],
                                ).toJson(),
                                WorkflowStep(
                                  name: 'Create ExportOptions.plist',
                                  command:
                                      "printf '%s\\n' '<?xml version=\"1.0\" encoding=\"UTF-8\"?>' '<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">' '<plist version=\"1.0\">' '<dict>' '<key>method</key>' '<string>app-store-connect</string>' '<key>teamID</key>' '<string>'\"\$TEAM_ID\"'</string>' '</dict>' '</plist>' > ios/ExportOptions.plist",
                                  isCompleted: true,
                                  requiredSecrets: [
                                    WorkflowStepRequiredSecret(
                                      key: 'TEAM_ID',
                                      secretDocumentId: teamIdSecretDocumentId,
                                    ),
                                  ],
                                ).toJson(),
                                WorkflowStep(
                                  name: 'Archive Build',
                                  command:
                                      "xcodebuild -quiet -workspace ios/*.xcworkspace -scheme ${schemeNameController.text} -configuration Release -archivePath \$PWD/ios/build/App.xcarchive archive -allowProvisioningUpdates -authenticationKeyPath \$PWD/ios/AuthKey_\$APP_STORE_CONNECT_KEY_ID.p8 -authenticationKeyID \$APP_STORE_CONNECT_KEY_ID -authenticationKeyIssuerID \$APP_STORE_CONNECT_ISSUER_ID DEVELOPMENT_TEAM=\$TEAM_ID > /tmp/xcodebuild.log 2>&1 || (tail -n 200 /tmp/xcodebuild.log && exit 1)",
                                  isCompleted: true,
                                  requiredSecrets: [
                                    WorkflowStepRequiredSecret(
                                      key: 'APP_STORE_CONNECT_KEY_ID',
                                      secretDocumentId: keyIdSecretDocumentId,
                                    ),
                                    WorkflowStepRequiredSecret(
                                      key: 'APP_STORE_CONNECT_ISSUER_ID',
                                      secretDocumentId:
                                          issuerIdSecretDocumentId,
                                    ),
                                    WorkflowStepRequiredSecret(
                                      key: 'TEAM_ID',
                                      secretDocumentId: teamIdSecretDocumentId,
                                    ),
                                  ],
                                ).toJson(),
                                WorkflowStep(
                                  name: 'Export IPA',
                                  command:
                                      "xcodebuild -exportArchive -archivePath \$PWD/ios/build/App.xcarchive -exportOptionsPlist ios/ExportOptions.plist -exportPath \$PWD/ios/build -allowProvisioningUpdates -authenticationKeyPath \$PWD/ios/AuthKey_\$APP_STORE_CONNECT_KEY_ID.p8 -authenticationKeyID \$APP_STORE_CONNECT_KEY_ID -authenticationKeyIssuerID \$APP_STORE_CONNECT_ISSUER_ID > /tmp/export.log 2>&1 || (tail -n 200 /tmp/export.log && exit 1)",
                                  isCompleted: true,
                                  requiredSecrets: [
                                    WorkflowStepRequiredSecret(
                                      key: 'APP_STORE_CONNECT_KEY_ID',
                                      secretDocumentId: keyIdSecretDocumentId,
                                    ),
                                    WorkflowStepRequiredSecret(
                                      key: 'APP_STORE_CONNECT_ISSUER_ID',
                                      secretDocumentId:
                                          issuerIdSecretDocumentId,
                                    ),
                                  ],
                                ).toJson(),
                                WorkflowStep(
                                  name: 'Upload to App Store Connect',
                                  command:
                                      "mkdir -p ~/private_keys && cp ios/AuthKey_\$APP_STORE_CONNECT_KEY_ID.p8 ~/private_keys/ && xcrun altool --upload-app --type ios --file \$PWD/ios/build/*.ipa --apiKey \$APP_STORE_CONNECT_KEY_ID --apiIssuer \$APP_STORE_CONNECT_ISSUER_ID 2>&1 || exit 1",
                                  isCompleted: true,
                                  requiredSecrets: [
                                    WorkflowStepRequiredSecret(
                                      key: 'APP_STORE_CONNECT_KEY_ID',
                                      secretDocumentId: keyIdSecretDocumentId,
                                    ),
                                    WorkflowStepRequiredSecret(
                                      key: 'APP_STORE_CONNECT_ISSUER_ID',
                                      secretDocumentId:
                                          issuerIdSecretDocumentId,
                                    ),
                                  ],
                                ).toJson(),
                              ]),
                            });
                          } catch (e) {
                            if (context.mounted) {
                              context.showSnackBarMessage(
                                'Failed to add workflow: $e',
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
