import 'package:dashboard/firebase/data_connect_config.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'each Firebase project selects its own service without mutating the SDK',
    () {
      final generated = ConnectorConfig(
        'asia-northeast1',
        'teams',
        'openci-b1b91-service',
      );
      for (final project in ['openci-b1b91', 'openci-self-hosted-example']) {
        final config = projectConnectorConfig(generated, project);
        expect(config.serviceId, '$project-service');
        expect(config.connector, 'teams');
        expect(config.location, 'asia-northeast1');
      }
      expect(generated.serviceId, 'openci-b1b91-service');
      expect(
        projectConnectorConfig(generated, 'demo-openci').serviceId,
        generated.serviceId,
      );
    },
  );
}
