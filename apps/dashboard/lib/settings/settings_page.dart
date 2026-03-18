import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/firebase/firestore_provider.dart';
import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/notifications/notification_settings_page.dart';
import 'package:dashboard/revenue_cat/revenue_cat.dart';
import 'package:dashboard/revenue_cat/subscription_page.dart';
import 'package:dashboard/settings/locale_provider.dart';
import 'package:dashboard/team/invite_team_member_bottom_sheet.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

class SettingsPage extends HookConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDeleting = useState(false);
    final auth = ref.watch(authProvider.notifier);
    final settingsT = t.settings;

    return Scaffold(
      appBar: AppBar(
        title: Text(settingsT.title),
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              ListTile(
                leading: Icon(Symbols.notifications_rounded),
                title: Text(settingsT.buildNotifications),
                subtitle: Text(settingsT.configureNotifications),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationSettingsPage(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Symbols.credit_card_rounded),
                title: Text(settingsT.subscription),
                subtitle: Text(settingsT.manageSubscription),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionPage(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              _LanguageTile(),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        settingsT.firebaseAppName(
                          name: auth.getFirebaseAuth().app.name,
                        ),
                      ),
                      SizedBox(height: 40),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          fixedSize: Size(200, 20),
                        ),
                        onPressed: () {
                          showModalBottomSheet(
                            showDragHandle: true,
                            context: context,
                            builder: (context) {
                              return SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.6,
                                child: InviteTeamMemberBottomSheet(),
                              );
                            },
                          );
                        },
                        child: Text(settingsT.inviteTeamMember),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          fixedSize: Size(200, 20),
                        ),
                        onPressed: () async {
                          try {
                            await logoutRevenueCat();
                            await auth.getFirebaseAuth().signOut();
                            ref.invalidate(authProvider);
                            ref.invalidate(firestoreProvider);
                            if (!context.mounted) return;
                            context.showSnackBarMessage(
                              settingsT.logoutSuccess,
                            );
                          } catch (e) {
                            context.showSnackBarMessage(
                              settingsT.logoutFailed(error: e.toString()),
                            );
                          }
                        },
                        child: Text(settingsT.logout),
                      ),
                      SizedBox(height: 8),
                      _DeleteAccountButton(
                        isDeleting: isDeleting,
                      ),
                    ],
                  ),
                ),
              ),
            ],
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

    return ListTile(
      leading: Icon(Symbols.language),
      title: Text(langT.title),
      subtitle: Text(currentLabel),
      trailing: Icon(Icons.chevron_right),
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
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
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

class _DeleteAccountButton extends StatelessWidget {
  const _DeleteAccountButton({required this.isDeleting});

  final ValueNotifier<bool> isDeleting;

  @override
  Widget build(BuildContext context) {
    final settingsT = t.settings;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        fixedSize: Size(200, 20),
      ),
      onPressed: isDeleting.value
          ? null
          : () => _showDeleteConfirmationDialog(context),
      child: Text(
        settingsT.deleteAccount,
        style: TextStyle(
          color: isDeleting.value ? Colors.grey : Colors.red,
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
              style: TextStyle(color: Colors.red),
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
