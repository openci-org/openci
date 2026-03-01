import 'dart:convert';
import 'dart:io';

import 'package:dashboard/supabase/supabase_provider.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
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

    final serviceAccountJsonController = useTextEditingController();

    final keystoreController = useTextEditingController();
    final keystorePasswordController = useTextEditingController();
    final keyAliasController = useTextEditingController(text: 'upload-key');

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
                            final result = await FilePicker.platform.pickFiles(
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
                            final result = await FilePicker.platform.pickFiles(
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
                            final supabase = ref.read(supabaseClientProvider);
                            final teamId = ref
                                .read(teamStateProvider)
                                .requireValue
                                .id;

                            await supabase.from('environment_variables').insert(
                              [
                                {
                                  'team_id': teamId,
                                  'key': 'GOOGLE_PLAY_SERVICE_ACCOUNT_JSON',
                                  'value': serviceAccountJsonController.text,
                                  'is_secret': true,
                                },
                                {
                                  'team_id': teamId,
                                  'key': 'ANDROID_KEYSTORE_BASE64',
                                  'value': keystoreController.text,
                                  'is_secret': true,
                                },
                                {
                                  'team_id': teamId,
                                  'key': 'ANDROID_KEYSTORE_PASSWORD',
                                  'value': keystorePasswordController.text,
                                  'is_secret': true,
                                },
                                {
                                  'team_id': teamId,
                                  'key': 'ANDROID_KEY_ALIAS',
                                  'value': keyAliasController.text,
                                  'is_secret': true,
                                },
                                {
                                  'team_id': teamId,
                                  'key': 'ANDROID_PACKAGE_NAME',
                                  'value': packageNameController.text,
                                  'is_secret': true,
                                },
                              ],
                            );
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
