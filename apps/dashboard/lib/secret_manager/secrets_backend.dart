import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../connections/active_connection_firebase_auth.dart';
import '../connections/local_development_connection.dart';
import '../generated/secrets/secrets.dart';

part 'secrets_backend.g.dart';

@riverpod
Future<SecretsConnector> secretsConnector(Ref ref) async {
  final auth = await ref.watch(activeConnectionFirebaseAuthProvider.future);
  final local = ref.watch(localDevelopmentConnectionProvider);
  final dc = FirebaseDataConnect.instanceFor(
    app: auth.app,
    connectorConfig: SecretsConnector.connectorConfig,
    sdkType: CallerSDKType.generated,
  );
  if (local != null) dc.useDataConnectEmulator(local.emulatorHost, 9399);
  return SecretsConnector(dataConnect: dc);
}

@riverpod
Future<HttpsCallable> teamSecretsCallable(Ref ref) async {
  final auth = await ref.watch(activeConnectionFirebaseAuthProvider.future);
  final local = ref.watch(localDevelopmentConnectionProvider);
  final functions = FirebaseFunctions.instanceFor(
    app: auth.app,
    region: 'asia-northeast1',
  );
  if (local != null) functions.useFunctionsEmulator(local.emulatorHost, 5001);
  return functions.httpsCallable('teamSecrets');
}
