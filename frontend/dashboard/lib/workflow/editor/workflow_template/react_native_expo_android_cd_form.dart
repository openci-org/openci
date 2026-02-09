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

class ReactNativeExpoAndroidCdForm extends HookConsumerWidget {
  const ReactNativeExpoAndroidCdForm({
    super.key,
    required this.documentId,
  });

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());

    // Google Play Console Service Account
    final serviceAccountJsonController = useTextEditingController();

    // Keystore settings
    final keystoreController = useTextEditingController();
    final keystorePasswordController = useTextEditingController();
    final keyAliasController = useTextEditingController(text: 'upload-key');

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
                    "React Native (Expo) CD (Android)",
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
                                  context.showSnackBarMessage(
                                    'Please select a .json file',
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
                            final functions = ref.read(functionsProvider);
                            final teamId = ref
                                .read(teamStateProvider)
                                .requireValue
                                .id;
                            final createSecret = functions.httpsCallable(
                              'createSecretV1',
                            );

                            // Create secrets
                            final serviceAccountSecretId =
                                (await createSecret.call({
                                  'name': 'GOOGLE_PLAY_SERVICE_ACCOUNT_JSON',
                                  'value': serviceAccountJsonController.text,
                                  'teamId': teamId,
                                })).data['documentId'];

                            final keystoreSecretId = (await createSecret.call({
                              'name': 'ANDROID_KEYSTORE_BASE64',
                              'value': keystoreController.text,
                              'teamId': teamId,
                            })).data['documentId'];

                            final keystorePasswordSecretId =
                                (await createSecret.call({
                                  'name': 'ANDROID_KEYSTORE_PASSWORD',
                                  'value': keystorePasswordController.text,
                                  'teamId': teamId,
                                })).data['documentId'];

                            final keyAliasSecretId = (await createSecret.call({
                              'name': 'ANDROID_KEY_ALIAS',
                              'value': keyAliasController.text,
                              'teamId': teamId,
                            })).data['documentId'];

                            // Use same password for both keystore and key
                            final keyPasswordSecretId =
                                keystorePasswordSecretId;

                            final packageNameSecretId =
                                (await createSecret.call({
                                  'name': 'ANDROID_PACKAGE_NAME',
                                  'value': packageNameController.text,
                                  'teamId': teamId,
                                })).data['documentId'];

                            await ref
                                .read(firestoreProvider)
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
                                      name: 'Setup Android SDK',
                                      command:
                                          "echo 'sdk.dir='\$HOME'/android-sdk' > android/local.properties",
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
                                          "cat >> android/gradle.properties << 'EOF'\nMYAPP_UPLOAD_STORE_FILE=release.keystore\nMYAPP_UPLOAD_STORE_PASSWORD=\$ANDROID_KEYSTORE_PASSWORD\nMYAPP_UPLOAD_KEY_ALIAS=\$ANDROID_KEY_ALIAS\nMYAPP_UPLOAD_KEY_PASSWORD=\$ANDROID_KEY_PASSWORD\nEOF",
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
                                      name: 'Patch build.gradle for signing',
                                      command: '''awk '{
  if (/signingConfigs \\{/) {
    print \$0
    print "        release {"
    print "            storeFile file(project.findProperty(\\"MYAPP_UPLOAD_STORE_FILE\\") ?: \\"release.keystore\\")"
    print "            storePassword project.findProperty(\\"MYAPP_UPLOAD_STORE_PASSWORD\\") ?: \\"\\""
    print "            keyAlias project.findProperty(\\"MYAPP_UPLOAD_KEY_ALIAS\\") ?: \\"\\""
    print "            keyPassword project.findProperty(\\"MYAPP_UPLOAD_KEY_PASSWORD\\") ?: \\"\\""
    print "        }"
    next
  }
  if (/signingConfig signingConfigs\\.debug/ && /release/) {
    gsub(/signingConfigs\\.debug/, "signingConfigs.release")
  }
  print
}' android/app/build.gradle > android/app/build.gradle.tmp && mv android/app/build.gradle.tmp android/app/build.gradle''',
                                      isCompleted: true,
                                    ).toJson(),
                                    WorkflowStep(
                                      name: 'Build Release AAB',
                                      command:
                                          "export JAVA_HOME=/opt/homebrew/opt/openjdk@17 && export ANDROID_HOME=\$HOME/android-sdk && export PATH=\$JAVA_HOME/bin:\$ANDROID_HOME/platform-tools:\$PATH && echo 'sdk.dir='\$ANDROID_HOME > android/local.properties && cd android && ./gradlew bundleRelease > /tmp/gradle.log 2>&1 || (tail -n 200 /tmp/gradle.log && exit 1)",
                                      isCompleted: true,
                                    ).toJson(),
                                    WorkflowStep(
                                      name:
                                          'Upload to Google Play (${trackController.text})',
                                      command:
                                          '''
# Parse service account JSON
SA_FILE="android/play-store-credentials.json"
CLIENT_EMAIL=\$(grep -o '"client_email"[^,]*' \$SA_FILE | cut -d'"' -f4)
PRIVATE_KEY=\$(sed -n 's/.*"private_key": "\\(.*\\)".*/\\1/p' \$SA_FILE | sed 's/\\\\n/\\n/g')

# Create JWT header and payload
NOW=\$(date +%s)
EXP=\$((NOW + 3600))
HEADER=\$(printf '{"alg":"RS256","typ":"JWT"}' | base64 | tr -d '=' | tr '/+' '_-' | tr -d '\\n')
PAYLOAD=\$(printf '{"iss":"%s","scope":"https://www.googleapis.com/auth/androidpublisher","aud":"https://oauth2.googleapis.com/token","iat":%s,"exp":%s}' "\$CLIENT_EMAIL" "\$NOW" "\$EXP" | base64 | tr -d '=' | tr '/+' '_-' | tr -d '\\n')

# Sign with RSA
printf '%s' "\$PRIVATE_KEY" > /tmp/sa_key.pem
SIGNATURE=\$(printf '%s.%s' "\$HEADER" "\$PAYLOAD" | openssl dgst -sha256 -sign /tmp/sa_key.pem | base64 | tr -d '=' | tr '/+' '_-' | tr -d '\\n')
rm /tmp/sa_key.pem
JWT="\$HEADER.\$PAYLOAD.\$SIGNATURE"

# Get access token
TOKEN_RESPONSE=\$(curl -s -X POST https://oauth2.googleapis.com/token \\
  -d "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=\$JWT")
ACCESS_TOKEN=\$(echo "\$TOKEN_RESPONSE" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

if [ -z "\$ACCESS_TOKEN" ]; then
  echo "Failed to get access token:"
  echo "\$TOKEN_RESPONSE"
  exit 1
fi
echo "Access token obtained"

PACKAGE_NAME=\$ANDROID_PACKAGE_NAME
AAB_PATH="android/app/build/outputs/bundle/release/app-release.aab"

# Create edit
echo "Creating edit for \$PACKAGE_NAME..."
EDIT_RESPONSE=\$(curl -s -X POST \\
  "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/\$PACKAGE_NAME/edits" \\
  -H "Authorization: Bearer \$ACCESS_TOKEN" \\
  -H "Content-Type: application/json" \\
  -d '{}')
echo "Edit response: \$EDIT_RESPONSE"
EDIT_ID=\$(echo "\$EDIT_RESPONSE" | grep -o '"id":"[^"]*' | cut -d'"' -f4)

if [ -z "\$EDIT_ID" ]; then
  echo "Failed to create edit. Check if:"
  echo "1. App is registered in Google Play Console"
  echo "2. Service account has 'Release manager' permission"
  exit 1
fi
echo "Edit ID: \$EDIT_ID"

# Upload AAB
echo "Uploading AAB..."
UPLOAD_RESPONSE=\$(curl -s -X POST \\
  "https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/\$PACKAGE_NAME/edits/\$EDIT_ID/bundles?uploadType=media" \\
  -H "Authorization: Bearer \$ACCESS_TOKEN" \\
  -H "Content-Type: application/octet-stream" \\
  --data-binary @"\$AAB_PATH")
echo "Upload response: \$UPLOAD_RESPONSE"
VERSION_CODE=\$(echo "\$UPLOAD_RESPONSE" | grep -o '"versionCode":[0-9]*' | cut -d':' -f2)

if [ -z "\$VERSION_CODE" ]; then
  echo "Failed to upload AAB"
  exit 1
fi
echo "Version code: \$VERSION_CODE"

# Update track
echo "Updating track..."
TRACK_RESPONSE=\$(curl -s -X PUT \\
  "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/\$PACKAGE_NAME/edits/\$EDIT_ID/tracks/${trackController.text}" \\
  -H "Authorization: Bearer \$ACCESS_TOKEN" \\
  -H "Content-Type: application/json" \\
  -d '{"track":"${trackController.text}","releases":[{"versionCodes":['\$VERSION_CODE'],"status":"completed"}]}')
echo "Track response: \$TRACK_RESPONSE"

# Commit edit
echo "Committing..."
COMMIT_RESPONSE=\$(curl -s -X POST \\
  "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/\$PACKAGE_NAME/edits/\$EDIT_ID:commit" \\
  -H "Authorization: Bearer \$ACCESS_TOKEN")
echo "Commit response: \$COMMIT_RESPONSE"

if echo "\$COMMIT_RESPONSE" | grep -q '"error"'; then
  echo "Failed to commit"
  exit 1
fi

echo "Upload complete!"
''',
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
