library builds;

import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

part 'retry_build_job.dart';

part 'get_build_jobs.dart';

part 'get_build_job.dart';

part 'find_build_jobs.dart';

String? bigIntToJson(BigInt? value) {
  return value?.toString();
}

BigInt bigIntFromJson(dynamic value) {
  return BigInt.parse(value);
}

class BuildsConnector {
  RetryBuildJobVariablesBuilder retryBuildJob({
    required String id,
    required int expectedRetryCount,
  }) {
    return RetryBuildJobVariablesBuilder(
      dataConnect,
      id: id,
      expectedRetryCount: expectedRetryCount,
    );
  }

  GetBuildJobsVariablesBuilder getBuildJobs({
    required String teamId,
  }) {
    return GetBuildJobsVariablesBuilder(
      dataConnect,
      teamId: teamId,
    );
  }

  GetBuildJobVariablesBuilder getBuildJob({
    required String id,
  }) {
    return GetBuildJobVariablesBuilder(
      dataConnect,
      id: id,
    );
  }

  FindBuildJobsVariablesBuilder findBuildJobs({
    required String teamId,
    required String githubBaseUrl,
    required String owner,
    required String repo,
  }) {
    return FindBuildJobsVariablesBuilder(
      dataConnect,
      teamId: teamId,
      githubBaseUrl: githubBaseUrl,
      owner: owner,
      repo: repo,
    );
  }

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'asia-northeast1',
    'builds',
    'openci-b1b91-service',
  );

  BuildsConnector({required this.dataConnect});
  static BuildsConnector get instance {
    CacheSettings cacheSettings = CacheSettings(
      maxAge: Duration(milliseconds: 5000),
      storage: CacheStorage.persistent,
    );

    return BuildsConnector(
      dataConnect: FirebaseDataConnect.instanceFor(
        connectorConfig: connectorConfig,

        cacheSettings: cacheSettings,

        sdkType: CallerSDKType.generated,
      ),
    );
  }

  FirebaseDataConnect dataConnect;
}
