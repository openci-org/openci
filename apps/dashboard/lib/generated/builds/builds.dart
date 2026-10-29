library builds;

import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

part 'get_build_jobs.dart';

String? bigIntToJson(BigInt? value) {
  return value?.toString();
}

BigInt bigIntFromJson(dynamic value) {
  return BigInt.parse(value);
}

class BuildsConnector {
  GetBuildJobsVariablesBuilder getBuildJobs({
    required String teamId,
  }) {
    return GetBuildJobsVariablesBuilder(
      dataConnect,
      teamId: teamId,
    );
  }

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'asia-northeast1',
    'builds',
    'openci-b1b91-service',
  );

  BuildsConnector({required this.dataConnect});
  static BuildsConnector get instance {
    return BuildsConnector(
      dataConnect: FirebaseDataConnect.instanceFor(
        connectorConfig: connectorConfig,

        sdkType: CallerSDKType.generated,
      ),
    );
  }

  FirebaseDataConnect dataConnect;
}
