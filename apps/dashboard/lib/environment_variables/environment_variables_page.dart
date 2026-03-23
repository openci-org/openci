import 'package:dashboard/environment_variables/environment_variable_provider.dart';
import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class EnvironmentVariablesTab extends HookConsumerWidget {
  const EnvironmentVariablesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(environmentVariableManagerProvider);
    final envT = t.envVars;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            showDragHandle: true,
            context: context,
            isScrollControlled: true,
            builder: (context) => const _AddEnvVarBottomSheet(),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: state.when(
        data: (envVars) {
          final builtIn = envVars.where((e) => e.autoIncrement).toList();
          final custom = envVars.where((e) => !e.autoIncrement).toList();

          if (envVars.isEmpty) {
            return Center(
              child: Text(envT.noEnvVars),
            );
          }

          return ListView(
            children: [
              ...builtIn.map((envVar) => _BuiltInEnvVarTile(envVar: envVar)),
              if (custom.isEmpty && builtIn.isNotEmpty)
                Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(envT.noCustomEnvVars),
                  ),
                )
              else
                ...custom.map(
                  (envVar) => _CustomEnvVarTile(
                    envVar: envVar,
                    onDelete: () => _confirmDelete(context, ref, envVar),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: asyncErrorWidget,
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    EnvironmentVariable envVar,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.common.delete),
        content: Text('${t.common.delete} "${envVar.key}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await ref
                    .read(environmentVariableManagerProvider.notifier)
                    .deleteEnvironmentVariable(envVar.id);
                if (!context.mounted) return;
                Navigator.of(context).pop();
                context.showSnackBarMessage(t.envVars.deletedSuccess);
              } catch (e) {
                if (!context.mounted) return;
                context.showSnackBarMessage('$e');
              }
            },
            child: Text(t.common.delete),
          ),
        ],
      ),
    );
  }
}

class _BuiltInEnvVarTile extends StatelessWidget {
  const _BuiltInEnvVarTile({required this.envVar});

  final EnvironmentVariable envVar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Card(
          child: ListTile(
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    envVar.key,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Auto ++',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text(envVar.value),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                showModalBottomSheet(
                  showDragHandle: true,
                  context: context,
                  isScrollControlled: true,
                  builder: (context) =>
                      _EditBuiltInEnvVarBottomSheet(envVar: envVar),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomEnvVarTile extends StatelessWidget {
  const _CustomEnvVarTile({
    required this.envVar,
    required this.onDelete,
  });

  final EnvironmentVariable envVar;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Card(
          child: ListTile(
            title: Text(
              envVar.key,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              envVar.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
                          _EditEnvVarBottomSheet(envVar: envVar),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditBuiltInEnvVarBottomSheet extends HookConsumerWidget {
  const _EditBuiltInEnvVarBottomSheet({required this.envVar});

  final EnvironmentVariable envVar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final valueController = useTextEditingController(text: envVar.value);
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isLoading = useState(false);
    final envT = t.envVars;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.4,
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
                      envT.editRunNumber,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      enabled: false,
                      initialValue: envVar.key,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: envT.keyName,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: valueController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: envT.value,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return envT.enterValue;
                        }
                        if (int.tryParse(value) == null) {
                          return envT.valueMustBeNumber;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: isLoading.value
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              isLoading.value = true;
                              try {
                                await ref
                                    .read(
                                      environmentVariableManagerProvider
                                          .notifier,
                                    )
                                    .updateEnvironmentVariable(
                                      documentId: envVar.id,
                                      key: envVar.key,
                                      value: valueController.text,
                                    );
                                if (!context.mounted) return;
                                context.showSnackBarMessage(
                                  envT.runNumberUpdated,
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

class _AddEnvVarBottomSheet extends HookConsumerWidget {
  const _AddEnvVarBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyController = useTextEditingController();
    final valueController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final envT = t.envVars;

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
                      envT.addEnvVar,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: keyController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: envT.keyName,
                        hintText: envT.keyHint,
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return envT.enterKeyName;
                        }
                        if (!RegExp(
                          r'^[A-Za-z_][A-Za-z0-9_]*$',
                        ).hasMatch(value.trim())) {
                          return envT.invalidKey;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: valueController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: envT.value,
                        hintText: envT.valueHint,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return envT.enterValue;
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
                              .read(
                                environmentVariableManagerProvider.notifier,
                              )
                              .addEnvironmentVariable(
                                keyController.text.trim(),
                                valueController.text,
                              );
                          if (!context.mounted) return;
                          context.showSnackBarMessage(envT.addedSuccess);
                          Navigator.of(context).pop();
                        } catch (e) {
                          if (!context.mounted) return;
                          context.showSnackBarMessage('$e');
                        }
                      },
                      child: Text(t.common.add),
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

class _EditEnvVarBottomSheet extends HookConsumerWidget {
  const _EditEnvVarBottomSheet({required this.envVar});

  final EnvironmentVariable envVar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyController = useTextEditingController(text: envVar.key);
    final valueController = useTextEditingController(text: envVar.value);
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isLoading = useState(false);
    final envT = t.envVars;

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
                      envT.editEnvVar,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: keyController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: envT.keyName,
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return envT.enterKeyName;
                        }
                        if (!RegExp(
                          r'^[A-Za-z_][A-Za-z0-9_]*$',
                        ).hasMatch(value.trim())) {
                          return envT.invalidKey;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: valueController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: envT.value,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return envT.enterValue;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: isLoading.value
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              isLoading.value = true;
                              try {
                                await ref
                                    .read(
                                      environmentVariableManagerProvider
                                          .notifier,
                                    )
                                    .updateEnvironmentVariable(
                                      documentId: envVar.id,
                                      key: keyController.text.trim(),
                                      value: valueController.text,
                                    );
                                if (!context.mounted) return;
                                context.showSnackBarMessage(
                                  envT.updatedSuccess,
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
