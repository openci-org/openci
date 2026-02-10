import 'package:dashboard/secret_manager/secret_manager_provider.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SecretManagerPage extends HookConsumerWidget {
  const SecretManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final secretNameController = useTextEditingController();
    final secretValueController = useTextEditingController();

    final state = ref.watch(secretManagerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secret Manager'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          secretNameController.clear();
          secretValueController.clear();
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Add Secret'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: secretNameController,
                    decoration: InputDecoration(
                      labelText: 'SECRET_NAME',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: secretValueController,
                    decoration: InputDecoration(
                      labelText: 'Secret Value',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      await ref.read(secretManagerProvider.notifier).addSecret(
                            secretNameController.text,
                            secretValueController.text,
                          );
                    } catch (e) {
                      if (!context.mounted) return;
                      context.showSnackBarMessage(
                        'Failed to add secret: $e',
                      );
                    }
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: state.when(
        data: (secrets) {
          if (secrets.isEmpty) {
            return const Center(child: Text('No secrets found'));
          }
          return ListView.builder(
            itemCount: secrets.length,
            itemBuilder: (context, index) {
              final secret = secrets[index];
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Card(
                    child: ListTile(
                      title: Text(secret.name),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _showEditDialog(
                            context: context,
                            ref: ref,
                            secret: secret,
                            existingSecrets: secrets,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  void _showEditDialog({
    required BuildContext context,
    required WidgetRef ref,
    required Secret secret,
    required List<Secret> existingSecrets,
  }) {
    final nameController = TextEditingController(text: secret.name);
    final valueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return _EditSecretDialog(
          nameController: nameController,
          valueController: valueController,
          secret: secret,
          existingSecrets: existingSecrets,
          ref: ref,
        );
      },
    );
  }
}

class _EditSecretDialog extends HookConsumerWidget {
  const _EditSecretDialog({
    required this.nameController,
    required this.valueController,
    required this.secret,
    required this.existingSecrets,
    required this.ref,
  });

  final TextEditingController nameController;
  final TextEditingController valueController;
  final Secret secret;
  final List<Secret> existingSecrets;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = useState(false);
    final nameError = useState<String?>(null);

    return AlertDialog(
      title: const Text('Edit Secret'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'SECRET_NAME',
              border: const OutlineInputBorder(),
              errorText: nameError.value,
            ),
            onChanged: (value) {
              // Check for duplicate name in real-time
              if (value != secret.name &&
                  existingSecrets.any((s) => s.name == value)) {
                nameError.value = 'This name is already in use';
              } else {
                nameError.value = null;
              }
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: valueController,
            decoration: const InputDecoration(
              labelText: 'New Secret Value (leave empty to keep current)',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          if (nameController.text != secret.name &&
              nameController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Changing the name will also update all workflows that reference this secret.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: isLoading.value ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: isLoading.value
              ? null
              : () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) {
                    nameError.value = 'Name cannot be empty';
                    return;
                  }

                  // Check for duplicate
                  if (name != secret.name &&
                      existingSecrets.any((s) => s.name == name)) {
                    nameError.value = 'This name is already in use';
                    return;
                  }

                  isLoading.value = true;
                  try {
                    await this
                        .ref
                        .read(secretManagerProvider.notifier)
                        .updateSecret(
                          documentId: secret.id,
                          name: name,
                          value: valueController.text.isNotEmpty
                              ? valueController.text
                              : null,
                        );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  } catch (e) {
                    isLoading.value = false;
                    if (!context.mounted) return;
                    context.showSnackBarMessage(
                      'Failed to update secret: $e',
                    );
                  }
                },
          child: isLoading.value
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
