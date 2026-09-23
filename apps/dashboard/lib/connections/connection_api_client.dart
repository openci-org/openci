import 'package:chopper/chopper.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../firebase/firebase_config_provider.dart';
import 'connection_firebase_auth.dart';
import 'connection_profile.dart';

part 'connection_api_client.g.dart';

@riverpod
ChopperClient connectionApiClient(
  Ref ref,
  ConnectionProfile profile,
  SelfHostedConfig config,
) {
  final auth = ref.watch(
    connectionFirebaseAuthProvider(profile.id, config).future,
  );
  final client = createOpenCIChopperClient(
    baseUrl: profile.apiUrl,
    tokenProvider: () async => (await auth).currentUser?.getIdToken(),
  );
  ref.onDispose(client.dispose);
  return client;
}
