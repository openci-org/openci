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
                          try {
                            final functions = FirebaseFunctions.instanceFor(
                              region: 'asia-northeast1',
                            );
                            final createSecret = functions.httpsCallable(
                              'createSecretV1',
                            );

                            final issuerIdSecretDocumentId =
                                (await createSecret.call({
                                  'name': 'APP_STORE_CONNECT_ISSUER_ID',
                                  'value': issuerIdController.text,
                                })).data['documentId'];

                            final keyIdSecretDocumentId =
                                (await createSecret.call({
                                  'name': 'APP_STORE_CONNECT_KEY_ID',
                                  'value': keyIdController.text,
                                })).data['documentId'];

                            final privateKeySecretDocumentId =
                                (await createSecret.call({
                                  'name':
                                      'APP_STORE_CONNECT_PRIVATE_KEY_BASE64',
                                  'value': privateKeyController.text,
                                })).data['documentId'];

                            final teamIdSecretDocumentId =
                                (await createSecret.call({
                                  'name': 'TEAM_ID',
                                  'value': teamIdController.text,
                                })).data['documentId'];

                            final bundleIdSecretDocumentId =
                                (await createSecret.call({
                                  'name': 'BUNDLE_ID',
                                  'value': bundleIdController.text,
                                })).data['documentId'];

                            await FirebaseFirestore.instance.collection(workflowsCollection).doc(documentId).update({
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
                                  name: 'Install Dependencies (Cocoapods)',
                                  command: "cd ios && pod install",
                                  isCompleted: true,
                                ).toJson(),
                                WorkflowStep(
                                  name: 'Create API Key File',
                                  command:
                                      "echo \"\$APP_STORE_CONNECT_PRIVATE_KEY_BASE64\" | base64 -D > ios/AuthKey_\$APP_STORE_CONNECT_KEY_ID.p8",
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
                                  name: 'Create ExportOptions.plist',
                                  command:
                                      '''cat <<EOF > ios/ExportOptions.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>\$TEAM_ID</string>
</dict>
</plist>
EOF''',
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
                                      "xcodebuild -workspace ios/*.xcworkspace -configuration Release -archivePath \$PWD/ios/build/App.xcarchive archive -allowProvisioningUpdates -authenticationKeyPath \$PWD/ios/AuthKey_\$APP_STORE_CONNECT_KEY_ID.p8 -authenticationKeyID \$APP_STORE_CONNECT_KEY_ID -authenticationKeyIssuerID \$APP_STORE_CONNECT_ISSUER_ID",
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
                                  name: 'Export IPA',
                                  command:
                                      "xcodebuild -exportArchive -archivePath \$PWD/ios/build/App.xcarchive -exportOptionsPlist ios/ExportOptions.plist -exportPath \$PWD/ios/build -allowProvisioningUpdates -authenticationKeyPath \$PWD/ios/AuthKey_\$APP_STORE_CONNECT_KEY_ID.p8 -authenticationKeyID \$APP_STORE_CONNECT_KEY_ID -authenticationKeyIssuerID \$APP_STORE_CONNECT_ISSUER_ID",
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
                                      "xcrun altool --upload-app --type ios --file \$PWD/ios/build/*.ipa --apiKey \$APP_STORE_CONNECT_KEY_ID --apiIssuer \$APP_STORE_CONNECT_ISSUER_ID",
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

                              //   command:
                              //       "echo \"\$APP_STORE_CONNECT_PRIVATE_KEY_BASE64\" | base64 --decode > ios/AuthKey_\$APP_STORE_CONNECT_KEY_ID.p8",
                              //   isCompleted: true,
                              //   requiredSecrets: [
                              //     WorkflowStepRequiredSecret(
                              //       key: 'APP_STORE_CONNECT_PRIVATE_KEY_BASE64',
                              //       secretDocumentId:
                              //           privateKeySecretDocumentId,
                              //     ),
                              //     WorkflowStepRequiredSecret(
                              //       key: 'APP_STORE_CONNECT_KEY_ID',
                              //       secretDocumentId: keyIdSecretDocumentId,
                              //     ),
                              //   ],
                              // ).toJson(),
                              //                                   WorkflowStep(
                              //                                     name: 'Create ExportOptions.plist',
                              //                                     command:
                              //                                         '''cat <<EOF > ios/ExportOptions.plist
                              // <?xml version="1.0" encoding="UTF-8"?>
                              // <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
                              // <plist version="1.0">
                              // <dict>
                              //     <key>method</key>
                              //     <string>app-store</string>
                              //     <key>teamID</key>
                              //     <string>\$TEAM_ID</string>
                              // </dict>
                              // </plist>
                              // EOF''',
                              //                                     isCompleted: true,
                              //                                     requiredSecrets: [
                              //                                       WorkflowStepRequiredSecret(
                              //                                         key: 'TEAM_ID',
                              //                                         secretDocumentId:
                              //                                             teamIdSecretDocumentId,
                              //                                       ),
                              //                                     ],
                              //                                   ).toJson(),
                              // WorkflowStep(
                              //   name: 'Archive Build',
                              //   command:
                              //       "xcodebuild -workspace ios/*.xcworkspace -scheme \$IOS_SCHEME_NAME -configuration Release -archivePath \$PWD/ios/build/App.xcarchive archive -allowProvisioningUpdates -authenticationKeyPath \$PWD/ios/AuthKey_\$APP_STORE_CONNECT_KEY_ID.p8 -authenticationKeyID \$APP_STORE_CONNECT_KEY_ID -authenticationKeyIssuerID \$APP_STORE_CONNECT_ISSUER_ID",
                              //   isCompleted: true,
                              // ).toJson(),
                              // WorkflowStep(
                              //   name: 'Export IPA',
                              //   command:
                              //       "xcodebuild -exportArchive -archivePath \$PWD/ios/build/App.xcarchive -exportOptionsPlist ios/ExportOptions.plist -exportPath \$PWD/ios/build -allowProvisioningUpdates -authenticationKeyPath \$PWD/ios/AuthKey_\$APP_STORE_CONNECT_KEY_ID.p8 -authenticationKeyID \$APP_STORE_CONNECT_KEY_ID -authenticationKeyIssuerID \$APP_STORE_CONNECT_ISSUER_ID",
                              //   isCompleted: true,
                              // ).toJson(),
                              // WorkflowStep(
                              //   name: 'Upload to App Store Connect',
                              //   command:
                              //       "xcrun altool --upload-app --type ios --file \$PWD/ios/build/*.ipa --apiKey \$APP_STORE_CONNECT_KEY_ID --apiIssuer \$APP_STORE_CONNECT_ISSUER_ID",
                              //   isCompleted: true,
                              // ).toJson(),
                            });
                          } catch (e) {
                            print(e);
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
