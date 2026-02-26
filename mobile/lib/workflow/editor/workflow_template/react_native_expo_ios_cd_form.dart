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
                            final supabase = ref.read(supabaseClientProvider);
                            final teamId = ref
                                .read(teamStateProvider)
                                .requireValue
                                .id;

                            await supabase.from('environment_variables').insert(
                              [
                                {
                                  'org_id': teamId,
                                  'key': 'APP_STORE_CONNECT_ISSUER_ID',
                                  'value': issuerIdController.text,
                                  'is_secret': true,
                                },
                                {
                                  'org_id': teamId,
                                  'key': 'APP_STORE_CONNECT_KEY_ID',
                                  'value': keyIdController.text,
                                  'is_secret': true,
                                },
                                {
                                  'org_id': teamId,
                                  'key': 'APP_STORE_CONNECT_PRIVATE_KEY_BASE64',
                                  'value': privateKeyController.text,
                                  'is_secret': true,
                                },
                                {
                                  'org_id': teamId,
                                  'key': 'TEAM_ID',
                                  'value': teamIdController.text,
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
