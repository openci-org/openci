import 'dart:async';

import 'package:dashboard/app_strings.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/billing/billing_identity.dart';
import 'package:dashboard/connections/active_connection_profile_provider.dart';
import 'package:dashboard/connections/connection_store_provider.dart';
import 'package:dashboard/connections/local_development_connection.dart';
import 'package:dashboard/connections/select_connection_profile.dart';
import 'package:dashboard/settings/email_verification_settings.dart';
import 'package:dashboard/settings/language_selector.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/utilities/macos_updater_initializer.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_updater/macos_updater.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class SettingsPage extends HookConsumerWidget {
  const SettingsPage({super.key, this.onSwitchTeam});

  final VoidCallback? onSwitchTeam;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDeleting = useState(false);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          context.t.settings.title,
        ),
      ),
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  if (ref.watch(billingIdentityProvider) != null) ...[
                    _SectionHeader(label: context.t.billing.title),
                    _SettingsGroup(
                      children: [
                        _SettingsItem(
                          icon: Symbols.credit_card_rounded,
                          title: context.t.settings.manageBilling,
                          subtitle: context.t.settings.billingDescription,
                          onTap: () {
                            final selected = ref.read(selectedTeamProvider);
                            final teamId =
                                selected.isLoading || selected.hasError
                                ? null
                                : selected.asData?.value.id;
                            context.go(
                              Uri(
                                path: '/billing',
                                queryParameters: {'teamId': ?teamId},
                              ).toString(),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                  _SectionHeader(label: context.t.settings.preferences),
                  _SettingsGroup(
                    children: [
                      const _AppVersionTile(),
                      const _GroupDivider(),
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: LanguageSelector(),
                      ),
                      if (isMacosUpdaterSupportedPlatform) ...[
                        const _GroupDivider(),
                        _SettingsItem(
                          icon: Icons.system_update_alt_rounded,
                          title: context.t.settings.checkForUpdates,
                          subtitle:
                              context.t.settings.checkForUpdatesDescription,
                          trailingIcon: null,
                          onTap: () async {
                            try {
                              context.showSnackBarMessage(
                                context.t.settings.checkingUpdates,
                              );
                              final result = await checkForMacosUpdates();
                              if (!context.mounted) return;
                              context.showSnackBarMessage(
                                _formatUpdateCheckResult(context, result),
                              );
                            } catch (e, s) {
                              debugPrint(e.toString());
                              debugPrint(s.toString());
                              if (!context.mounted) return;
                              context.showSnackBarMessage(
                                context.t.settings.checkForUpdatesFailed(
                                  error: e.toString(),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionHeader(label: context.t.settings.teamSection),
                  _SettingsGroup(
                    children: [
                      _TeamSettingsTile(onSwitchTeam: onSwitchTeam),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionHeader(label: context.t.settings.account),
                  _SettingsGroup(
                    children: [
                      const EmailVerificationSettings(),
                      const _GroupDivider(),
                      _SettingsItem(
                        icon: Icons.logout_rounded,
                        title: context.t.settings.logout,
                        subtitle: context.t.settings.logoutDescription,
                        trailingIcon: null,
                        onTap: () => unawaited(_signOut(context, ref)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _ConnectionIndicator(),
                  const SizedBox(height: 16),
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

String _formatUpdateCheckResult(
  BuildContext context,
  MacosUpdaterCheckResult result,
) {
  return switch (result.type) {
    MacosUpdaterCheckResultType.updateAvailable =>
      result.displayVersion == null || result.displayVersion!.isEmpty
          ? context.t.settings.updateAvailable
          : context.t.settings.updateVersionAvailable(
              version: result.displayVersion!,
            ),
    MacosUpdaterCheckResultType.noUpdateFound => context.t.settings.noUpdate,
    MacosUpdaterCheckResultType.failed =>
      result.message.isEmpty
          ? context.t.settings.updateCheckFailed
          : context.t.settings.checkForUpdatesFailed(error: result.message),
  };
}

Future<void> _signOut(BuildContext context, WidgetRef ref) async {
  try {
    final auth = await ref.read(firebaseAuthProvider.future);
    await auth.signOut();

    if (!context.mounted) return;
    context.showSnackBarMessage(context.t.settings.logoutSuccess);
  } catch (e, s) {
    debugPrint(e.toString());
    debugPrint(s.toString());
    if (!context.mounted) return;
    context.showSnackBarMessage(
      context.t.settings.logoutFailed(error: e.toString()),
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
          color: Theme.of(context).colorScheme.outline,
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
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
      color: Theme.of(context).dividerColor,
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingIcon = Icons.chevron_right,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      hoverColor: colorScheme.outlineVariant.withValues(alpha: 0.5),
      splashColor: colorScheme.outlineVariant.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            if (trailingIcon != null)
              Icon(
                trailingIcon,
                size: 18,
                color: colorScheme.outline,
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingsInfoItem extends StatelessWidget {
  const _SettingsInfoItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 18,
                color: colorScheme.onSurfaceVariant,
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamSettingsTile extends ConsumerWidget {
  const _TeamSettingsTile({required this.onSwitchTeam});

  final VoidCallback? onSwitchTeam;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(selectedTeamProvider);

    return teamAsync.when(
      data: (team) {
        final switchTeam = onSwitchTeam;
        if (switchTeam == null) {
          return _SettingsInfoItem(
            icon: Icons.groups_2_outlined,
            title: context.t.team.selectTeamLabel,
            subtitle: team.name,
          );
        }

        return _SettingsItem(
          icon: Icons.groups_2_outlined,
          title: context.t.team.selectTeamLabel,
          subtitle: team.name,
          trailingIcon: Icons.expand_more_rounded,
          onTap: switchTeam,
        );
      },
      loading: () => _SettingsInfoItem(
        icon: Icons.groups_2_outlined,
        title: context.t.team.selectTeamLabel,
        subtitle: context.t.common.loading,
      ),
      error: (error, stackTrace) {
        debugPrint('error: $error, stackTrace: $stackTrace');
        unawaited(
          Sentry.captureException(error, stackTrace: stackTrace),
        );
        return _SettingsInfoItem(
          icon: Icons.groups_2_outlined,
          title: context.t.team.selectTeamLabel,
          subtitle: context.t.settings.teamLoadFailed,
        );
      },
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

    final colorScheme = Theme.of(context).colorScheme;

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
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                child: Icon(
                  Symbols.info_rounded,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t.settings.appVersion,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    versionText,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.outline,
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

class _ConnectionIndicator extends HookConsumerWidget {
  const _ConnectionIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSwitching = useState(false);
    final store = ref.watch(connectionStoreProvider);
    final activeProfile = ref.watch(activeConnectionProfileProvider(store));
    final localDevelopment = ref.watch(localDevelopmentConnectionProvider);
    final profile = activeProfile.value;
    if (profile == null) return const SizedBox.shrink();

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
                      localDevelopment != null
                          ? 'Local Auth Emulator · demo-openci'
                          : profile.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.apiUrl,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!profile.isCloud && localDevelopment == null) ...[
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
                onPressed: isSwitching.value || activeProfile.isLoading
                    ? null
                    : () async {
                        if (isSwitching.value) return;
                        isSwitching.value = true;
                        try {
                          await selectConnectionProfile(
                            context,
                            ref,
                            store.cloud,
                          );
                        } finally {
                          if (context.mounted) isSwitching.value = false;
                        }
                      },
                child: isSwitching.value
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        context.t.settings.returnToCloud,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeleteAccountButton extends ConsumerWidget {
  const _DeleteAccountButton({required this.isDeleting});

  final ValueNotifier<bool> isDeleting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            : () => _showDeleteConfirmationDialog(context, ref),
        child: Text(
          context.t.settings.deleteAccount,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t.settings.deleteConfirmTitle),
        content: Text(context.t.settings.deleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.t.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              context.t.common.delete,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _deleteAccount(context, ref);
    }
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    isDeleting.value = true;
    try {
      final auth = await ref.read(firebaseAuthProvider.future);
      if (!context.mounted) return;
      final user = auth.currentUser;
      if (user == null) {
        throw Exception(context.t.settings.noUserSignedIn);
      }
      await user.delete();
      if (!context.mounted) return;
      context.showSnackBarMessage(context.t.settings.deleteSuccess);
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      if (e.code == 'requires-recent-login') {
        context.showSnackBarMessage(context.t.settings.requiresRecentLogin);
      } else {
        context.showSnackBarMessage(
          context.t.settings.deleteFailed(error: e.message ?? e.code),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      context.showSnackBarMessage(
        context.t.settings.deleteFailed(error: e.toString()),
      );
    } finally {
      isDeleting.value = false;
    }
  }
}
