import 'package:firebase_data_connect/firebase_data_connect.dart';

/// Each deployment uses the Firebase project's default service name.
/// Local emulators keep the checked-in schema's service name.
ConnectorConfig projectConnectorConfig(
  ConnectorConfig generated,
  String projectId,
) => ConnectorConfig(
  generated.location,
  generated.connector,
  projectId.startsWith('demo-') ? generated.serviceId : '$projectId-service',
);
