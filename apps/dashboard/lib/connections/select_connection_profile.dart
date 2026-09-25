import 'package:dashboard/app_strings.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'active_connection_profile_provider.dart';
import 'connection_firebase_auth.dart';
import 'connection_firebase_config.dart';
import 'connection_profile.dart';
import 'connection_store_provider.dart';

Future<void> selectConnectionProfile(
  BuildContext context,
  WidgetRef ref,
  ConnectionProfile profile, {
  bool closeSheet = false,
}) async {
  final store = ref.read(connectionStoreProvider);
  final selection = ref.read(activeConnectionProfileProvider(store).notifier);
  final router = GoRouter.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    // Initialize authentication before changing the saved selection, so a
    // configuration error leaves the current connection available.
    final authProvider = connectionFirebaseAuthProvider(
      profile.id,
      firebaseConfigForCurrentPlatform(profile),
    );
    if (ref.read(authProvider).hasError) ref.invalidate(authProvider);
    final auth = await ref.read(authProvider.future);
    final user = await auth.authStateChanges().first;
    if (!context.mounted) return;
    await selection.select(profile.id);

    // Root may remove the current page while authentication changes.
    if (closeSheet && context.mounted) Navigator.pop(context);
    router.go(user == null ? '/auth' : '/');
  } catch (error) {
    if (messenger.mounted) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          responsiveSnackBar(
            messenger.context,
            content: Text(t.common.error(error: error.toString())),
          ),
        );
    }
  }
}
