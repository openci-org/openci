import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/theme/app_colors.dart';

import 'package:dashboard/build_info.dart';

import 'package:dashboard/firebase/firebase_config_provider.dart';

import 'package:dashboard/i18n/strings.g.dart';

import 'package:dashboard/notifications/notification_provider.dart';

import 'package:dashboard/notifications/notification_settings_page.dart';

import 'package:dashboard/revenue_cat/revenue_cat.dart';

import 'package:dashboard/revenue_cat/subscription_page.dart';

import 'package:dashboard/settings/locale_provider.dart';

import 'package:dashboard/team/team_provider.dart';

import 'package:dashboard/utilities/snack_bar_extension.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';

import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:material_symbols_icons/symbols.dart';

import 'package:package_info_plus/package_info_plus.dart';

import 'package:swipeable_page_route/swipeable_page_route.dart';


class SettingsPage extends HookConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDeleting = useState(false);
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
                      const _LanguageTile(),
                      const _GroupDivider(),
                      const _AppVersionTile(),
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

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
                  icon,
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
              Icons.chevron_right,
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

class _LanguageTile extends ConsumerWidget {
  const _LanguageTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeAsync = ref.watch(localeProvider);
    final langT = t.settings.language;

    final currentLabel = localeAsync.when(
      data: (savedLocale) => switch (savedLocale) {
        'en' => langT.english,
        'ja' => langT.japanese,
        'es' => langT.spanish,
        _ => langT.system,
      },
      loading: () => '...',
      error: (_, _) => langT.system,
    );

    return _SettingsItem(
      icon: Symbols.language,
      title: langT.title,
      subtitle: currentLabel,
      onTap: () {
        showModalBottomSheet(
          showDragHandle: true,
          context: context,
          builder: (_) => const _LanguageBottomSheet(),
        );
      },
    );
  }
}

class _LanguageBottomSheet extends ConsumerWidget {
  const _LanguageBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeAsync = ref.watch(localeProvider);
    final langT = t.settings.language;

    final options = <({String? tag, String label, String subtitle})>[
      (tag: null, label: langT.system, subtitle: ''),
      (tag: 'en', label: langT.english, subtitle: 'English'),
      (tag: 'ja', label: langT.japanese, subtitle: '日本語'),
      (tag: 'es', label: langT.spanish, subtitle: 'Español'),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                langT.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.of(context).textPrimary,
                ),
              ),
            ),
            _SettingsGroup(
              children: localeAsync.when(
                loading: () => [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator.adaptive(),
                    ),
                  ),
                ],
                error: (error, _) {
                  debugPrint(error.toString());
                  return [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(t.common.error(error: error.toString())),
                    ),
                  ];
                },
                data: (savedLocale) {
                  final items = <Widget>[];
                  for (var i = 0; i < options.length; i++) {
                    if (i > 0) items.add(const _GroupDivider());
                    final option = options[i];
                    final isSelected = option.tag == savedLocale;
                    items.add(
                      InkWell(
                        onTap: () async {
                          await ref
                              .read(localeProvider.notifier)
                              .setLocale(option.tag);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        hoverColor: AppColors.of(context).borderSubtle,
                        splashColor: AppColors.of(context).borderSubtle,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 13,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      option.label,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? AppColors.of(context).accent
                                            : AppColors.of(context).textPrimary,
                                      ),
                                    ),
                                    if (option.subtitle.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        option.subtitle,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.of(context).textPrimary.withValues(
                                            alpha: 0.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_rounded,
                                  size: 18,
                                  color: AppColors.of(context).accent,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return items;
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
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
        ? 'v${info.version} (${info.buildNumber})  •  $buildDate'
        : '...';

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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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
