import 'package:dashboard/i18n/strings.g.dart';
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
    final secretsT = t.secrets;
    return Scaffold(
      appBar: AppBar(
        title: Text(secretsT.title),
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
            return Center(child: Text(secretsT.noSecrets));
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
