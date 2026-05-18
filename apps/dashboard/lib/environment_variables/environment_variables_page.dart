import 'package:dashboard/environment_variables/environment_variable_provider.dart';
import 'package:dashboard/app_strings.dart';
import 'package:dashboard/theme/app_colors.dart';
import 'package:dashboard/utilities/adaptive_modal.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _environmentVariablesContentMaxWidth = 540.0;

class EnvironmentVariablesTab extends HookConsumerWidget {
  const EnvironmentVariablesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final state = ref.watch(environmentVariableManagerProvider);
    final envT = t.envVars;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: colors.accent,
        foregroundColor: colors.accentOnAccent,
        elevation: 0,
        tooltip: envT.addEnvVar,
        onPressed: () => _showAddEnvVarSheet(context),
        child: const Icon(Icons.add),
      ),
      body: state.when(
        data: (envVars) {
          final builtIn = envVars.where((e) => e.autoIncrement).toList();
          final custom = envVars.where((e) => !e.autoIncrement).toList();

          if (envVars.isEmpty) {
            return _EnvironmentVariablesEmptyState(
              onAdd: () => _showAddEnvVarSheet(context),
            );
          }

          return Scrollbar(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _environmentVariablesContentMaxWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (builtIn.isNotEmpty)
                          _EnvironmentSection(
                            icon: Icons.numbers_rounded,
                            title: '自動変数',
                            count: builtIn.length,
                            children: [
                              for (final envVar in builtIn)
                                _BuiltInEnvVarTile(envVar: envVar),
                            ],
                          ),
                        _EnvironmentSection(
                          icon: Icons.tune_rounded,
                          title: 'カスタム変数',
                          count: custom.length,
                          children: custom.isEmpty
                              ? [
                                  _EnvironmentInlineEmptyState(
                                    message: envT.noCustomEnvVars,
                                  ),
                                ]
                              : [
                                  for (final envVar in custom)
                                    _CustomEnvVarTile(
                                      envVar: envVar,
                                      onDelete: () =>
                                          _confirmDeleteEnvironmentVariable(
                                            context,
                                            ref,
                                            envVar,
                                          ),
                                    ),
                                ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const _EnvironmentVariablesLoadingState(),
        error: asyncErrorWidget,
      ),
    );
  }
}

class EnvironmentVariablesInlineSection extends HookConsumerWidget {
  const EnvironmentVariablesInlineSection({super.key, this.topPadding = 28});

  final double topPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(environmentVariableManagerProvider);
    final envT = t.envVars;

    return state.when(
      data: (envVars) {
        final builtIn = envVars.where((e) => e.autoIncrement).toList();
        final custom = envVars.where((e) => !e.autoIncrement).toList();

        return _EnvironmentInlineShell(
          topPadding: topPadding,
          count: envVars.length,
          onAdd: () => _showAddEnvVarSheet(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (envVars.isEmpty)
                _EnvironmentInlineEmptyState(message: envT.noEnvVars)
              else ...[
                if (builtIn.isNotEmpty)
                  _EnvironmentSection(
                    icon: Icons.numbers_rounded,
                    title: '自動変数',
                    count: builtIn.length,
                    children: [
                      for (final envVar in builtIn)
                        _BuiltInEnvVarTile(envVar: envVar),
                    ],
                  ),
                if (custom.isNotEmpty)
                  _EnvironmentSection(
                    icon: Icons.tune_rounded,
                    title: 'カスタム変数',
                    count: custom.length,
                    children: [
                      for (final envVar in custom)
                        _CustomEnvVarTile(
                          envVar: envVar,
                          onDelete: () => _confirmDeleteEnvironmentVariable(
                            context,
                            ref,
                            envVar,
                          ),
                        ),
                    ],
                  )
                else if (builtIn.isEmpty)
                  _EnvironmentInlineEmptyState(message: envT.noCustomEnvVars),
              ],
            ],
          ),
        );
      },
      loading: () => _EnvironmentInlineShell(
        topPadding: topPadding,
        count: null,
        onAdd: () => _showAddEnvVarSheet(context),
        child: const _EnvironmentVariablesInlineLoadingState(),
      ),
      error: (error, stack) => _EnvironmentInlineShell(
        topPadding: topPadding,
        count: null,
        onAdd: () => _showAddEnvVarSheet(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            t.common.error(error: error.toString()),
            style: TextStyle(color: AppColors.of(context).error),
          ),
        ),
      ),
    );
  }
}

void _showAddEnvVarSheet(BuildContext context) {
  showAdaptiveFormModal(
    context: context,
    builder: (context) => const _AddEnvVarBottomSheet(),
  );
}

void _confirmDeleteEnvironmentVariable(
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

class _EnvironmentInlineShell extends StatelessWidget {
  const _EnvironmentInlineShell({
    required this.topPadding,
    required this.count,
    required this.onAdd,
    required this.child,
  });

  final double topPadding;
  final int? count;
  final VoidCallback onAdd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final envT = t.envVars;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: _environmentVariablesContentMaxWidth,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, topPadding, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: colors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      size: 15,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      envT.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  if (count != null) ...[
                    Container(
                      constraints: const BoxConstraints(minWidth: 26),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: colors.border),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: colors.textTertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  TextButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(envT.addEnvVar),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _EnvironmentVariablesEmptyState extends StatelessWidget {
  const _EnvironmentVariablesEmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final envT = t.envVars;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 88),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    color: colors.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  envT.noEnvVars,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(envT.addEnvVar),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EnvironmentVariablesLoadingState extends StatelessWidget {
  const _EnvironmentVariablesLoadingState();

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 88),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: _environmentVariablesContentMaxWidth,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _EnvironmentLoadingNotice(message: '環境変数を読み込み中'),
                  SizedBox(height: 14),
                  _EnvironmentLoadingRow(widthFactor: 0.72),
                  _EnvironmentLoadingRow(widthFactor: 0.58),
                  _EnvironmentLoadingRow(widthFactor: 0.66),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnvironmentVariablesInlineLoadingState extends StatelessWidget {
  const _EnvironmentVariablesInlineLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EnvironmentLoadingNotice(message: '環境変数を読み込み中'),
        SizedBox(height: 10),
        _EnvironmentLoadingRow(widthFactor: 0.62),
        _EnvironmentLoadingRow(widthFactor: 0.48),
      ],
    );
  }
}

class _EnvironmentLoadingNotice extends StatelessWidget {
  const _EnvironmentLoadingNotice({required this.message});

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

class _EnvironmentLoadingRow extends StatelessWidget {
  const _EnvironmentLoadingRow({required this.widthFactor});

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
            _LoadingBlock(
              width: 34,
              height: 34,
              borderRadius: BorderRadius.circular(9),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FractionallySizedBox(
                    widthFactor: widthFactor,
                    child: const _LoadingBlock(height: 12),
                  ),
                  const SizedBox(height: 8),
                  const FractionallySizedBox(
                    widthFactor: 0.42,
                    child: _LoadingBlock(height: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock({
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

class _EnvironmentSection extends StatelessWidget {
  const _EnvironmentSection({
    required this.icon,
    required this.title,
    required this.count,
    required this.children,
  });

  final IconData icon;
  final String title;
  final int count;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EnvironmentSectionHeader(
          icon: icon,
          title: title,
          count: count,
        ),
        ...children,
        const SizedBox(height: 10),
      ],
    );
  }
}

class _EnvironmentSectionHeader extends StatelessWidget {
  const _EnvironmentSectionHeader({
    required this.icon,
    required this.title,
    required this.count,
  });

  final IconData icon;
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 18, 2, 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 15, color: colors.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 26),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: colors.accent,
                fontSize: 11,
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

class _EnvironmentInlineEmptyState extends StatelessWidget {
  const _EnvironmentInlineEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.textTertiary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _BuiltInEnvVarTile extends StatelessWidget {
  const _BuiltInEnvVarTile({required this.envVar});

  final EnvironmentVariable envVar;

  @override
  Widget build(BuildContext context) {
    return _EnvironmentVariableCard(
      envVar: envVar,
      badgeLabel: 'Auto ++',
      actions: [
        _EnvironmentIconButton(
          icon: Icons.edit_outlined,
          tooltip: t.common.edit,
          onPressed: () {
            showAdaptiveFormModal(
              context: context,
              builder: (context) =>
                  _EditBuiltInEnvVarBottomSheet(envVar: envVar),
            );
          },
        ),
      ],
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
    final colors = AppColors.of(context);

    return _EnvironmentVariableCard(
      envVar: envVar,
      actions: [
        _EnvironmentIconButton(
          icon: Icons.edit_outlined,
          tooltip: t.common.edit,
          onPressed: () {
            showAdaptiveFormModal(
              context: context,
              builder: (context) => _EditEnvVarBottomSheet(envVar: envVar),
            );
          },
        ),
        const SizedBox(width: 4),
        _EnvironmentIconButton(
          icon: Icons.delete_outline,
          color: colors.error,
          tooltip: t.common.delete,
          onPressed: onDelete,
        ),
      ],
    );
  }
}

class _EnvironmentVariableCard extends StatelessWidget {
  const _EnvironmentVariableCard({
    required this.envVar,
    required this.actions,
    this.badgeLabel,
  });

  final EnvironmentVariable envVar;
  final List<Widget> actions;
  final String? badgeLabel;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  Icons.terminal_rounded,
                  size: 17,
                  color: colors.accent,
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
                            envVar.key,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        if (badgeLabel != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: colors.success.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              badgeLabel!,
                              style: TextStyle(
                                color: colors.success,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      envVar.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: actions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnvironmentIconButton extends StatelessWidget {
  const _EnvironmentIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        icon: Icon(icon, size: 16, color: color ?? colors.textTertiary),
        tooltip: tooltip,
        onPressed: onPressed,
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

class _EnvironmentVariableFormFrame extends StatelessWidget {
  const _EnvironmentVariableFormFrame({
    required this.title,
    required this.icon,
    required this.child,
    required this.primaryAction,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget primaryAction;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isSheet = usesBottomSheetFormModal(context);
    final maxHeight =
        MediaQuery.sizeOf(context).height * (isSheet ? 0.78 : 0.9);

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
                        child: Icon(icon, size: 17, color: colors.accent),
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
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: colors.border)),
                    color: colors.surface,
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 14, 20, isSheet ? 20 : 16),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: isSheet
                          ? SizedBox(
                              width: double.infinity,
                              child: primaryAction,
                            )
                          : ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 112),
                              child: primaryAction,
                            ),
                    ),
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

InputDecoration _environmentInputDecoration(
  BuildContext context, {
  required String labelText,
  String? hintText,
}) {
  final colors = AppColors.of(context);

  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    filled: true,
    fillColor: colors.surfaceSecondary.withValues(alpha: 0.55),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: colors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: colors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: colors.accent, width: 1.4),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: colors.borderSubtle),
    ),
  );
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

    return _EnvironmentVariableFormFrame(
      title: envT.editRunNumber,
      icon: Icons.numbers_rounded,
      primaryAction: FilledButton(
        onPressed: isLoading.value
            ? null
            : () async {
                if (!formKey.currentState!.validate()) return;
                isLoading.value = true;
                try {
                  await ref
                      .read(environmentVariableManagerProvider.notifier)
                      .updateEnvironmentVariable(
                        documentId: envVar.id,
                        key: envVar.key,
                        value: valueController.text,
                      );
                  if (!context.mounted) return;
                  context.showSnackBarMessage(envT.runNumberUpdated);
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
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              enabled: false,
              initialValue: envVar.key,
              decoration: _environmentInputDecoration(
                context,
                labelText: envT.keyName,
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: valueController,
              decoration: _environmentInputDecoration(
                context,
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
          ],
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

    return _EnvironmentVariableFormFrame(
      title: envT.addEnvVar,
      icon: Icons.tune_rounded,
      primaryAction: FilledButton(
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
            context.showSnackBarMessage(envT.addedSuccess);
            Navigator.of(context).pop();
          } catch (e) {
            if (!context.mounted) return;
            context.showSnackBarMessage('$e');
          }
        },
        child: Text(t.common.add),
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: keyController,
              decoration: _environmentInputDecoration(
                context,
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
            const SizedBox(height: 14),
            TextFormField(
              controller: valueController,
              decoration: _environmentInputDecoration(
                context,
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
          ],
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

    return _EnvironmentVariableFormFrame(
      title: envT.editEnvVar,
      icon: Icons.tune_rounded,
      primaryAction: FilledButton(
        onPressed: isLoading.value
            ? null
            : () async {
                if (!formKey.currentState!.validate()) return;
                isLoading.value = true;
                try {
                  await ref
                      .read(environmentVariableManagerProvider.notifier)
                      .updateEnvironmentVariable(
                        documentId: envVar.id,
                        key: keyController.text.trim(),
                        value: valueController.text,
                      );
                  if (!context.mounted) return;
                  context.showSnackBarMessage(envT.updatedSuccess);
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
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: keyController,
              decoration: _environmentInputDecoration(
                context,
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
            const SizedBox(height: 14),
            TextFormField(
              controller: valueController,
              decoration: _environmentInputDecoration(
                context,
                labelText: envT.value,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return envT.enterValue;
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
