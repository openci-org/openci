import 'package:dashboard/auth/auth_provider.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ListTile(
                    leading: Icon(
                      Symbols.notifications_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    title: Text(settingsT.buildNotifications),
                    subtitle: Text(
                      settingsT.configureNotifications,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        SwipeablePageRoute(
                          builder: (_) => const NotificationSettingsPage(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  const _AiFeaturesTile(),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      Symbols.credit_card_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    title: Text(settingsT.subscription),
                    subtitle: Text(
                      settingsT.manageSubscription,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        SwipeablePageRoute(
                          builder: (_) => const SubscriptionPage(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  _LanguageTile(),
                  const Divider(),
                  _AppVersionTile(),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _SelfHostedIndicator(),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () async {
                                try {
                                  await logoutRevenueCat();
                                  await FirebaseAuth.instance.signOut();
                                  ref.invalidate(notificationServiceProvider);
                                  ref.invalidate(authProvider);
                                  if (!context.mounted) return;
                                  context.showSnackBarMessage(
                                    settingsT.logoutSuccess,
                                  );
                                } catch (e, s) {
                                  debugPrint(e.toString());
                                  debugPrint(s.toString());
                                  context.showSnackBarMessage(
                                    settingsT.logoutFailed(
                                      error: e.toString(),
                                    ),
                                  );
                                }
                              },
                              child: Text(settingsT.logout),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _DeleteAccountButton(
                            isDeleting: isDeleting,
                          ),
                        ],
                      ),
                    ),
                  ),
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

class _SelfHostedIndicator extends StatelessWidget {
  const _SelfHostedIndicator();


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settingsT = t.settings;

    return FutureBuilder<SelfHostedConfig?>(
      future: loadSelfHostedConfig(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final config = snapshot.data;
        if (config != null) {
          // Self-hosted config is saved in SharedPreferences
          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_outlined,
                      size: 18,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            settingsT.selfHostedActive,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            settingsT.selfHostedProject(
                              projectId: config.projectId,
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    side: BorderSide(
                      color: colorScheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  onPressed: () async {
                    await clearSelfHostedConfig();
                    if (!context.mounted) return;
                    context.showSnackBarMessage(
                      settingsT.resetToCloudSuccess,
                    );
                  },
                  child: Text(settingsT.resetToCloud),
                ),
              ),
            ],
          );
        }

        // Default: show normal app name
        return Text(
          settingsT.firebaseAppName(
            name: FirebaseAuth.instance.app.name,
          ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        );
      },
    );
  }
}

class _AiFeaturesTile extends ConsumerWidget {
  const _AiFeaturesTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final teamAsync = ref.watch(teamStateProvider);
    final aiT = t.settings.aiFeatures;

    return teamAsync.when(
      data: (team) {
        final isEnabled = team.aiEnabled;
        return SwitchListTile(
          secondary: Icon(
            Icons.auto_awesome,
            color: isEnabled
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          title: Text(aiT.title),
          subtitle: Text(
            isEnabled ? aiT.enabled : aiT.disabled,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
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
        );
      },
      loading: () => ListTile(
        leading: Icon(
          Icons.auto_awesome,
          color: colorScheme.onSurfaceVariant,
        ),
        title: Text(aiT.title),
        subtitle: Text(
          aiT.subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator.adaptive(strokeWidth: 2),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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

    return ListTile(
      leading: Icon(
        Symbols.language,
        color: colorScheme.onSurfaceVariant,
      ),
      title: Text(langT.title),
      subtitle: Text(
        currentLabel,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
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
      (tag: 'ja', label: langT.japanese, subtitle: 'Japanese'),
      (tag: 'es', label: langT.spanish, subtitle: 'Spanish'),
    ];

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              langT.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          localeAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator.adaptive(),
              ),
            ),
            error: (error, _) {
              debugPrint(error.toString());
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(t.common.error(error: error.toString())),
              );
            },
            data: (savedLocale) => Column(
              mainAxisSize: MainAxisSize.min,
              children: options.map(
                (option) {
                  final isSelected = option.tag == savedLocale;
                  return ListTile(
                    leading: isSelected
                        ? Icon(
                            Icons.check,
                            color: Theme.of(context).primaryColor,
                          )
                        : const SizedBox(width: 24),
                    title: Text(
                      option.label,
                      style: isSelected
                          ? TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                    ),
                    subtitle: option.subtitle.isNotEmpty
                        ? Text(option.subtitle)
                        : null,
                    onTap: () async {
                      await ref
                          .read(localeProvider.notifier)
                          .setLocale(option.tag);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                  );
                },
              ).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _AppVersionTile extends HookWidget {
  const _AppVersionTile();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final snapshot = useFuture(
      useMemoized(() => PackageInfo.fromPlatform()),
    );

    final info = snapshot.data;

    return ListTile(
      leading: Icon(
        Symbols.info_rounded,
        color: colorScheme.onSurfaceVariant,
      ),
      title: Text(t.settings.appVersion),
      subtitle: info != null
          ? Text(
              'v${info.version} (${info.buildNumber})  •  $buildDate',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : const SizedBox(
              height: 12,
              width: 12,
              child: CircularProgressIndicator.adaptive(strokeWidth: 2),
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
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.error,
        ),
        onPressed: isDeleting.value
            ? null
            : () => _showDeleteConfirmationDialog(context),
        child: Text(settingsT.deleteAccount),
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
