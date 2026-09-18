import 'package:chopper/chopper.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'active_connection_profile_provider.dart';
import 'connection_api_client.dart';
import 'connection_firebase_config.dart';
import 'connection_store_provider.dart';

part 'active_connection_api_client.g.dart';

@riverpod
Future<ChopperClient> activeConnectionApiClient(Ref ref) async {
  final store = ref.watch(connectionStoreProvider);
  final profile = await ref.watch(
    activeConnectionProfileProvider(store).future,
  );
  return ref.watch(
    connectionApiClientProvider(
      profile,
      firebaseConfigForCurrentPlatform(profile),
    ),
  );
}
