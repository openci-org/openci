import 'dart:convert';

import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/secret_manager/secret_manager_provider.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SecretManagerTab extends HookConsumerWidget {
  const SecretManagerTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(secretManagerProvider);
    final secretsT = t.secrets;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            showDragHandle: true,
            context: context,
            isScrollControlled: true,
            builder: (context) => const _AddSecretBottomSheet(),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: state.when(
        data: (secrets) {
          final hasCertKey = secrets.any(
            (s) => s.name == 'OPENCI_CERTIFICATE_PRIVATE_KEY',
          );
          final hasAscApiKey = secrets.any(
            (s) => s.name == 'OPENCI_ASC_ISSUER_ID',
          );
          final setupCards = <Widget>[
            if (!hasCertKey) _GenerateCertificateKeyButton(),
            if (!hasAscApiKey) _SetupAscApiKeyButton(),
          ];
          if (secrets.isEmpty) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Column(
                    children: [
                      Text(secretsT.noSecrets),
                      const SizedBox(height: 24),
                      ...setupCards,
                    ],
                  ),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 16),
            itemCount: secrets.length + setupCards.length,
            itemBuilder: (context, index) {
              if (index < setupCards.length) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: setupCards[index],
                    ),
                  ),
                );
              }
              final secretIndex = index - setupCards.length;
              final secret = secrets[secretIndex];
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Card(
                    child: ListTile(
                      title: Text(secret.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              showModalBottomSheet(
                                showDragHandle: true,
                                context: context,
                                isScrollControlled: true,
                                builder: (context) =>
                                    _EditSecretBottomSheet(secret: secret),
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(t.common.delete),
                                  content: Text(secretsT.deleteConfirm),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: Text(t.common.cancel),
                                    ),
                                    FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            Theme.of(context).colorScheme.error,
                                      ),
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: Text(t.common.delete),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed != true || !context.mounted) return;
                              try {
                                await ref
                                    .read(secretManagerProvider.notifier)
                                    .deleteSecret(documentId: secret.id);
                                if (!context.mounted) return;
                                context.showSnackBarMessage(
                                  secretsT.deletedSuccess,
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                context.showSnackBarMessage('$e');
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(t.common.error(error: error.toString())),
        ),
      ),
    );
  }
}

class _AddSecretBottomSheet extends HookConsumerWidget {
  const _AddSecretBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final secretNameController = useTextEditingController();
    final secretValueController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final secretsT = t.secrets;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    Text(
                      secretsT.addSecret,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: secretNameController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: secretsT.secretName,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return secretsT.enterSecretName;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: secretValueController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: secretsT.secretValue,
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return secretsT.enterSecretValue;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        try {
                          await ref
                              .read(secretManagerProvider.notifier)
                              .addSecret(
                                secretNameController.text.trim(),
                                secretValueController.text,
                              );
                          if (!context.mounted) return;
                          context.showSnackBarMessage(
                            secretsT.addedSuccess,
                          );
                          Navigator.of(context).pop();
                        } catch (e) {
                          if (!context.mounted) return;
                          context.showSnackBarMessage('$e');
                        }
                      },
                      child: Text(secretsT.addSecret),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditSecretBottomSheet extends HookConsumerWidget {
  const _EditSecretBottomSheet({required this.secret});

  final Secret secret;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController(text: secret.name);
    final valueController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isLoading = useState(false);
    final secretsT = t.secrets;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    Text(
                      secretsT.editSecret,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: secretsT.secretName,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return secretsT.enterSecretName;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: valueController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: secretsT.newSecretValue,
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: isLoading.value
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              final name = nameController.text.trim();

                              isLoading.value = true;
                              try {
                                await ref
                                    .read(secretManagerProvider.notifier)
                                    .updateSecret(
                                      documentId: secret.id,
                                      name: name,
                                      value: valueController.text.isNotEmpty
                                          ? valueController.text
                                          : null,
                                    );
                                if (!context.mounted) return;
                                context.showSnackBarMessage(
                                  secretsT.updatedSuccess,
                                );
                                Navigator.of(context).pop();
                              } catch (e) {
                                isLoading.value = false;
                                if (!context.mounted) return;
                                context.showSnackBarMessage('$e');
                              }
                            },
                      child: isLoading.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(t.common.save),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GenerateCertificateKeyButton extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = useState(false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.key, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'iOS Code Signing',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Generate a certificate private key for iOS builds. This is required for automatic code signing.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isLoading.value
                    ? null
                    : () async {
                        isLoading.value = true;
                        try {
                          await ref
                              .read(secretManagerProvider.notifier)
                              .generateCertificateKey();
                          if (!context.mounted) return;
                          context.showSnackBarMessage(
                            'Certificate key generated successfully',
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          context.showSnackBarMessage('$e');
                        } finally {
                          if (context.mounted) isLoading.value = false;
                        }
                      },
                icon: isLoading.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.vpn_key),
                label: Text(
                  isLoading.value ? 'Generating...' : 'Generate Certificate Key',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupAscApiKeyButton extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = useState(false);
    final isExpanded = useState(false);
    final issuerIdController = useTextEditingController();
    final keyIdController = useTextEditingController();
    final privateKeyContent = useState<String?>(null);
    final p8FileName = useState<String?>(null);
    final formKey = useMemoized(() => GlobalKey<FormState>());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => isExpanded.value = !isExpanded.value,
              child: Row(
                children: [
                  Icon(
                    Icons.apple,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'App Store Connect API Key',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Icon(
                    isExpanded.value
                        ? Icons.expand_less
                        : Icons.expand_more,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Required for iOS code signing and TestFlight deployment.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (isExpanded.value) ...[
              const SizedBox(height: 16),
              Form(
                key: formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: issuerIdController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Issuer ID',
                        hintText: 'e.g. 69a6d....-....-....',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter Issuer ID';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: keyIdController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Key ID',
                        hintText: 'e.g. ABC123DEFG',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter Key ID';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['p8'],
                            withData: true,
                          );
                          if (result == null || result.files.isEmpty) return;
                          final file = result.files.first;
                          final bytes = file.bytes;
                          if (bytes == null) return;
                          privateKeyContent.value = utf8.decode(bytes);
                          p8FileName.value = file.name;
                        },
                        icon: Icon(
                          p8FileName.value != null
                              ? Icons.check_circle
                              : Icons.upload_file,
                        ),
                        label: Text(
                          p8FileName.value ?? 'Upload .p8 file',
                        ),
                      ),
                    ),
                    if (privateKeyContent.value == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Download the .p8 file from App Store Connect',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: isLoading.value
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                if (privateKeyContent.value == null) {
                                  context.showSnackBarMessage(
                                    'Please upload the .p8 file',
                                  );
                                  return;
                                }
                                isLoading.value = true;
                                try {
                                  await ref
                                      .read(secretManagerProvider.notifier)
                                      .setupAscApiKey(
                                        issuerId:
                                            issuerIdController.text.trim(),
                                        keyId: keyIdController.text.trim(),
                                        privateKey:
                                            privateKeyContent.value!,
                                      );
                                  if (!context.mounted) return;
                                  context.showSnackBarMessage(
                                    'ASC API Key configured successfully',
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  context.showSnackBarMessage('$e');
                                } finally {
                                  if (context.mounted) isLoading.value = false;
                                }
                              },
                        icon: isLoading.value
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          isLoading.value ? 'Saving...' : 'Save API Key',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
