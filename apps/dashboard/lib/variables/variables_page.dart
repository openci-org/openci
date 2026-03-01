import 'package:dashboard/environment_variables/environment_variable_provider.dart';
import 'package:dashboard/secret_manager/secret_manager_provider.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class VariablesPage extends HookWidget {
  const VariablesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tabController = useTabController(initialLength: 2);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.12),
                    colorScheme.surfaceContainerHighest,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  Icons.vpn_key_outlined,
                  size: 16,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Variables',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 15),
                  SizedBox(width: 6),
                  Text('Secrets'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune, size: 15),
                  SizedBox(width: 6),
                  Text('Environment'),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _VariablesFAB(tabController: tabController),
      body: TabBarView(
        controller: tabController,
        children: const [
          _SecretsTab(),
          _EnvVarsTab(),
        ],
      ),
    );
  }
}

class _VariablesFAB extends HookWidget {
  const _VariablesFAB({required this.tabController});
  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    final tabIndex = useState(0);

    useEffect(() {
      void listener() => tabIndex.value = tabController.index;
      tabController.addListener(listener);
      return () => tabController.removeListener(listener);
    }, [tabController]);

    return FloatingActionButton(
      onPressed: () {
        if (tabIndex.value == 0) {
          showModalBottomSheet(
            showDragHandle: true,
            context: context,
            isScrollControlled: true,
            builder: (_) => const _AddSecretSheet(),
          );
        } else {
          showModalBottomSheet(
            showDragHandle: true,
            context: context,
            isScrollControlled: true,
            builder: (_) => const _AddEnvVarSheet(),
          );
        }
      },
      child: const Icon(Icons.add),
    );
  }
}

class _SecretsTab extends ConsumerWidget {
  const _SecretsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(secretManagerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return state.when(
      data: (secrets) {
        if (secrets.isEmpty) {
          return _EmptyState(
            icon: Icons.lock_outline,
            title: 'No secrets yet',
            subtitle:
                'Add encrypted secrets like API keys,\ntokens, and certificates.',
            onAdd: () => showModalBottomSheet(
              showDragHandle: true,
              context: context,
              isScrollControlled: true,
              builder: (_) => const _AddSecretSheet(),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: secrets.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final secret = secrets[index];
            return _VariableCard(
              name: secret.name,
              isSecret: true,
              onTap: () => showModalBottomSheet(
                showDragHandle: true,
                context: context,
                isScrollControlled: true,
                builder: (_) => _EditSecretSheet(secret: secret),
              ),
              trailing: Icon(
                Icons.visibility_off_outlined,
                size: 16,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: asyncErrorWidget,
    );
  }
}

class _EnvVarsTab extends ConsumerWidget {
  const _EnvVarsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(environmentVariableManagerProvider);

    return state.when(
      data: (envVars) {
        if (envVars.isEmpty) {
          return _EmptyState(
            icon: Icons.tune,
            title: 'No environment variables',
            subtitle:
                'Add variables that will be available\nduring your CI/CD builds.',
            onAdd: () => showModalBottomSheet(
              showDragHandle: true,
              context: context,
              isScrollControlled: true,
              builder: (_) => const _AddEnvVarSheet(),
            ),
          );
        }

        final builtIn = envVars.where((e) => e.autoIncrement).toList();
        final custom = envVars.where((e) => !e.autoIncrement).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final envVar in builtIn) ...[
              _VariableCard(
                name: envVar.key,
                value: envVar.value,
                badge: 'auto ++',
                onTap: () => showModalBottomSheet(
                  showDragHandle: true,
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => _EditBuiltInEnvVarSheet(envVar: envVar),
                ),
              ),
              const SizedBox(height: 8),
            ],
            for (int i = 0; i < custom.length; i++) ...[
              _VariableCard(
                name: custom[i].key,
                value: custom[i].value,
                onTap: () => showModalBottomSheet(
                  showDragHandle: true,
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => _EditEnvVarSheet(envVar: custom[i]),
                ),
                onDelete: () => _confirmDelete(context, ref, custom[i]),
              ),
              if (i < custom.length - 1) const SizedBox(height: 8),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: asyncErrorWidget,
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
        title: const Text('Delete Variable'),
        content: Text('Delete "${envVar.key}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await ref
                    .read(environmentVariableManagerProvider.notifier)
                    .deleteEnvironmentVariable(envVar.id);
                if (!context.mounted) return;
                Navigator.of(context).pop();
                context.showSnackBarMessage('Deleted successfully');
              } catch (e) {
                if (!context.mounted) return;
                context.showSnackBarMessage('$e');
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _VariableCard extends StatelessWidget {
  const _VariableCard({
    required this.name,
    this.value,
    this.badge,
    this.isSecret = false,
    this.trailing,
    required this.onTap,
    this.onDelete,
  });

  final String name;
  final String? value;
  final String? badge;
  final bool isSecret;
  final Widget? trailing;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSecret
                      ? Colors.amber.withValues(alpha: 0.12)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    isSecret ? Icons.lock : Icons.code,
                    size: 15,
                    color: isSecret
                        ? Colors.amber.shade700
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badge!,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (value != null && !isSecret) ...[
                      const SizedBox(height: 2),
                      Text(
                        value!,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (isSecret) ...[
                      const SizedBox(height: 2),
                      Text(
                        '••••••••',
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 2,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
              if (onDelete != null)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: colorScheme.error.withValues(alpha: 0.5),
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onAdd,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    colorScheme.primaryContainer.withValues(alpha: 0.5),
                    colorScheme.primaryContainer.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: colorScheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddSecretSheet extends HookConsumerWidget {
  const _AddSecretSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final valueController = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.lock,
                      size: 15,
                      color: Colors.amber.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Add Secret',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'SECRET_NAME',
                  hintText: 'e.g. API_KEY',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                textCapitalization: TextCapitalization.characters,
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
                decoration: InputDecoration(
                  labelText: 'Secret Value',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a secret value';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 13,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Secrets are encrypted and never exposed in logs.',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  try {
                    await ref
                        .read(secretManagerProvider.notifier)
                        .addSecret(
                          nameController.text.trim(),
                          valueController.text,
                        );
                    if (!context.mounted) return;
                    context.showSnackBarMessage('Secret added');
                    Navigator.of(context).pop();
                  } catch (e) {
                    if (!context.mounted) return;
                    context.showSnackBarMessage('$e');
                  }
                },
                icon: const Icon(Icons.check),
                label: const Text('Add Secret'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditSecretSheet extends HookConsumerWidget {
  const _EditSecretSheet({required this.secret});
  final Secret secret;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController(text: secret.name);
    final valueController = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final isLoading = useState(false);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.lock,
                      size: 15,
                      color: Colors.amber.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Edit Secret',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'SECRET_NAME',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
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
                decoration: InputDecoration(
                  labelText: 'New Value (leave empty to keep current)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isLoading.value
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        isLoading.value = true;
                        try {
                          await ref
                              .read(secretManagerProvider.notifier)
                              .updateSecret(
                                documentId: secret.id,
                                name: nameController.text.trim(),
                                value: valueController.text.isNotEmpty
                                    ? valueController.text
                                    : null,
                              );
                          if (!context.mounted) return;
                          context.showSnackBarMessage('Secret updated');
                          Navigator.of(context).pop();
                        } catch (e) {
                          isLoading.value = false;
                          if (!context.mounted) return;
                          context.showSnackBarMessage('$e');
                        }
                      },
                icon: isLoading.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: const Text('Save Changes'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddEnvVarSheet extends HookConsumerWidget {
  const _AddEnvVarSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyController = useTextEditingController();
    final valueController = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.code,
                      size: 15,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Add Variable',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: keyController,
                decoration: InputDecoration(
                  labelText: 'KEY_NAME',
                  hintText: 'e.g. MY_VARIABLE',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a key name';
                  }
                  if (!RegExp(
                    r'^[A-Za-z_][A-Za-z0-9_]*$',
                  ).hasMatch(value.trim())) {
                    return 'Use only letters, numbers, and underscores';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: valueController,
                decoration: InputDecoration(
                  labelText: 'Value',
                  hintText: 'e.g. hello',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a value';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  try {
                    await ref
                        .read(environmentVariableManagerProvider.notifier)
                        .addEnvironmentVariable(
                          keyController.text.trim(),
                          valueController.text,
                        );
                    if (!context.mounted) return;
                    context.showSnackBarMessage('Variable added');
                    Navigator.of(context).pop();
                  } catch (e) {
                    if (!context.mounted) return;
                    context.showSnackBarMessage('$e');
                  }
                },
                icon: const Icon(Icons.check),
                label: const Text('Add Variable'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditEnvVarSheet extends HookConsumerWidget {
  const _EditEnvVarSheet({required this.envVar});
  final EnvironmentVariable envVar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyController = useTextEditingController(text: envVar.key);
    final valueController = useTextEditingController(text: envVar.value);
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final isLoading = useState(false);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.code,
                      size: 15,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Edit Variable',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: keyController,
                decoration: InputDecoration(
                  labelText: 'KEY_NAME',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a key name';
                  }
                  if (!RegExp(
                    r'^[A-Za-z_][A-Za-z0-9_]*$',
                  ).hasMatch(value.trim())) {
                    return 'Use only letters, numbers, and underscores';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: valueController,
                decoration: InputDecoration(
                  labelText: 'Value',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a value';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isLoading.value
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        isLoading.value = true;
                        try {
                          await ref
                              .read(
                                environmentVariableManagerProvider.notifier,
                              )
                              .updateEnvironmentVariable(
                                documentId: envVar.id,
                                key: keyController.text.trim(),
                                value: valueController.text,
                              );
                          if (!context.mounted) return;
                          context.showSnackBarMessage('Variable updated');
                          Navigator.of(context).pop();
                        } catch (e) {
                          isLoading.value = false;
                          if (!context.mounted) return;
                          context.showSnackBarMessage('$e');
                        }
                      },
                icon: isLoading.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: const Text('Save Changes'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditBuiltInEnvVarSheet extends HookConsumerWidget {
  const _EditBuiltInEnvVarSheet({required this.envVar});
  final EnvironmentVariable envVar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final valueController = useTextEditingController(text: envVar.value);
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final isLoading = useState(false);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.tag,
                      size: 15,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Edit Run Number',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                enabled: false,
                initialValue: envVar.key,
                decoration: InputDecoration(
                  labelText: 'KEY_NAME',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: valueController,
                decoration: InputDecoration(
                  labelText: 'Value',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a value';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Value must be a number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isLoading.value
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        isLoading.value = true;
                        try {
                          await ref
                              .read(
                                environmentVariableManagerProvider.notifier,
                              )
                              .updateEnvironmentVariable(
                                documentId: envVar.id,
                                key: envVar.key,
                                value: valueController.text,
                              );
                          if (!context.mounted) return;
                          context.showSnackBarMessage('Run number updated');
                          Navigator.of(context).pop();
                        } catch (e) {
                          isLoading.value = false;
                          if (!context.mounted) return;
                          context.showSnackBarMessage('$e');
                        }
                      },
                icon: isLoading.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: const Text('Save'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
