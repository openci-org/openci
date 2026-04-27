import 'package:dashboard/generated/dataconnect/default.dart';
import 'package:dashboard/firebase/firebase_config_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart';

export 'package:dashboard/generated/dataconnect/default.dart';

DefaultConnector? _selfHostedConnector;

DefaultConnector get dataConnector {
  return _selfHostedConnector ?? DefaultConnector.instance;
}

String dataConnectServiceIdForConfig(SelfHostedConfig? selfHostedConfig) {
  final configuredServiceId = selfHostedConfig?.dataConnectServiceId.trim();
  if (configuredServiceId == null || configuredServiceId.isEmpty) {
    return 'openci';
  }
  if (configuredServiceId == '${selfHostedConfig!.projectId}-service') {
    return 'openci';
  }
  return configuredServiceId;
}

void initDataConnector(SelfHostedConfig? selfHostedConfig) {
  final serviceId = dataConnectServiceIdForConfig(selfHostedConfig);

  // Keep this visible while self-hosted setup is being configured.
  // It is the quickest way to confirm which backend the generated SDK targets.
  // ignore: avoid_print
  print('[OpenCI] Data Connect service ID: $serviceId');

  DefaultConnector.connectorConfig = ConnectorConfig(
    'asia-northeast1',
    'default',
    serviceId,
  );

  if (selfHostedConfig == null) {
    _selfHostedConnector = null;
    return;
  }

  // FirebaseDataConnect.instanceFor always attaches FirebaseAppCheck.
  // Self-hosted projects do not require App Check by default, so build the
  // instance directly to avoid blocking on App Check token exchange.
  // ignore: invalid_use_of_visible_for_testing_member
  final dataConnect = FirebaseDataConnect(
    app: Firebase.app(),
    connectorConfig: DefaultConnector.connectorConfig,
    auth: FirebaseAuth.instance,
    sdkType: CallerSDKType.generated,
  );
  _selfHostedConnector = DefaultConnector(dataConnect: dataConnect);
}

DateTime dateTimeFromDataConnect(Timestamp timestamp) => timestamp.toDateTime();

AnyValue anyValue(Object? value) => AnyValue(value);

Map<String, Object?> anyMap(AnyValue? value) {
  final raw = value?.value;
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

List<Object?> anyList(AnyValue? value) {
  final raw = value?.value;
  return raw is List ? raw : const [];
}
