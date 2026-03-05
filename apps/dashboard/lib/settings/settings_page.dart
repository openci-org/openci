import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/firebase/firestore_provider.dart';
import 'package:dashboard/notifications/notification_settings_page.dart';
import 'package:dashboard/revenue_cat/subscription_page.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              ListTile(
                leading: Icon(Symbols.notifications_rounded),
                title: Text('Build Notifications'),
                subtitle: Text('Configure when to receive notifications'),
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
                title: Text('Subscription'),
                subtitle: Text('Manage your subscription plan'),
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
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Firebase App Name: ${auth.getFirebaseAuth().app.name}',
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
                        child: Text("Invite Team Member"),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          fixedSize: Size(200, 20),
                        ),
                        onPressed: () async {
                          try {
                            await auth.getFirebaseAuth().signOut();
                            ref.invalidate(authProvider);
                            ref.invalidate(firestoreProvider);
                            if (!context.mounted) return;
                            context.showSnackBarMessage(
                              'Logged out successfully',
                            );
                          } catch (e) {
                            context.showSnackBarMessage(
                              'Failed to log out: $e',
                            );
                          }
                        },
                        child: Text("Logout"),
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

class _DeleteAccountButton extends StatelessWidget {
  const _DeleteAccountButton({required this.isDeleting});

  final ValueNotifier<bool> isDeleting;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        fixedSize: Size(200, 20),
      ),
      onPressed: isDeleting.value
          ? null
          : () => _showDeleteConfirmationDialog(context),
      child: Text(
        "Delete Account",
        style: TextStyle(
          color: isDeleting.value ? Colors.grey : Colors.red,
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Account"),
        content: Text(
          "Are you sure you want to delete your account? "
          "This action cannot be undone and all your data will be permanently deleted.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              "Delete",
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
    isDeleting.value = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("No user is currently signed in");
      }
      await user.delete();
      if (!context.mounted) return;
      context.showSnackBarMessage('Account deleted successfully');
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      if (e.code == 'requires-recent-login') {
        context.showSnackBarMessage(
          'Please sign out and sign in again before deleting your account',
        );
      } else {
        context.showSnackBarMessage(
          'Failed to delete account: ${e.message}',
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      context.showSnackBarMessage('Failed to delete account: $e');
    } finally {
      isDeleting.value = false;
    }
  }
}
