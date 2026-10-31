library logs;

import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

part 'append_build_log.dart';

part 'get_build_logs.dart';

part 'get_build_log_write_state.dart';

part 'get_build_step_write_state.dart';

part 'get_build_log_state.dart';

part 'get_expired_build_logs.dart';

part 'delete_expired_build_logs.dart';

part 'create_build_step.dart';

part 'update_build_step.dart';

String? bigIntToJson(BigInt? value) {
  return value?.toString();
}

BigInt bigIntFromJson(dynamic value) {
  return BigInt.parse(value);
}

class LogsConnector {
  AppendBuildLogVariablesBuilder appendBuildLog({
    required String teamId,
    required String runId,
    required BigInt expectedLastSequence,
    required BigInt sequence,
    required String logId,
    required String source,
    required String stream,
    required String message,
    required Timestamp occurredAt,
  }) {
    return AppendBuildLogVariablesBuilder(
      dataConnect,
      teamId: teamId,
      runId: runId,
      expectedLastSequence: expectedLastSequence,
      sequence: sequence,
      logId: logId,
      source: source,
      stream: stream,
      message: message,
      occurredAt: occurredAt,
    );
  }

  GetBuildLogsVariablesBuilder getBuildLogs({
    required String teamId,
    required String runId,
  }) {
    return GetBuildLogsVariablesBuilder(
      dataConnect,
      teamId: teamId,
      runId: runId,
    );
  }

  GetBuildLogWriteStateVariablesBuilder getBuildLogWriteState({
    required String teamId,
    required String runId,
    required List<String> logIds,
  }) {
    return GetBuildLogWriteStateVariablesBuilder(
      dataConnect,
      teamId: teamId,
      runId: runId,
      logIds: logIds,
    );
  }

  GetBuildStepWriteStateVariablesBuilder getBuildStepWriteState({
    required String teamId,
    required String runId,
    required String stepId,
  }) {
    return GetBuildStepWriteStateVariablesBuilder(
      dataConnect,
      teamId: teamId,
      runId: runId,
      stepId: stepId,
    );
  }

  GetBuildLogStateVariablesBuilder getBuildLogState({
    required String teamId,
    required String jobId,
    required String runId,
  }) {
    return GetBuildLogStateVariablesBuilder(
      dataConnect,
      teamId: teamId,
      jobId: jobId,
      runId: runId,
    );
  }

  GetExpiredBuildLogsVariablesBuilder getExpiredBuildLogs() {
    return GetExpiredBuildLogsVariablesBuilder(
      dataConnect,
    );
  }

  DeleteExpiredBuildLogsVariablesBuilder deleteExpiredBuildLogs({
    required String runId,
    required BigInt throughSequence,
  }) {
    return DeleteExpiredBuildLogsVariablesBuilder(
      dataConnect,
      runId: runId,
      throughSequence: throughSequence,
    );
  }

  CreateBuildStepVariablesBuilder createBuildStep({
    required String teamId,
    required String runId,
    required String stepId,
    required String name,
    required int stepOrder,
  }) {
    return CreateBuildStepVariablesBuilder(
      dataConnect,
      teamId: teamId,
      runId: runId,
      stepId: stepId,
      name: name,
      stepOrder: stepOrder,
    );
  }

  UpdateBuildStepVariablesBuilder updateBuildStep({
    required String teamId,
    required String runId,
    required String stepId,
    required String status,
    required BigInt durationMs,
  }) {
    return UpdateBuildStepVariablesBuilder(
      dataConnect,
      teamId: teamId,
      runId: runId,
      stepId: stepId,
      status: status,
      durationMs: durationMs,
    );
  }

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'asia-northeast1',
    'logs',
    'openci-b1b91-service',
  );

  LogsConnector({required this.dataConnect});
  static LogsConnector get instance {
    CacheSettings cacheSettings = CacheSettings(
      maxAge: Duration(milliseconds: 5000),
      storage: CacheStorage.persistent,
    );

    return LogsConnector(
      dataConnect: FirebaseDataConnect.instanceFor(
        connectorConfig: connectorConfig,

        cacheSettings: cacheSettings,

        sdkType: CallerSDKType.generated,
      ),
    );
  }

  FirebaseDataConnect dataConnect;
}
