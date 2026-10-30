import 'package:dashboard/connections/active_connection_firebase_auth.dart';
import 'package:dashboard/connections/local_development_connection.dart';
import 'package:dashboard/generated/teams/teams.dart';
import 'package:dashboard/team/teams_connector_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Firebase extends FirebasePlatform {
  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async => FirebaseAppPlatform(name!, options!);
}

void main() {
  var nextApp = 0;
  late FirebaseAuth auth;
  late ProviderContainer container;
  LocalDevelopmentConnection? local;

  Future<FirebaseAuth> createAuth(String projectId) async {
    final app = await Firebase.initializeApp(
      name: 'teams-test-${nextApp++}',
      options: FirebaseOptions(
        apiKey: 'test-key',
        appId: 'test-app',
        messagingSenderId: '123',
        projectId: projectId,
      ),
    );
    return FirebaseAuth.instanceFor(app: app);
  }

  setUp(() async {
    final previous = Firebase.delegatePackingProperty;
    Firebase.delegatePackingProperty = _Firebase();
    addTearDown(() => Firebase.delegatePackingProperty = previous);
    addTearDown(FirebaseDataConnect.cachedInstances.clear);
    auth = await createAuth('selected-project');
    local = null;
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        activeConnectionFirebaseAuthProvider.overrideWith((ref) => auth),
        localDevelopmentConnectionProvider.overrideWith((ref) => local),
      ],
    );
    container.listen(teamsConnectorProvider, (_, _) {});
  });

  test('uses the selected Firebase app and its authentication', () async {
    final connector = await container.read(teamsConnectorProvider.future);

    expect(connector.dataConnect.app, same(auth.app));
    expect(connector.dataConnect.auth, same(auth));
    expect(connector.dataConnect.options.projectId, 'selected-project');
    expect(
      connector.dataConnect.connectorConfig,
      TeamsConnector.connectorConfig,
    );
    expect(connector.dataConnect.transportOptions, isNull);
  });

  test(
    'recreates the connector when the selected connection changes',
    () async {
      final previous = await container.read(teamsConnectorProvider.future);
      auth = await createAuth('another-project');
      container.invalidate(activeConnectionFirebaseAuthProvider);

      final current = await container.read(teamsConnectorProvider.future);

      expect(current.dataConnect, isNot(same(previous.dataConnect)));
      expect(current.dataConnect.app, same(auth.app));
      expect(current.dataConnect.auth, same(auth));
      expect(current.dataConnect.options.projectId, 'another-project');
    },
  );

  test('routes local development to the SQL Connect emulator', () async {
    auth = await createAuth('demo-openci');
    local = LocalDevelopmentConnection.parse(
      mode: 'true',
      apiUrl: 'http://localhost:8080',
      emulatorHost: 'emulator.test',
      emulatorPort: '9099',
    );
    container.invalidate(activeConnectionFirebaseAuthProvider);
    container.invalidate(localDevelopmentConnectionProvider);

    final connector = await container.read(teamsConnectorProvider.future);

    expect(connector.dataConnect.app.options.projectId, 'demo-openci');
    expect(connector.dataConnect.transportOptions?.host, 'emulator.test');
    expect(connector.dataConnect.transportOptions?.port, 9399);
    expect(connector.dataConnect.transportOptions?.isSecure, isFalse);
  });
}
