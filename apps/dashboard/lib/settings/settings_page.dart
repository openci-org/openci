import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/notifications/notification_settings_page.dart';
import 'package:dashboard/revenue_cat/subscription_page.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

String _localeDisplayName(BuildContext context, AppLocale locale) =>
    switch (locale) {
      AppLocale.en => context.t.locale.en,
      AppLocale.ja => context.t.locale.ja,
    };

class SettingsPage extends HookConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final isDeleting = useState(false);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    String email;
    String initial;
    try {
      final user = FirebaseAuth.instance.currentUser;
      email = user?.email ?? 'user@example.com';
    } catch (_) {
      email = 'user@example.com';
    }
    initial = email.isNotEmpty ? email[0].toUpperCase() : '?';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.settings.title,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              _ProfileCard(
                email: email,
                initial: initial,
                isDark: isDark,
                colorScheme: colorScheme,
                plan: SubscriptionPlan.standard,
              ),
              const SizedBox(height: 28),
              _SectionHeader(
                title: t.settings.general,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 8),
              _SettingsCard(
                isDark: isDark,
                colorScheme: colorScheme,
                children: [
                  _SettingsTile(
                    icon: Symbols.notifications_rounded,
                    iconColor: const Color(0xFF58A6FF),
                    title: t.settings.buildNotifications,
                    subtitle: t.settings.buildNotificationsDesc,
                    colorScheme: colorScheme,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationSettingsPage(),
                      ),
                    ),
                  ),
                  _SettingsDivider(isDark: isDark),
                  _SettingsTile(
                    icon: Symbols.credit_card_rounded,
                    iconColor: const Color(0xFFD2A8FF),
                    title: t.settings.subscription,
                    subtitle: t.settings.subscriptionDesc,
                    colorScheme: colorScheme,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SubscriptionPage(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              _SectionHeader(
                title: t.settings.support,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 8),
              _SettingsCard(
                isDark: isDark,
                colorScheme: colorScheme,
                children: [
                  _SettingsTile(
                    icon: FontAwesomeIcons.github,
                    iconColor: colorScheme.onSurface,
                    title: t.settings.githubRepo,
                    subtitle: t.settings.githubRepoDesc,
                    colorScheme: colorScheme,
                    onTap: () {
                      context.showSnackBarMessage(
                        t.settings.openingGithub,
                      );
                    },
                    trailing: FaIcon(
                      FontAwesomeIcons.arrowUpRightFromSquare,
                      size: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  _SettingsDivider(isDark: isDark),
                  _SettingsTile(
                    icon: Symbols.bug_report_rounded,
                    iconColor: const Color(0xFFFF6B6B),
                    title: t.settings.reportBug,
                    subtitle: t.settings.reportBugDesc,
                    colorScheme: colorScheme,
                    onTap: () {
                      context.showSnackBarMessage(
                        t.settings.openingIssueTracker,
                      );
                    },
                    trailing: FaIcon(
                      FontAwesomeIcons.arrowUpRightFromSquare,
                      size: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SectionHeader(
                title: t.settings.language,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 8),
              _SettingsCard(
                isDark: isDark,
                colorScheme: colorScheme,
                children: [
                  _SettingsTile(
                    icon: Symbols.language_rounded,
                    iconColor: const Color(0xFF56D364),
                    title: t.settings.language,
                    subtitle: t.settings.languageDesc,
                    colorScheme: colorScheme,
                    onTap: () => showModalBottomSheet(
                      context: context,
                      showDragHandle: true,
                      builder: (_) => const _LanguageSheet(),
                    ),
                    trailing: Text(
                      _localeDisplayName(context, LocaleSettings.currentLocale),
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SectionHeader(
                title: t.settings.account,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 8),
              _SettingsCard(
                isDark: isDark,
                colorScheme: colorScheme,
                children: [
                  _SettingsTile(
                    icon: Symbols.logout_rounded,
                    iconColor: const Color(0xFFF0883E),
                    title: t.settings.logout,
                    subtitle: t.settings.logoutDesc,
                    colorScheme: colorScheme,
                    onTap: () async {
                      try {
                        await FirebaseAuth.instance.signOut();
                        ref.invalidate(authProvider);
                        if (!context.mounted) return;
                        context.showSnackBarMessage(
                          t.settings.loggedOut,
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        context.showSnackBarMessage(
                          t.settings.logoutFailed(error: '$e'),
                        );
                      }
                    },
                  ),
                  _SettingsDivider(isDark: isDark),
                  _SettingsTile(
                    icon: Symbols.delete_forever_rounded,
                    iconColor: const Color(0xFFFF6B6B),
                    title: t.settings.deleteAccount,
                    subtitle: t.settings.deleteAccountDesc,
                    colorScheme: colorScheme,
                    destructive: true,
                    onTap: isDeleting.value
                        ? null
                        : () => _showDeleteConfirmation(
                            context,
                            isDeleting,
                            colorScheme,
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Center(
                child: Column(
                  children: [
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        BlendMode.srcIn,
                      ),
                      child: Image.asset(
                        'assets/company_logo.png',
                        height: 24,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'v1.4.0 · ${t.common.openSource}',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isDeleting.value) ...[
            const ModalBarrier(dismissible: false, color: Colors.black54),
            const Center(child: CircularProgressIndicator.adaptive()),
          ],
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    ValueNotifier<bool> isDeleting,
    ColorScheme colorScheme,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFFF6B6B),
              size: 22,
            ),
            SizedBox(width: 10),
            Text(
              t.settings.deleteAccount,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          t.settings.deleteConfirmation,
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              t.common.cancel,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(t.common.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _deleteAccount(context, isDeleting);
    }
  }

  Future<void> _deleteAccount(
    BuildContext context,
    ValueNotifier<bool> isDeleting,
  ) async {
    isDeleting.value = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }
      await user.delete();
      await FirebaseAuth.instance.signOut();
      if (!context.mounted) return;
      context.showSnackBarMessage(t.settings.accountDeleted);
    } catch (e) {
      if (!context.mounted) return;
      context.showSnackBarMessage(
        t.settings.deleteAccountFailed(error: '$e'),
      );
    } finally {
      isDeleting.value = false;
    }
  }
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.settings.language,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...AppLocale.values.map((locale) {
              final isSelected = LocaleSettings.currentLocale == locale;
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                title: Text(
                  _localeDisplayName(context, locale),
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                onTap: () {
                  LocaleSettings.setLocale(locale);
                  Navigator.of(context).pop();
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

enum SubscriptionPlan {
  nano,
  standard,
  pro
  ;

  String get label => switch (this) {
    nano => 'Nano',
    standard => 'Standard',
    pro => 'Pro',
  };

  Color get color => switch (this) {
    nano => const Color(0xFF8B949E),
    standard => const Color(0xFF58A6FF),
    pro => const Color(0xFFD2A8FF),
  };

  IconData get icon => switch (this) {
    nano => Icons.bolt_rounded,
    standard => Icons.rocket_launch_rounded,
    pro => Icons.diamond_rounded,
  };
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.email,
    required this.initial,
    required this.isDark,
    required this.colorScheme,
    this.plan = SubscriptionPlan.nano,
  });

  final String email;
  final String initial;
  final bool isDark;
  final ColorScheme colorScheme;
  final SubscriptionPlan plan;

  @override
  Widget build(BuildContext context) {
    final planColor = plan.color;
    final isPaid = plan != SubscriptionPlan.nano;

    final baseColor = isDark
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
        : colorScheme.surfaceContainerLowest;

    BoxDecoration decoration;
    switch (plan) {
      case SubscriptionPlan.nano:
        decoration = BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        );
        break;
      case SubscriptionPlan.standard:
        decoration = BoxDecoration(
          color: baseColor,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(baseColor, planColor, 0.12)!,
              baseColor,
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: planColor.withValues(alpha: 0.4),
            width: 1,
          ),
        );
        break;
      case SubscriptionPlan.pro:
        decoration = BoxDecoration(
          color: baseColor,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(baseColor, planColor, 0.22)!,
              Color.lerp(baseColor, const Color(0xFF58A6FF), 0.1)!,
              baseColor,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: planColor.withValues(alpha: 0.6),
            width: 1.5,
          ),
        );
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: decoration,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: plan == SubscriptionPlan.pro
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        planColor.withValues(alpha: 0.3),
                        const Color(0xFF58A6FF).withValues(alpha: 0.15),
                      ],
                    )
                  : null,
              color: plan != SubscriptionPlan.pro
                  ? planColor.withValues(alpha: 0.15)
                  : null,
            ),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: planColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(plan.icon, size: 13, color: planColor),
                    const SizedBox(width: 4),
                    Text(
                      plan.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: planColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: isPaid
                ? planColor.withValues(alpha: 0.5)
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.colorScheme,
  });

  final String title;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.children,
    required this.isDark,
    required this.colorScheme,
  });

  final List<Widget> children;
  final bool isDark;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.colorScheme,
    this.onTap,
    this.trailing,
    this.destructive = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final ColorScheme colorScheme;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: icon == FontAwesomeIcons.github
                      ? FaIcon(icon, size: 17, color: iconColor)
                      : Icon(icon, size: 20, color: iconColor),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: destructive
                            ? const Color(0xFFFF6B6B)
                            : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 66),
      child: Divider(
        height: 1,
        color: Theme.of(
          context,
        ).colorScheme.outlineVariant.withValues(alpha: 0.3),
      ),
    );
  }
}
