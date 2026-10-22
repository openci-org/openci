import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/connections/active_connection_profile_provider.dart';
import 'package:dashboard/connections/connection_profile.dart';
import 'package:dashboard/connections/connection_store_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

typedef BillingIdentity = ({ConnectionProfile connection, String userId});

final billingWebSupportedProvider = Provider<bool>((ref) => kIsWeb);

final billingIdentityProvider = Provider.autoDispose<BillingIdentity?>((ref) {
  if (!ref.watch(billingWebSupportedProvider)) return null;
  final store = ref.watch(connectionStoreProvider);
  final connection = ref.watch(activeConnectionProfileProvider(store));
  if (connection.isLoading || connection.hasError) return null;
  final profile = connection.asData?.value;
  if (profile == null || !profile.isCloud) return null;
  final user = ref.watch(authStateChangesProvider);
  if (user.isLoading || user.hasError) return null;
  final uid = user.asData?.value?.uid;
  return uid == null ? null : (connection: profile, userId: uid);
});
