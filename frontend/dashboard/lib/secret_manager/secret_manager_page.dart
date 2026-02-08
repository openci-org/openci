import 'package:dashboard/secret_manager/secret_manager_provider.dart';
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
                      await ref
                          .read(secretManagerProvider.notifier)
                          .addSecret(
                            secretNameController.text,
                            secretValueController.text,
                          );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to add secret: $e'),
                          behavior: SnackBarBehavior.floating,
                        ),
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
