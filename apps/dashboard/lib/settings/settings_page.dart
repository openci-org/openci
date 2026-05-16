import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/build_info.dart';
import 'package:dashboard/firebase/firebase_config_provider.dart';
import 'package:dashboard/app_strings.dart';
import 'package:dashboard/macos_updater_initializer.dart';
import 'package:dashboard/notifications/notification_provider.dart';
import 'package:dashboard/notifications/notification_settings_page.dart';
import 'package:dashboard/revenue_cat/revenue_cat.dart';
import 'package:dashboard/revenue_cat/subscription_page.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/theme/app_colors.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

class SettingsPage extends HookConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDeleting = useState(false);
    final isCheckingForUpdates = useState(false);
    final settingsT = t.settings;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _SectionHeader(label: settingsT.general),
                  _SettingsGroup(
                    children: [
                      _SettingsItem(
                        icon: Symbols.notifications_rounded,
                        title: settingsT.buildNotifications,
                        subtitle: settingsT.configureNotifications,
                        onTap: () => Navigator.of(context).push(
                          SwipeablePageRoute(
                            builder: (_) => const NotificationSettingsPage(),
                          ),
                        ),
                      ),
                      const _GroupDivider(),
                      const _AiFeaturesTile(),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionHeader(label: settingsT.subscription),
                  _SettingsGroup(
                    children: [
                      _SettingsItem(
                        icon: Symbols.credit_card_rounded,
                        title: settingsT.subscription,
                        subtitle: settingsT.manageSubscription,
                        onTap: () => Navigator.of(context).push(
                          SwipeablePageRoute(
                            builder: (_) => const SubscriptionPage(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionHeader(label: settingsT.preferences),
                  _SettingsGroup(
                    children: [
                      const _AppVersionTile(),
                      if (isMacosUpdaterAvailable) ...[
                        const _GroupDivider(),
                        _SettingsItem(
                          icon: Symbols.system_update_alt_rounded,
                          title: settingsT.checkForUpdates,
                          subtitle: settingsT.checkForUpdatesDescription,
                          isLoading: isCheckingForUpdates.value,
                          onTap: () async {
                            if (isCheckingForUpdates.value) {
                              return;
                            }
                            isCheckingForUpdates.value = true;
                            try {
                              await checkForMacosUpdates();
                              if (!context.mounted) return;
                              context.showSnackBarMessage(
                                settingsT.checkForUpdatesStarted,
                              );
                            } catch (e, s) {
                              debugPrint(e.toString());
                              debugPrint(s.toString());
                              if (!context.mounted) return;
                              context.showSnackBarMessage(
                                settingsT.checkForUpdatesFailed(
                                  error: e.toString(),
                                ),
                              );
                            } finally {
                              isCheckingForUpdates.value = false;
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _SelfHostedIndicator(),
                  const SizedBox(height: 24),
                  _ActionButton(
                    label: settingsT.logout,
                    onPressed: () async {
                      try {
                        await logoutRevenueCat();
                        await FirebaseAuth.instance.signOut();
                        ref.invalidate(notificationServiceProvider);
                        ref.invalidate(authProvider);
                        if (!context.mounted) return;
                        context.showSnackBarMessage(settingsT.logoutSuccess);
                      } catch (e, s) {
                        debugPrint(e.toString());
                        debugPrint(s.toString());
                        context.showSnackBarMessage(
                          settingsT.logoutFailed(error: e.toString()),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  _DeleteAccountButton(isDeleting: isDeleting),
                ],
              ),
            ),
          ),
          if (isDeleting.value) ...[
            const ModalBarrier(dismissible: false, color: Colors.black26),
            const Center(child: CircularProgressIndicator.adaptive()),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.of(context).textTertiary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.of(context).border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class _GroupDivider extends StatelessWidget {
  const _GroupDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.of(context).divider,
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLoading = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      hoverColor: AppColors.of(context).borderSubtle,
      splashColor: AppColors.of(context).borderSubtle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.of(context).divider,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                child: Icon(
                  isLoading ? Symbols.progress_activity_rounded : icon,
                  size: 18,
                  color: AppColors.of(context).textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.of(context).textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.of(context).textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isLoading ? Icons.more_horiz_rounded : Icons.chevron_right,
              size: 18,
              color: AppColors.of(context).textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _AiFeaturesTile extends ConsumerWidget {
  const _AiFeaturesTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamStateProvider);
    final aiT = t.settings.aiFeatures;

    return teamAsync.when(
      data: (team) {
        final isEnabled = team.aiEnabled;
        return InkWell(
          onTap: () async {
            try {
              await ref
                  .read(teamListProvider.notifier)
                  .updateAiEnabled(team.id, !isEnabled);
              if (!context.mounted) return;
              context.showSnackBarMessage(aiT.updated);
            } catch (e) {
              if (!context.mounted) return;
              context.showSnackBarMessage(
                t.common.error(error: e.toString()),
              );
            }
          },
          hoverColor: AppColors.of(context).borderSubtle,
          splashColor: AppColors.of(context).borderSubtle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? AppColors.of(context).accent.withValues(alpha: 0.15)
                        : AppColors.of(context).divider,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.auto_awesome,
                      size: 18,
                      color: isEnabled
                          ? AppColors.of(context).accent
                          : AppColors.of(context).textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        aiT.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.of(context).textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isEnabled ? aiT.enabled : aiT.disabled,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.of(context).textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 28,
                  child: Switch.adaptive(
                    value: isEnabled,
                    onChanged: (value) async {
                      try {
                        await ref
                            .read(teamListProvider.notifier)
                            .updateAiEnabled(team.id, value);
                        if (!context.mounted) return;
                        context.showSnackBarMessage(aiT.updated);
                      } catch (e) {
                        if (!context.mounted) return;
                        context.showSnackBarMessage(
                          t.common.error(error: e.toString()),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.of(context).divider,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                child: Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: AppColors.of(context).textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    aiT.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.of(context).textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    aiT.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.of(context).textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator.adaptive(strokeWidth: 2),
            ),
          ],
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _AppVersionTile extends HookWidget {
  const _AppVersionTile();

  @override
  Widget build(BuildContext context) {
    final snapshot = useFuture(
      useMemoized(() => PackageInfo.fromPlatform()),
    );

    final info = snapshot.data;
    final versionText = info != null
        ? 'v${info.version} (${info.buildNumber})'
        : '...';
    final buildUpdatedText = _formatBuildUpdatedText();

    return InkWell(
      onTap: null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.of(context).divider,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                child: Icon(
                  Symbols.info_rounded,
                  size: 18,
                  color: AppColors.of(context).textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.settings.appVersion,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.of(context).textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    versionText,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.of(context).textTertiary,
                    ),
                  ),
                  if (buildUpdatedText != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      buildUpdatedText,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.of(context).textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String? _formatBuildUpdatedText() {
  final updatedAt = BuildInfo.updatedAt;
  if (updatedAt == null) {
    return null;
  }

  final formattedDate = DateFormat('yyyy/MM/dd HH:mm').format(updatedAt);
  final shaSuffix = BuildInfo.sha.isEmpty ? '' : ' (${BuildInfo.sha})';
  return '最終更新: $formattedDate$shaSuffix';
}

class _SelfHostedIndicator extends StatelessWidget {
  const _SelfHostedIndicator();

  @override
  Widget build(BuildContext context) {
    final settingsT = t.settings;

    return FutureBuilder<SelfHostedConfig?>(
      future: loadSelfHostedConfig(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final config = snapshot.data;
        if (config != null) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.amber.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.cloud_outlined,
                          size: 18,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            settingsT.selfHostedActive,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.of(context).textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            settingsT.selfHostedProject(
                              projectId: config.projectId,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.of(context).textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.amber,
                      backgroundColor: Colors.amber.withValues(alpha: 0.1),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: Colors.amber.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    onPressed: () async {
                      await clearSelfHostedConfig();
                      if (!context.mounted) return;
                      context.showSnackBarMessage(
                        settingsT.resetToCloudSuccess,
                      );
                    },
                    child: Text(
                      settingsT.resetToCloud,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Center(
          child: Text(
            settingsT.firebaseAppName(
              name: FirebaseAuth.instance.app.name,
            ),
            style: TextStyle(
              fontSize: 12,
              color: AppColors.of(context).textTertiary,
            ),
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.of(context).textPrimary,
          backgroundColor: AppColors.of(context).divider,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: AppColors.of(context).border,
            ),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _DeleteAccountButton extends StatelessWidget {
  const _DeleteAccountButton({required this.isDeleting});

  final ValueNotifier<bool> isDeleting;

  @override
  Widget build(BuildContext context) {
    final settingsT = t.settings;
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: Colors.red.withValues(alpha: 0.7),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: isDeleting.value
            ? null
            : () => _showDeleteConfirmationDialog(context),
        child: Text(
          settingsT.deleteAccount,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    final settingsT = t.settings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(settingsT.deleteConfirmTitle),
        content: Text(settingsT.deleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              t.common.delete,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _deleteAccount(context);
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final settingsT = t.settings;
    isDeleting.value = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception(settingsT.noUserSignedIn);
      }
      await user.delete();
      if (!context.mounted) return;
      context.showSnackBarMessage(settingsT.deleteSuccess);
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      if (e.code == 'requires-recent-login') {
        context.showSnackBarMessage(settingsT.requiresRecentLogin);
      } else {
        context.showSnackBarMessage(
          settingsT.deleteFailed(error: e.message ?? e.code),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      context.showSnackBarMessage(
        settingsT.deleteFailed(error: e.toString()),
      );
    } finally {
      isDeleting.value = false;
    }
  }
}
