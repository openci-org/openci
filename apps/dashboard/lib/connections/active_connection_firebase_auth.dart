import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'active_connection_profile_provider.dart';
import 'connection_firebase_auth.dart';
import 'connection_firebase_config.dart';
import 'connection_store_provider.dart';

part 'active_connection_firebase_auth.g.dart';

@riverpod
Future<FirebaseAuth> activeConnectionFirebaseAuth(Ref ref) async {
  final store = ref.watch(connectionStoreProvider);
  final profile = await ref.watch(
    activeConnectionProfileProvider(store).future,
  );
  return ref.watch(
    connectionFirebaseAuthProvider(
      profile.id,
      firebaseConfigForCurrentPlatform(profile),
    ).future,
  );
}
