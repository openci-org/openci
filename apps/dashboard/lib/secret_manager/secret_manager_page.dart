import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/secret_manager/secret_manager_provider.dart';
import 'package:dashboard/theme/app_colors.dart';
import 'package:dashboard/utilities/function_error_message.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:dashboard/workflow/list/workflow_file_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Extract secret names referenced in workflow YAML content.
Set<String> _extractSecretNames(String content) {
  final regex = RegExp(r'secrets\.([A-Za-z_][A-Za-z0-9_]*)');
  return regex.allMatches(content).map((m) => m.group(1)!).toSet();
}

/// Group secrets by workflow usage.
/// Returns a map: workflow name -> list of secrets used in that workflow.
/// Also returns an "unused" group for secrets not in any workflow.
({
  List<({String workflowName, List<Secret> secrets})> groups,
  List<Secret> unused,
})
_groupSecretsByWorkflow(
  List<Secret> secrets,
  List<WorkflowFile> workflowFiles,
) {
  // Build mapping: workflow name -> set of secret names
  final workflowSecrets = <String, Set<String>>{};
  for (final wf in workflowFiles) {
    workflowSecrets[wf.name] = _extractSecretNames(wf.content);
  }

  // Track which secrets are used in at least one workflow
  final usedSecretNames = <String>{};
  for (final names in workflowSecrets.values) {
    usedSecretNames.addAll(names);
  }

  // Build groups
  final groups = <({String workflowName, List<Secret> secrets})>[];
  for (final entry in workflowSecrets.entries) {
    final matchedSecrets = secrets
        .where((s) => entry.value.contains(s.name))
        .toList();
    if (matchedSecrets.isNotEmpty) {
      groups.add((workflowName: entry.key, secrets: matchedSecrets));
    }
  }

  // Sort groups by workflow name
  groups.sort((a, b) => a.workflowName.compareTo(b.workflowName));

  // Unused secrets
  final unused = secrets
      .where((s) => !usedSecretNames.contains(s.name))
      .toList();

  return (groups: groups, unused: unused);
}

class SecretManagerTab extends HookConsumerWidget {
  const SecretManagerTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final state = ref.watch(secretManagerProvider);
    final workflowFilesAsync = ref.watch(workflowFilesProvider);
    final secretsT = t.secrets;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: colors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        onPressed: () {
          showModalBottomSheet(
            showDragHandle: true,
            context: context,
            isScrollControlled: true,
            backgroundColor: colors.scaffold,
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
          final hasDeveloperIdCertificate = secrets.any(
            (s) => s.name == 'OPENCI_DEVELOPER_ID_CERTIFICATE_P12',
          );
          final setupCards = <Widget>[
            if (!hasCertKey) _GenerateCertificateKeyButton(),
            if (!hasAscApiKey) _SetupAscApiKeyButton(),
            if (!hasDeveloperIdCertificate) _SetupDeveloperIdCertificateCard(),
          ];

          if (secrets.isEmpty) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    children: [
                      // Empty state illustration
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: colors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.key_off_outlined,
                          size: 28,
                          color: colors.accent,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        secretsT.noSecrets,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Add secrets and API keys to use in your workflows',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textTertiary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ...setupCards,
                    ],
                  ),
                ),
              ),
            );
          }

          return workflowFilesAsync.when(
            loading: () => _SecretListSkeleton(setupCards: setupCards),
            error: (error, stack) => Center(
              child: Text(
                t.common.error(error: error.toString()),
                style: TextStyle(color: colors.error),
              ),
            ),
            data: (workflowFiles) {
              final grouped = _groupSecretsByWorkflow(secrets, workflowFiles);

              return ListView(
                padding: const EdgeInsets.only(top: 12, bottom: 80),
                children: [
                  // Setup cards
                  ...setupCards.map(
                    (card) => Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: card,
                        ),
                      ),
                    ),
                  ),
                  // Grouped sections
                  for (final group in grouped.groups) ...[
                    _SectionHeader(
                      icon: Icons.description_outlined,
                      title: group.workflowName,
                      count: group.secrets.length,
                    ),
                    ...group.secrets.map(
                      (secret) => _SecretListTile(secret: secret),
                    ),
                  ],
                  // Unused section
                  if (workflowFiles.isNotEmpty &&
                      grouped.unused.isNotEmpty) ...[
                    _SectionHeader(
                      icon: Icons.warning_amber_rounded,
                      title: secretsT.unusedSecrets,
                      count: grouped.unused.length,
                      isWarning: true,
                    ),
                    ...grouped.unused.map(
                      (secret) => _SecretListTile(
                        secret: secret,
                        isUnused: true,
                      ),
                    ),
                  ],
                  // If no workflows exist, show flat list without marking all as unused.
                  if (workflowFiles.isEmpty && grouped.groups.isEmpty) ...[
                    ...secrets.map(
                      (secret) => _SecretListTile(secret: secret),
                    ),
                  ],
                ],
              );
            },
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: colors.accent),
        ),
        error: (error, stack) => Center(
          child: Text(
            t.common.error(error: error.toString()),
            style: TextStyle(color: colors.error),
          ),
        ),
      ),
    );
  }
}

class _SecretListSkeleton extends StatelessWidget {
  const _SecretListSkeleton({required this.setupCards});

  final List<Widget> setupCards;

  static final _secrets = [
    Secret(
      id: 'skeleton-1',
      name: 'OPENCI_GITHUB_TOKEN',
      teamId: 'skeleton',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ),
    Secret(
      id: 'skeleton-2',
      name: 'OPENCI_ASC_KEY_ID',
      teamId: 'skeleton',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ),
    Secret(
      id: 'skeleton-3',
      name: 'REVENUE_CAT_API_KEY',
      teamId: 'skeleton',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 80),
        children: [
          ...setupCards.map(
            (card) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: card,
                ),
              ),
            ),
          ),
          const _SectionHeader(
            icon: Icons.description_outlined,
            title: 'flutter-ci-cd.yaml',
            count: 2,
          ),
          ..._secrets.take(2).map((secret) => _SecretListTile(secret: secret)),
          _SectionHeader(
            icon: Icons.warning_amber_rounded,
            title: t.secrets.unusedSecrets,
            count: 1,
            isWarning: true,
          ),
          _SecretListTile(secret: _secrets.last, isUnused: true),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
    this.isWarning = false,
  });

  final IconData icon;
  final String title;
  final int count;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final color = isWarning ? colors.warning : colors.accent;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecretListTile extends ConsumerWidget {
  const _SecretListTile({
    required this.secret,
    this.isUnused = false,
  });

  final Secret secret;
  final bool isUnused;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final secretsT = t.secrets;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isUnused
                    ? colors.warning.withValues(alpha: 0.2)
                    : colors.border,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              child: Row(
                children: [
                  // Key icon
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isUnused
                          ? colors.warning.withValues(alpha: 0.1)
                          : colors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.key_rounded,
                      size: 16,
                      color: isUnused ? colors.warning : colors.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name + subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          secret.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                            color: isUnused
                                ? colors.textTertiary
                                : colors.textPrimary,
                            decoration: isUnused
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isUnused) ...[
                          const SizedBox(height: 2),
                          Text(
                            secretsT.notUsedInWorkflows,
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.warning,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Actions
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ActionIconButton(
                        icon: Icons.edit_outlined,
                        color: colors.textTertiary,
                        tooltip: secretsT.editSecret,
                        onPressed: () {
                          showModalBottomSheet(
                            showDragHandle: true,
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: colors.scaffold,
                            builder: (context) =>
                                _EditSecretBottomSheet(secret: secret),
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      _ActionIconButton(
                        icon: Icons.delete_outline,
                        color: colors.error,
                        tooltip: t.common.delete,
                        onPressed: () => _confirmDelete(context, ref, secretsT),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    dynamic secretsT,
  ) async {
    final colors = AppColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          t.common.delete,
          style: TextStyle(color: colors.textPrimary),
        ),
        content: Text(
          secretsT.deleteConfirm,
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              t.common.cancel,
              style: TextStyle(color: colors.textTertiary),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
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
      context.showSnackBarMessage(secretsT.deletedSuccess);
    } on FirebaseFunctionsException catch (e, s) {
      final errorMessage = await FunctionErrorMessage.capture(
        e,
        stackTrace: s,
      );
      if (!context.mounted) return;
      context.showSnackBarMessage(errorMessage.message);
    } catch (e) {
      if (!context.mounted) return;
      context.showSnackBarMessage('$e');
    }
  }
}

/// Small icon button with hover effect for secret actions.
class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.icon,
    required this.color,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        icon: Icon(icon, size: 16, color: color),
        onPressed: onPressed,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        splashRadius: 16,
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

enum _InputMode { text, file }

class _AddSecretBottomSheet extends HookConsumerWidget {
  const _AddSecretBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final secretNameController = useTextEditingController();
    final secretValueController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final secretsT = t.secrets;
    final inputMode = useState(_InputMode.text);
    final selectedFileName = useState<String?>(null);
    final fileContent = useState<String?>(null);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.4,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title ──
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 20),
                    child: Text(
                      secretsT.addSecret,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.of(context).textPrimary,
                      ),
                    ),
                  ),

                  // ── Secret Name ──
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.of(context).surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.of(context).border,
                      ),
                    ),
                    child: TextFormField(
                      controller: secretNameController,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.of(context).textPrimary,
                        fontFamily: 'monospace',
                      ),
                      decoration: InputDecoration(
                        hintText: secretsT.secretName,
                        hintStyle: TextStyle(
                          color: AppColors.of(context).textTertiary,
                          fontSize: 14,
                          fontFamily: 'monospace',
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: InputBorder.none,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 8),
                          child: Icon(
                            Icons.key_outlined,
                            size: 18,
                            color: AppColors.of(context).textTertiary,
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 0,
                          minHeight: 0,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return secretsT.enterSecretName;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Input Mode Toggle ──
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.of(context).surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.of(context).border,
                      ),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ModeTab(
                            label: secretsT.inputModeText,
                            icon: Icons.text_fields,
                            isSelected: inputMode.value == _InputMode.text,
                            onTap: () {
                              inputMode.value = _InputMode.text;
                              selectedFileName.value = null;
                              fileContent.value = null;
                            },
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _ModeTab(
                            label: secretsT.inputModeFile,
                            icon: Icons.upload_file,
                            isSelected: inputMode.value == _InputMode.file,
                            onTap: () {
                              inputMode.value = _InputMode.file;
                              secretValueController.clear();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Value Input (Text Mode) ──
                  if (inputMode.value == _InputMode.text)
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.of(context).surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.of(context).border,
                        ),
                      ),
                      child: TextFormField(
                        controller: secretValueController,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.of(context).textPrimary,
                        ),
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: secretsT.secretValue,
                          hintStyle: TextStyle(
                            color: AppColors.of(context).textTertiary,
                            fontSize: 14,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: InputBorder.none,
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 12, right: 8),
                            child: Icon(
                              Icons.lock_outline,
                              size: 18,
                              color: AppColors.of(context).textTertiary,
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 0,
                            minHeight: 0,
                          ),
                        ),
                        validator: (value) {
                          if (inputMode.value == _InputMode.text &&
                              (value == null || value.isEmpty)) {
                            return secretsT.enterSecretValue;
                          }
                          return null;
                        },
                      ),
                    )
                  // ── File Upload (File Mode) ──
                  else
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final result = await FilePicker.pickFiles(
                          withData: true,
                        );
                        if (result != null && result.files.isNotEmpty) {
                          final file = result.files.first;
                          if (file.bytes != null) {
                            fileContent.value = utf8.decode(file.bytes!);
                            selectedFileName.value = file.name;
                          }
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 28,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.of(context).surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedFileName.value != null
                                ? AppColors.of(
                                    context,
                                  ).accent.withValues(alpha: 0.4)
                                : AppColors.of(context).border,
                            width: selectedFileName.value != null ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: selectedFileName.value != null
                                    ? const Color(
                                        0xFF3B82F6,
                                      ).withValues(alpha: 0.15)
                                    : AppColors.of(context).divider,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                selectedFileName.value != null
                                    ? Icons.check_rounded
                                    : Icons.cloud_upload_outlined,
                                size: 20,
                                color: selectedFileName.value != null
                                    ? AppColors.of(context).accent
                                    : AppColors.of(context).textTertiary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (selectedFileName.value != null) ...[
                              Text(
                                selectedFileName.value!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.of(context).textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF3B82F6,
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'file loaded',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.of(context).accent,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ] else ...[
                              Text(
                                secretsT.uploadFile,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.of(context).textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                secretsT.orUploadFile,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.of(context).textTertiary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // ── Submit Button ──
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.of(context).textPrimary,
                        backgroundColor: AppColors.of(context).accent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        if (inputMode.value == _InputMode.file &&
                            fileContent.value == null) {
                          context.showSnackBarMessage(
                            secretsT.enterValueOrUpload,
                          );
                          return;
                        }
                        if (!formKey.currentState!.validate()) return;

                        final name = secretNameController.text.trim();
                        final value = inputMode.value == _InputMode.file
                            ? fileContent.value!
                            : secretValueController.text;
                        final secretManager = ref.read(
                          secretManagerProvider.notifier,
                        );
                        final messenger = ScaffoldMessenger.of(context);

                        Navigator.of(context).pop();
                        messenger
                          ..removeCurrentSnackBar()
                          ..showSnackBar(
                            responsiveSnackBar(
                              messenger.context,
                              content: Text(secretsT.adding),
                              duration: const Duration(days: 1),
                            ),
                          );

                        try {
                          await secretManager.addSecret(name, value);
                          if (!messenger.mounted) return;
                          messenger
                            ..removeCurrentSnackBar()
                            ..showSnackBar(
                              responsiveSnackBar(
                                messenger.context,
                                content: Text(secretsT.addedSuccess),
                              ),
                            );
                        } on FirebaseFunctionsException catch (e, s) {
                          final errorMessage =
                              await FunctionErrorMessage.capture(
                                e,
                                stackTrace: s,
                              );
                          if (!messenger.mounted) return;
                          messenger
                            ..removeCurrentSnackBar()
                            ..showSnackBar(
                              responsiveSnackBar(
                                messenger.context,
                                content: Text(errorMessage.message),
                              ),
                            );
                        } catch (e) {
                          if (!messenger.mounted) return;
                          messenger
                            ..removeCurrentSnackBar()
                            ..showSnackBar(
                              responsiveSnackBar(
                                messenger.context,
                                content: Text('$e'),
                              ),
                            );
                        }
                      },
                      child: Text(
                        secretsT.addSecret,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A pill-shaped tab for the Text/File mode toggle.
class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.of(context).border : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? AppColors.of(context).textPrimary
                  : AppColors.of(context).textTertiary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppColors.of(context).textPrimary
                    : AppColors.of(context).textTertiary,
              ),
            ),
          ],
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
    final colors = AppColors.of(context);
    final nameController = useTextEditingController(text: secret.name);
    final valueController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isLoading = useState(false);
    final secretsT = t.secrets;
    final inputMode = useState(_InputMode.text);
    final selectedFileName = useState<String?>(null);
    final fileContent = useState<String?>(null);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.35,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title ──
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 20),
                    child: Text(
                      secretsT.editSecret,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),

                  // ── Secret Name ──
                  Container(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    child: TextFormField(
                      controller: nameController,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textPrimary,
                        fontFamily: 'monospace',
                      ),
                      decoration: InputDecoration(
                        hintText: secretsT.secretName,
                        hintStyle: TextStyle(
                          color: colors.textTertiary,
                          fontSize: 14,
                          fontFamily: 'monospace',
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: InputBorder.none,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 8),
                          child: Icon(
                            Icons.key_outlined,
                            size: 18,
                            color: colors.textTertiary,
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 0,
                          minHeight: 0,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return secretsT.enterSecretName;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Input Mode Toggle ──
                  Container(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.border),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ModeTab(
                            label: secretsT.inputModeText,
                            icon: Icons.text_fields,
                            isSelected: inputMode.value == _InputMode.text,
                            onTap: () {
                              inputMode.value = _InputMode.text;
                              selectedFileName.value = null;
                              fileContent.value = null;
                            },
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _ModeTab(
                            label: secretsT.inputModeFile,
                            icon: Icons.upload_file,
                            isSelected: inputMode.value == _InputMode.file,
                            onTap: () {
                              inputMode.value = _InputMode.file;
                              valueController.clear();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Value Input (Text Mode) ──
                  if (inputMode.value == _InputMode.text)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colors.border),
                          ),
                          child: TextFormField(
                            controller: valueController,
                            style: TextStyle(
                              fontSize: 14,
                              color: colors.textPrimary,
                            ),
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: secretsT.newSecretValue,
                              hintStyle: TextStyle(
                                color: colors.textTertiary,
                                fontSize: 14,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              border: InputBorder.none,
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(
                                  left: 12,
                                  right: 8,
                                ),
                                child: Icon(
                                  Icons.lock_outline,
                                  size: 18,
                                  color: colors.textTertiary,
                                ),
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 0,
                                minHeight: 0,
                              ),
                            ),
                          ),
                        ),
                        // ── Hint ──
                        Padding(
                          padding: const EdgeInsets.only(left: 4, top: 6),
                          child: Text(
                            'Leave value empty to keep current secret',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    )
                  // ── File Upload (File Mode) ──
                  else
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final result = await FilePicker.pickFiles(
                          withData: true,
                        );
                        if (result != null && result.files.isNotEmpty) {
                          final file = result.files.first;
                          if (file.bytes != null) {
                            fileContent.value = utf8.decode(file.bytes!);
                            selectedFileName.value = file.name;
                          }
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 28,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedFileName.value != null
                                ? colors.accent.withValues(alpha: 0.4)
                                : colors.border,
                            width: selectedFileName.value != null ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: selectedFileName.value != null
                                    ? const Color(
                                        0xFF3B82F6,
                                      ).withValues(alpha: 0.15)
                                    : colors.divider,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                selectedFileName.value != null
                                    ? Icons.check_rounded
                                    : Icons.cloud_upload_outlined,
                                size: 20,
                                color: selectedFileName.value != null
                                    ? colors.accent
                                    : colors.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (selectedFileName.value != null) ...[
                              Text(
                                selectedFileName.value!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF3B82F6,
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'file loaded',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: colors.accent,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ] else ...[
                              Text(
                                secretsT.uploadFile,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                secretsT.orUploadFile,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colors.textTertiary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // ── Submit Button ──
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: colors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: isLoading.value
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              final name = nameController.text.trim();

                              String? value;
                              if (inputMode.value == _InputMode.file) {
                                value = fileContent.value;
                              } else if (valueController.text.isNotEmpty) {
                                value = valueController.text;
                              }

                              isLoading.value = true;
                              try {
                                await ref
                                    .read(secretManagerProvider.notifier)
                                    .updateSecret(
                                      documentId: secret.id,
                                      name: name,
                                      value: value,
                                    );
                                if (!context.mounted) return;
                                context.showSnackBarMessage(
                                  secretsT.updatedSuccess,
                                );
                                Navigator.of(context).pop();
                              } on FirebaseFunctionsException catch (e, s) {
                                final errorMessage =
                                    await FunctionErrorMessage.capture(
                                      e,
                                      stackTrace: s,
                                    );
                                isLoading.value = false;
                                if (!context.mounted) return;
                                context.showSnackBarMessage(
                                  errorMessage.message,
                                );
                              } catch (e) {
                                isLoading.value = false;
                                if (!context.mounted) return;
                                context.showSnackBarMessage('$e');
                              }
                            },
                      child: isLoading.value
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              t.common.save,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
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
    final colors = AppColors.of(context);
    final isLoading = useState(false);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.key,
                    size: 16,
                    color: colors.accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'iOS Code Signing',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Generate a certificate private key for iOS builds. This is required for automatic code signing.',
              style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: colors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
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
                        } on FirebaseFunctionsException catch (e, s) {
                          final errorMessage =
                              await FunctionErrorMessage.capture(
                                e,
                                stackTrace: s,
                              );
                          if (!context.mounted) return;
                          context.showSnackBarMessage(errorMessage.message);
                        } catch (e) {
                          if (!context.mounted) return;
                          context.showSnackBarMessage('$e');
                        } finally {
                          if (context.mounted) isLoading.value = false;
                        }
                      },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isLoading.value)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else ...[
                      const Icon(Icons.vpn_key, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Generate Certificate Key',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupDeveloperIdCertificateCard extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final isExpanded = useState(false);
    final isGeneratingCsr = useState(false);
    final isSavingCertificate = useState(false);
    final csrPem = useState<String?>(null);
    final certificateFileName = useState<String?>(null);
    final certificateBase64 = useState<String?>(null);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => isExpanded.value = !isExpanded.value,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF58A6FF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.desktop_mac_outlined,
                      size: 16,
                      color: Color(0xFF58A6FF),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'macOS Developer ID 証明書',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD29922).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      '設定が必要',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD29922),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded.value ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      size: 20,
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '直接ダウンロード配布する macOS アプリの署名と公証に必要です。Developer ID 証明書は Apple Developer Portal で Account Holder が発行します。',
              style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
            if (isExpanded.value) ...[
              const SizedBox(height: 16),
              _DeveloperIdSetupStep(
                number: 1,
                title: 'OpenCI で CSR を生成',
                description: 'OpenCI が秘密鍵を保持し、Apple に提出する証明書署名要求（CSR）を生成します。',
                actionLabel: isGeneratingCsr.value ? '生成中...' : 'CSR を生成',
                icon: Icons.description_outlined,
                isComplete: csrPem.value != null,
                onPressed: isGeneratingCsr.value
                    ? null
                    : () async {
                        isGeneratingCsr.value = true;
                        try {
                          final csr = await ref
                              .read(secretManagerProvider.notifier)
                              .generateDeveloperIdCsr();
                          csrPem.value = csr;
                          if (!context.mounted) return;
                          context.showSnackBarMessage('CSR を生成しました');
                        } on FirebaseFunctionsException catch (e, s) {
                          final errorMessage =
                              await FunctionErrorMessage.capture(
                                e,
                                stackTrace: s,
                              );
                          if (!context.mounted) return;
                          context.showSnackBarMessage(errorMessage.message);
                        } catch (e) {
                          if (!context.mounted) return;
                          context.showSnackBarMessage('$e');
                        } finally {
                          if (context.mounted) isGeneratingCsr.value = false;
                        }
                      },
              ),
              if (csrPem.value != null) ...[
                const SizedBox(height: 10),
                _DeveloperIdCsrPreview(csrPem: csrPem.value!),
              ],
              const SizedBox(height: 10),
              _DeveloperIdSetupStep(
                number: 2,
                title: 'Developer ID Application 証明書を作成',
                description:
                    'Apple Developer Portal の Certificates 画面で「Developer ID Application」を選び、OpenCI で生成した CSR をアップロードします。',
                icon: Icons.open_in_new_rounded,
              ),
              const SizedBox(height: 10),
              const _DeveloperIdPortalGuide(),
              const SizedBox(height: 10),
              _DeveloperIdSetupStep(
                number: 3,
                title: '発行された証明書をアップロード',
                description:
                    'OpenCI が .cer と保存済みの秘密鍵を組み合わせ、CI で署名に使うシークレットを準備します。',
                actionLabel:
                    certificateFileName.value ?? 'Developer ID .cer をアップロード',
                icon: certificateFileName.value == null
                    ? Icons.upload_file
                    : Icons.check_circle,
                isComplete: certificateFileName.value != null,
                onPressed: () async {
                  final result = await FilePicker.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['cer', 'crt'],
                    withData: true,
                  );
                  if (result == null || result.files.isEmpty) return;
                  final file = result.files.first;
                  final bytes = file.bytes;
                  if (bytes == null || bytes.isEmpty) {
                    if (!context.mounted) return;
                    context.showSnackBarMessage('証明書ファイルを読み込めませんでした');
                    return;
                  }
                  certificateFileName.value = file.name;
                  certificateBase64.value = base64Encode(bytes);
                },
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceTertiary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: colors.textTertiary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '証明書を登録したあとは、CI で Xcode アカウントにサインインする必要はありません。Apple が App Store Connect API 経由で Developer ID 証明書を発行していないため、Portal での手続きだけが必要です。',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: certificateFileName.value == null
                        ? colors.textTertiary.withValues(alpha: 0.35)
                        : colors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: certificateFileName.value == null
                      ? null
                      : isSavingCertificate.value
                      ? null
                      : () async {
                          final encodedCertificate = certificateBase64.value;
                          if (encodedCertificate == null) {
                            context.showSnackBarMessage(
                              '証明書ファイルを選択してください',
                            );
                            return;
                          }
                          isSavingCertificate.value = true;
                          try {
                            await ref
                                .read(secretManagerProvider.notifier)
                                .registerDeveloperIdCertificate(
                                  certificateBase64: encodedCertificate,
                                );
                            ref.invalidate(secretManagerProvider);
                            if (!context.mounted) return;
                            context.showSnackBarMessage(
                              'Developer ID 証明書を保存しました',
                            );
                          } on FirebaseFunctionsException catch (e, s) {
                            final errorMessage =
                                await FunctionErrorMessage.capture(
                                  e,
                                  stackTrace: s,
                                );
                            if (!context.mounted) return;
                            context.showSnackBarMessage(errorMessage.message);
                          } catch (e) {
                            if (!context.mounted) return;
                            context.showSnackBarMessage('$e');
                          } finally {
                            if (context.mounted) {
                              isSavingCertificate.value = false;
                            }
                          }
                        },
                  child: isSavingCertificate.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Developer ID 証明書を保存',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DeveloperIdCsrPreview extends StatelessWidget {
  const _DeveloperIdCsrPreview({required this.csrPem});

  final String csrPem;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceTertiary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Apple Developer Portal に貼り付ける CSR',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: csrPem));
                  if (!context.mounted) return;
                  context.showSnackBarMessage('CSR をコピーしました');
                },
                icon: const Icon(Icons.copy, size: 14),
                label: const Text('コピー'),
              ),
              TextButton.icon(
                onPressed: () async {
                  try {
                    final path = await FilePicker.saveFile(
                      dialogTitle: 'CSR を保存',
                      fileName: 'openci-developer-id.certSigningRequest',
                      type: FileType.custom,
                      allowedExtensions: ['certSigningRequest'],
                      bytes: Uint8List.fromList(utf8.encode(csrPem)),
                    );
                    if (!context.mounted || path == null) return;
                    context.showSnackBarMessage('CSR ファイルを保存しました');
                  } on PlatformException catch (error) {
                    await Clipboard.setData(ClipboardData(text: csrPem));
                    if (!context.mounted) return;
                    context.showSnackBarMessage(
                      '保存できませんでした。CSR をコピーしました: ${error.code}',
                    );
                  }
                },
                icon: const Icon(Icons.download_rounded, size: 14),
                label: const Text('保存'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 160),
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                csrPem,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  color: colors.textSecondary,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeveloperIdPortalGuide extends StatelessWidget {
  const _DeveloperIdPortalGuide();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    const steps = [
      'Apple Developer Portal に Account Holder でログインします。',
      'Certificates, Identifiers & Profiles > Certificates を開き、追加（+）を押します。',
      'Software の中から Developer ID Application を選び、Continue します。',
      'OpenCI の「保存」ボタンで CSR を .certSigningRequest ファイルとして保存し、そのファイルをアップロードします。',
      '発行された Developer ID Application 証明書（.cer）をダウンロードします。',
      'ダウンロードした .cer を、この画面の「Developer ID .cer をアップロード」から登録します。',
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceTertiary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.open_in_new_rounded,
                size: 16,
                color: colors.textTertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Apple Developer Portal での操作',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final (index, step) in steps.indexed) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${index + 1}.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.textTertiary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    step,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            if (index != steps.length - 1) const SizedBox(height: 6),
          ],
          const SizedBox(height: 10),
          Text(
            '※ Apple Portal では CSR のファイルアップロードが必要です。OpenCI の「保存」ボタンで作った .certSigningRequest ファイルを選択してください。',
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeveloperIdSetupStep extends StatelessWidget {
  const _DeveloperIdSetupStep({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    this.actionLabel,
    this.onPressed,
    this.isComplete = false,
  });

  final int number;
  final String title;
  final String description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onPressed;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final accent = isComplete ? const Color(0xFF3FB950) : colors.accent;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceTertiary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
                if (actionLabel != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: accent,
                        backgroundColor: accent.withValues(alpha: 0.08),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: onPressed,
                      icon: Icon(icon, size: 15),
                      label: Text(
                        actionLabel!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupAscApiKeyButton extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final isLoading = useState(false);
    final isExpanded = useState(false);
    final issuerIdController = useTextEditingController();
    final keyIdController = useTextEditingController();
    final privateKeyContent = useState<String?>(null);
    final p8FileName = useState<String?>(null);
    final formKey = useMemoized(() => GlobalKey<FormState>());

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => isExpanded.value = !isExpanded.value,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.apple,
                      size: 16,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'App Store Connect API Key',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded.value ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      size: 20,
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Required for iOS code signing and TestFlight deployment.',
              style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
            if (isExpanded.value) ...[
              const SizedBox(height: 16),
              Form(
                key: formKey,
                child: Column(
                  children: [
                    // Issuer ID
                    Container(
                      decoration: BoxDecoration(
                        color: colors.surfaceTertiary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.border),
                      ),
                      child: TextFormField(
                        controller: issuerIdController,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textPrimary,
                          fontFamily: 'monospace',
                        ),
                        decoration: InputDecoration(
                          hintText: 'Issuer ID (e.g. 69a6d…)',
                          hintStyle: TextStyle(
                            color: colors.textTertiary,
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: InputBorder.none,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter Issuer ID';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Key ID
                    Container(
                      decoration: BoxDecoration(
                        color: colors.surfaceTertiary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.border),
                      ),
                      child: TextFormField(
                        controller: keyIdController,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textPrimary,
                          fontFamily: 'monospace',
                        ),
                        decoration: InputDecoration(
                          hintText: 'Key ID (e.g. ABC123DEFG)',
                          hintStyle: TextStyle(
                            color: colors.textTertiary,
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: InputBorder.none,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter Key ID';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    // .p8 file upload
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: p8FileName.value != null
                              ? Colors.green
                              : colors.textSecondary,
                          backgroundColor: p8FileName.value != null
                              ? Colors.green.withValues(alpha: 0.08)
                              : colors.surfaceTertiary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: p8FileName.value != null
                                  ? Colors.green.withValues(alpha: 0.3)
                                  : colors.border,
                            ),
                          ),
                        ),
                        onPressed: () async {
                          final result = await FilePicker.pickFiles(
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              p8FileName.value != null
                                  ? Icons.check_circle
                                  : Icons.upload_file,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              p8FileName.value ?? 'Upload .p8 file',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (privateKeyContent.value == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 4),
                        child: Text(
                          'Download the .p8 file from App Store Connect',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textTertiary,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: colors.accent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
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
                                        issuerId: issuerIdController.text
                                            .trim(),
                                        keyId: keyIdController.text.trim(),
                                        privateKey: privateKeyContent.value!,
                                      );
                                  if (!context.mounted) return;
                                  context.showSnackBarMessage(
                                    'ASC API Key configured successfully',
                                  );
                                } on FirebaseFunctionsException catch (e, s) {
                                  final errorMessage =
                                      await FunctionErrorMessage.capture(
                                        e,
                                        stackTrace: s,
                                      );
                                  if (!context.mounted) return;
                                  context.showSnackBarMessage(
                                    errorMessage.message,
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  context.showSnackBarMessage('$e');
                                } finally {
                                  if (context.mounted) isLoading.value = false;
                                }
                              },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isLoading.value)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            else ...[
                              const Icon(Icons.save, size: 16),
                              const SizedBox(width: 8),
                              const Text(
                                'Save API Key',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
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
