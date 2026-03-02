library dataconnect_generated;
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';







class DashboardConnector {
  

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'asia-northeast1',
    'dashboard',
    'openci-b1b91-service',
  );

  DashboardConnector({required this.dataConnect});
  static DashboardConnector get instance {
    return DashboardConnector(
        dataConnect: FirebaseDataConnect.instanceFor(
            connectorConfig: connectorConfig,
            sdkType: CallerSDKType.generated));
  }

  FirebaseDataConnect dataConnect;
}
