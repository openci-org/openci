import 'dart:convert';

import 'package:dashboard/app_strings.dart';
import 'package:dashboard/secret_manager/secret_manager_provider.dart';
import 'package:dashboard/theme/app_colors.dart';
import 'package:dashboard/utilities/adaptive_modal.dart';
import 'package:dashboard/utilities/breakpoint.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

const _secretManagerContentMaxWidth = 540.0;

String _formatSecretUpdatedAt(DateTime value) {
  return DateFormat('yyyy/MM/dd HH:mm').format(value.toLocal());
}

class SecretManagerTab extends HookConsumerWidget {
  const SecretManagerTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final state = ref.watch(secretManagerProvider);
    final secretsT = t.secrets;
    final isDesktop =
        Breakpoint.fromWidth(MediaQuery.sizeOf(context).width) ==
        Breakpoint.desktop;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton(
              backgroundColor: colors.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              tooltip: secretsT.addSecret,
              onPressed: () => _showAddSecretSheet(context),
              child: const Icon(Icons.add),
            ),
      body: state.when(
        data: (secrets) {
          final hasCertKey = secrets.any(
            (s) => s.name == 'OPENCI_IOS_CERTIFICATE_PRIVATE_KEY',
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
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 88),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: _secretManagerContentMaxWidth,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.border),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: colors.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(
                                Icons.key_rounded,
                                size: 24,
                                color: colors.accent,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              secretsT.noSecrets,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                                letterSpacing: 0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 18),
                            FilledButton.icon(
                              onPressed: () => _showAddSecretSheet(context),
                              icon: const Icon(Icons.add_rounded),
                              label: Text(secretsT.addSecret),
                            ),
                          ],
                        ),
                      ),
                      ...setupCards,
                    ],
                  ),
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.only(top: 12, bottom: 80),
            children: [
              if (isDesktop)
                _SecretManagerDesktopAction(
                  onPressed: () => _showAddSecretSheet(context),
                ),
              // Setup cards
              ...setupCards.map(
                (card) => Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _secretManagerContentMaxWidth,
                    ),
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
              // Flat list of secrets
              ...secrets.map(
                (secret) => _SecretListTile(secret: secret),
              ),
            ],
          );
        },
        loading: () => const _SecretManagerLoadingState(),
        error: (error, stack) => Center(
          child: Text(
            t.common.error(error: error.toString()),
            style: TextStyle(color: colors.error),
          ),
        ),
      ),
    );
  }

  void _showAddSecretSheet(BuildContext context) {
    showAdaptiveFormModal(
      context: context,
      builder: (context) => const _AddSecretBottomSheet(),
    );
  }
}

class _SecretManagerDesktopAction extends StatelessWidget {
  const _SecretManagerDesktopAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final secretsT = t.secrets;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: _secretManagerContentMaxWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.add_rounded, size: 17),
                label: Text(secretsT.addSecret),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: colors.accentOnAccent,
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.only(left: 10, right: 12),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
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

class _SecretManagerLoadingState extends StatelessWidget {
  const _SecretManagerLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 24, bottom: 80),
      children: const [
        _SecretLoadingContent(
          message: 'シークレットを読み込み中',
          topPadding: 0,
        ),
      ],
    );
  }
}

class _SecretLoadingContent extends StatelessWidget {
  const _SecretLoadingContent({
    required this.message,
    required this.topPadding,
  });

  final String message;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: _secretManagerContentMaxWidth,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, topPadding, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SecretLoadingNotice(message: message),
              const SizedBox(height: 14),
              const _SecretLoadingSectionHeader(),
              const _SecretLoadingRow(widthFactor: 0.72),
              const _SecretLoadingRow(widthFactor: 0.58),
              const SizedBox(height: 12),
              const _SecretLoadingSectionHeader(widthFactor: 0.44),
              const _SecretLoadingRow(widthFactor: 0.64),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecretLoadingNotice extends StatelessWidget {
  const _SecretLoadingNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecretLoadingSectionHeader extends StatelessWidget {
  const _SecretLoadingSectionHeader({this.widthFactor = 0.52});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
      child: Row(
        children: [
          const _SecretLoadingBlock(
            width: 28,
            height: 28,
            borderRadius: BorderRadius.all(Radius.circular(7)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: widthFactor,
              child: const _SecretLoadingBlock(height: 12),
            ),
          ),
          const _SecretLoadingBlock(
            width: 26,
            height: 18,
            borderRadius: BorderRadius.all(Radius.circular(999)),
          ),
        ],
      ),
    );
  }
}

class _SecretLoadingRow extends StatelessWidget {
  const _SecretLoadingRow({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          children: [
            const _SecretLoadingBlock(
              width: 32,
              height: 32,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: widthFactor,
                child: const _SecretLoadingBlock(height: 12),
              ),
            ),
            const SizedBox(width: 12),
            const _SecretLoadingBlock(
              width: 32,
              height: 32,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecretLoadingBlock extends StatelessWidget {
  const _SecretLoadingBlock({
    this.width,
    required this.height,
    this.borderRadius,
  });

  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.shimmer,
        borderRadius: borderRadius ?? BorderRadius.circular(999),
      ),
    );
  }
}

class _SecretListTile extends ConsumerWidget {
  const _SecretListTile({
    required this.secret,
  });

  final Secret secret;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final secretsT = t.secrets;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: _secretManagerContentMaxWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors.border,
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
                      color: colors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.key_rounded,
                      size: 16,
                      color: colors.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                            color: colors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 7),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _SecretMetaChip(
                              icon: Icons.update_rounded,
                              label:
                                  '${secretsT.lastUpdated} ${_formatSecretUpdatedAt(secret.updatedAt)}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ActionIconButton(
                        icon: Icons.visibility_outlined,
                        color: colors.textTertiary,
                        tooltip: secretsT.viewSecretValue,
                        onPressed: () => _showSecretValueDialog(context, ref),
                      ),
                      const SizedBox(width: 4),
                      _ActionIconButton(
                        icon: Icons.edit_outlined,
                        color: colors.textTertiary,
                        tooltip: secretsT.editSecret,
                        onPressed: () {
                          showAdaptiveFormModal(
                            context: context,
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

  Future<void> _showSecretValueDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _SecretValueDialog(
        secret: secret,
        valueFuture: ref
            .read(secretManagerProvider.notifier)
            .readSecret(documentId: secret.id),
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
    } catch (e) {
      if (!context.mounted) return;
      context.showSnackBarMessage('$e');
    }
  }
}

class _SecretMetaChip extends StatelessWidget {
  const _SecretMetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final effectiveColor = colors.textTertiary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: effectiveColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: effectiveColor,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecretValueDialog extends StatelessWidget {
  const _SecretValueDialog({
    required this.secret,
    required this.valueFuture,
  });

  final Secret secret;
  final Future<String> valueFuture;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final secretsT = t.secrets;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Material(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: colors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        Icons.visibility_outlined,
                        size: 17,
                        color: colors.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            secretsT.secretValueTitle,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            secret.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textTertiary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: t.common.close,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.border),
              Flexible(
                child: FutureBuilder<String>(
                  future: valueFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.accent,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              secretsT.secretValueLoading,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          t.common.error(error: snapshot.error.toString()),
                          style: TextStyle(
                            color: colors.error,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                      );
                    }

                    final value = snapshot.data ?? '';

                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 280),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: colors.scaffold,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colors.border),
                              ),
                              child: SingleChildScrollView(
                                child: SelectableText(
                                  value,
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 12,
                                    height: 1.45,
                                    fontFamily: 'monospace',
                                    letterSpacing: 0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: TextButton.styleFrom(
                                  foregroundColor: colors.textSecondary,
                                  minimumSize: const Size(0, 40),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  textStyle: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(t.common.close),
                              ),
                              const Spacer(),
                              FilledButton.icon(
                                onPressed: () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: value),
                                  );
                                  if (!context.mounted) return;
                                  context.showSnackBarMessage(
                                    secretsT.copiedSecretValue,
                                  );
                                },
                                icon: const Icon(Icons.copy_rounded, size: 16),
                                label: Text(secretsT.copySecretValue),
                                style: FilledButton.styleFrom(
                                  backgroundColor: colors.accent,
                                  foregroundColor: colors.accentOnAccent,
                                  minimumSize: const Size(0, 40),
                                  padding: const EdgeInsets.only(
                                    left: 12,
                                    right: 14,
                                  ),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  textStyle: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

class _SecretFormFrame extends StatelessWidget {
  const _SecretFormFrame({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isSheet = usesBottomSheetFormModal(context);
    final maxHeight =
        MediaQuery.sizeOf(context).height * (isSheet ? 0.82 : 0.9);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Material(
            color: colors.surface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: colors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          Icons.key_rounded,
                          size: 17,
                          color: colors.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: t.common.cancel,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: colors.border),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
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
    final inputMode = useState(_InputMode.text);
    final selectedFileName = useState<String?>(null);
    final fileContent = useState<String?>(null);
    final isSubmitting = useState(false);

    return _SecretFormFrame(
      title: secretsT.addSecret,
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

            const SizedBox(height: 18),
            _SecretFormActionBar(
              isSubmitting: isSubmitting.value,
              submitLabel: secretsT.addSecret,
              submittingLabel: secretsT.adding,
              submitIcon: Icons.add_rounded,
              onCancel: () => Navigator.of(context).pop(),
              onSubmit: isSubmitting.value
                  ? null
                  : () async {
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

                      try {
                        isSubmitting.value = true;
                        await secretManager.addSecret(name, value);
                        if (!context.mounted) return;
                        showResponsiveSnackBar(
                          context,
                          content: Text(secretsT.addedSuccess),
                        );
                        Navigator.of(context).pop();
                      } catch (e) {
                        if (!context.mounted) return;
                        isSubmitting.value = false;
                        showResponsiveSnackBar(
                          context,
                          content: Text('$e'),
                        );
                      }
                    },
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _SecretFormActionBar extends StatelessWidget {
  const _SecretFormActionBar({
    required this.isSubmitting,
    required this.submitLabel,
    required this.submittingLabel,
    required this.submitIcon,
    required this.onCancel,
    required this.onSubmit,
  });

  final bool isSubmitting;
  final String submitLabel;
  final String submittingLabel;
  final IconData submitIcon;
  final VoidCallback onCancel;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.borderSubtle),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Row(
          children: [
            TextButton(
              onPressed: isSubmitting ? null : onCancel,
              style: TextButton.styleFrom(
                foregroundColor: colors.textSecondary,
                disabledForegroundColor: colors.textTertiary,
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(t.common.cancel),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: colors.accentOnAccent,
                  disabledBackgroundColor: colors.accent.withValues(
                    alpha: 0.48,
                  ),
                  disabledForegroundColor: colors.accentOnAccent.withValues(
                    alpha: 0.82,
                  ),
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: isSubmitting
                      ? Row(
                          key: const ValueKey('submitting'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.accentOnAccent,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                submittingLabel,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          key: const ValueKey('ready'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(submitIcon, size: 17),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                submitLabel,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
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

    return _SecretFormFrame(
      title: secretsT.editSecret,
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 4),
          ],
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

                          final match = RegExp(
                            r'AuthKey_([A-Z0-9]{10})\.p8$',
                            caseSensitive: false,
                          ).firstMatch(file.name);
                          if (match != null) {
                            keyIdController.text = match.group(1)!;
                          }
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
