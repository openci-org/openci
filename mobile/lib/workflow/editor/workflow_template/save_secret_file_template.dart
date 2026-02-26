import 'dart:convert';
import 'dart:io';

import 'package:dashboard/secret_manager/secret_manager_provider.dart';
import 'package:dashboard/supabase/supabase_provider.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SaveSecretFileTemplate extends HookConsumerWidget {
  const SaveSecretFileTemplate({
    super.key,
    required this.documentId,
    this.insertAt,
  });

  final String documentId;
  final int? insertAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final secretsAsync = ref.watch(secretManagerProvider);
    final selectedSecret = useState<Secret?>(null);
    final isNewUpload = useState(true);
    final fileNameController = useTextEditingController();
    final directoryController = useTextEditingController(text: './');
    final secretNameController = useTextEditingController();
    final uploadedBase64 = useState<String?>(null);
    final uploadedFileName = useState<String?>(null);
    final isLoading = useState(false);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          Text(
            "Save Secret File",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Toggle: New Upload or Existing Secret
                  Text(
                    "Secret Source",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        label: Text("Upload New"),
                        icon: Icon(Icons.upload_file),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text("Existing Secret"),
                        icon: Icon(Icons.key),
                      ),
                    ],
                    selected: {isNewUpload.value},
                    onSelectionChanged: (value) {
                      isNewUpload.value = value.first;
                      selectedSecret.value = null;
                      uploadedBase64.value = null;
                      uploadedFileName.value = null;
                      secretNameController.clear();
                      fileNameController.clear();
                    },
                  ),

                  const SizedBox(height: 24.0),

                  // New Upload Section
                  if (isNewUpload.value) ...[
                    TextFormField(
                      controller: secretNameController,
                      decoration: const InputDecoration(
                        labelText: "Secret Name",
                        helperText:
                            "e.g. FIREBASE_OPTIONS, GOOGLE_SERVICES_JSON",
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    InkWell(
                      borderRadius: BorderRadius.circular(12.0),
                      onTap: () async {
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
                              uploadedBase64.value = base64Encode(fileBytes);
                              uploadedFileName.value = result.files.single.name;
                              if (fileNameController.text.isEmpty) {
                                fileNameController.text =
                                    result.files.single.name;
                              }
                              if (secretNameController.text.isEmpty) {
                                secretNameController.text = result
                                    .files
                                    .single
                                    .name
                                    .toUpperCase()
                                    .replaceAll('.', '_')
                                    .replaceAll('-', '_');
                              }
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
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: uploadedFileName.value != null
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.outline.withValues(alpha: 0.5),
                            width: uploadedFileName.value != null ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12.0),
                          color: uploadedFileName.value != null
                              ? Theme.of(context).colorScheme.primaryContainer
                                    .withValues(alpha: 0.3)
                              : null,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              uploadedFileName.value != null
                                  ? Icons.check_circle
                                  : Icons.cloud_upload_outlined,
                              size: 36,
                              color: uploadedFileName.value != null
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              uploadedFileName.value ?? "Click to select file",
                              style: TextStyle(
                                color: uploadedFileName.value != null
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.outline,
                                fontWeight: uploadedFileName.value != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            if (uploadedFileName.value != null) ...[
                              const SizedBox(height: 4.0),
                              Text(
                                "Base64 encoded • Tap to change",
                                style:
                                    Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Existing Secret Section
                  if (!isNewUpload.value) ...[
                    secretsAsync.when(
                      data: (secrets) {
                        if (secrets.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24.0),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline.withValues(alpha: 0.5),
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: const Center(
                              child: Text("No secrets found"),
                            ),
                          );
                        }
                        return DropdownButtonFormField<Secret>(
                          initialValue: selectedSecret.value,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: "Select Secret",
                          ),
                          items: secrets
                              .map(
                                (secret) => DropdownMenuItem(
                                  value: secret,
                                  child: Text(
                                    secret.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            selectedSecret.value = value;
                          },
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, _) => Text('Error: $error'),
                    ),
                  ],

                  const SizedBox(height: 24.0),
                  const Divider(),
                  const SizedBox(height: 16.0),

                  // Output Settings
                  Text(
                    "Output Settings",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: fileNameController,
                    decoration: const InputDecoration(
                      labelText: "File Name",
                      helperText: "e.g. firebase_options.dart",
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: directoryController,
                    decoration: const InputDecoration(
                      labelText: "Directory",
                      helperText: "e.g. lib/, android/app/",
                    ),
                  ),

                  const SizedBox(height: 16.0),

                  // Preview
                  Builder(
                    builder: (context) {
                      final secretKey = isNewUpload.value
                          ? secretNameController.text.isNotEmpty
                                ? secretNameController.text
                                : 'SECRET_NAME'
                          : selectedSecret.value?.name ?? 'SECRET_NAME';
                      final fileName = fileNameController.text.isNotEmpty
                          ? fileNameController.text
                          : 'filename';
                      final dir = directoryController.text.isNotEmpty
                          ? directoryController.text
                          : './';
                      final normalizedDir = dir.endsWith('/') ? dir : '$dir/';
                      final command =
                          'echo \$$secretKey | base64 -D > $normalizedDir$fileName';

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Preview Command",
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline,
                                  ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              command,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32.0),

                  // Submit
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        minimumSize: Size(double.infinity, 50),
                      ),
                      onPressed: isLoading.value
                          ? null
                          : () async {
                              // Validation
                              if (fileNameController.text.isEmpty) {
                                context.showSnackBarMessage(
                                  'Please enter a file name',
                                );
                                return;
                              }
                              if (isNewUpload.value) {
                                if (secretNameController.text.isEmpty) {
                                  context.showSnackBarMessage(
                                    'Please enter a secret name',
                                  );
                                  return;
                                }
                                if (uploadedBase64.value == null) {
                                  context.showSnackBarMessage(
                                    'Please select a file to upload',
                                  );
                                  return;
                                }
                              } else {
                                if (selectedSecret.value == null) {
                                  context.showSnackBarMessage(
                                    'Please select a secret',
                                  );
                                  return;
                                }
                              }

                              isLoading.value = true;
                              try {
                                if (isNewUpload.value) {
                                  final supabase = ref.read(
                                    supabaseClientProvider,
                                  );
                                  final teamId = ref
                                      .read(teamStateProvider)
                                      .requireValue
                                      .id;
                                  await supabase
                                      .from('environment_variables')
                                      .insert({
                                        'org_id': teamId,
                                        'key': secretNameController.text,
                                        'value': uploadedBase64.value!,
                                        'is_secret': true,
                                      });
                                }

                                final supabase = ref.read(
                                  supabaseClientProvider,
                                );
                                await supabase
                                    .from('workflows')
                                    .update({
                                      'yaml_definition': '',
                                    })
                                    .eq('id', documentId);

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  context.showSnackBarMessage(
                                    'Failed to add step: $e',
                                  );
                                }
                              } finally {
                                isLoading.value = false;
                              }
                            },
                      child: isLoading.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text("Add Step"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
