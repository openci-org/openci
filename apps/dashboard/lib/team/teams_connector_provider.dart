import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../connections/active_connection_firebase_auth.dart';
import '../connections/local_development_connection.dart';
import '../generated/teams/teams.dart';

part 'teams_connector_provider.g.dart';

@riverpod
Future<TeamsConnector> teamsConnector(Ref ref) async {
  final local = ref.watch(localDevelopmentConnectionProvider);
  final auth = await ref.watch(activeConnectionFirebaseAuthProvider.future);
  final dataConnect = FirebaseDataConnect.instanceFor(
    app: auth.app,
    connectorConfig: TeamsConnector.connectorConfig,
    sdkType: CallerSDKType.generated,
  );
  if (local != null) {
    // Port configured in firebase/dataconnect/firebase.json.
    dataConnect.useDataConnectEmulator(local.emulatorHost, 9399);
  }
  return TeamsConnector(dataConnect: dataConnect);
}
