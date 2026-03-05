import 'package:dashboard/secret_manager/secret_manager_provider.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SecretManagerPage extends HookConsumerWidget {
  const SecretManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(secretManagerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secret Manager'),
      ),
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
                          showModalBottomSheet(
                            showDragHandle: true,
                            context: context,
                            isScrollControlled: true,
                            builder: (context) =>
                                _EditSecretBottomSheet(secret: secret),
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
}

class _AddSecretBottomSheet extends HookConsumerWidget {
  const _AddSecretBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final secretNameController = useTextEditingController();
    final secretValueController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());

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
                    const Text(
                      'Add Secret',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: secretNameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'SECRET_NAME',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a secret name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: secretValueController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Secret Value',
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a secret value';
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
                            'Secret added successfully',
                          );
                          Navigator.of(context).pop();
                        } catch (e) {
                          if (!context.mounted) return;
                          context.showSnackBarMessage('$e');
                        }
                      },
                      child: const Text('Add Secret'),
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
                    const Text(
                      'Edit Secret',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'SECRET_NAME',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a secret name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: valueController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText:
                            'New Secret Value (leave empty to keep current)',
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
                                  'Secret updated successfully',
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
                          : const Text('Save'),
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
