part of 'billing.dart';

class HeartbeatBillingExecutionVariablesBuilder {
  String teamId;
  String jobId;
  String workerHost;
  String runId;
  BigInt expectedUsageRevision;
  BigInt atMs;

  final FirebaseDataConnect _dataConnect;
  HeartbeatBillingExecutionVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.jobId,
    required this.workerHost,
    required this.runId,
    required this.expectedUsageRevision,
    required this.atMs,
  });
  Deserializer<HeartbeatBillingExecutionData> dataDeserializer =
      (dynamic json) =>
          HeartbeatBillingExecutionData.fromJson(jsonDecode(json));
  Serializer<HeartbeatBillingExecutionVariables> varsSerializer =
      (HeartbeatBillingExecutionVariables vars) => jsonEncode(vars.toJson());
  Future<
    OperationResult<
      HeartbeatBillingExecutionData,
      HeartbeatBillingExecutionVariables
    >
  >
  execute() {
    return ref().execute();
  }

  MutationRef<HeartbeatBillingExecutionData, HeartbeatBillingExecutionVariables>
  ref() {
    HeartbeatBillingExecutionVariables vars =
        HeartbeatBillingExecutionVariables(
          teamId: teamId,
          jobId: jobId,
          workerHost: workerHost,
          runId: runId,
          expectedUsageRevision: expectedUsageRevision,
          atMs: atMs,
        );
    return _dataConnect.mutation(
      "HeartbeatBillingExecution",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class HeartbeatBillingExecutionBillingExecutionUpdate {
  final String runId;
  HeartbeatBillingExecutionBillingExecutionUpdate.fromJson(dynamic json)
    : runId = nativeFromJson<String>(json['runId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final HeartbeatBillingExecutionBillingExecutionUpdate otherTyped =
        other as HeartbeatBillingExecutionBillingExecutionUpdate;
    return runId == otherTyped.runId;
  }

  @override
  int get hashCode => runId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['runId'] = nativeToJson<String>(runId);
    return json;
  }

  HeartbeatBillingExecutionBillingExecutionUpdate({
    required this.runId,
  });
}

@immutable
class HeartbeatBillingExecutionData {
  final int billingAccount_updateMany;
  final int buildJob_updateMany;
  final HeartbeatBillingExecutionBillingExecutionUpdate?
  billingExecution_update;
  HeartbeatBillingExecutionData.fromJson(dynamic json)
    : billingAccount_updateMany = nativeFromJson<int>(
        json['billingAccount_updateMany'],
      ),
      buildJob_updateMany = nativeFromJson<int>(json['buildJob_updateMany']),
      billingExecution_update = json['billingExecution_update'] == null
          ? null
          : HeartbeatBillingExecutionBillingExecutionUpdate.fromJson(
              json['billingExecution_update'],
            );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final HeartbeatBillingExecutionData otherTyped =
        other as HeartbeatBillingExecutionData;
    return billingAccount_updateMany == otherTyped.billingAccount_updateMany &&
        buildJob_updateMany == otherTyped.buildJob_updateMany &&
        billingExecution_update == otherTyped.billingExecution_update;
  }

  @override
  int get hashCode => Object.hashAll([
    billingAccount_updateMany.hashCode,
    buildJob_updateMany.hashCode,
    billingExecution_update.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['billingAccount_updateMany'] = nativeToJson<int>(
      billingAccount_updateMany,
    );
    json['buildJob_updateMany'] = nativeToJson<int>(buildJob_updateMany);
    if (billingExecution_update != null) {
      json['billingExecution_update'] = billingExecution_update!.toJson();
    }
    return json;
  }

  HeartbeatBillingExecutionData({
    required this.billingAccount_updateMany,
    required this.buildJob_updateMany,
    this.billingExecution_update,
  });
}

@immutable
class HeartbeatBillingExecutionVariables {
  final String teamId;
  final String jobId;
  final String workerHost;
  final String runId;
  final BigInt expectedUsageRevision;
  final BigInt atMs;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  HeartbeatBillingExecutionVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']),
      jobId = nativeFromJson<String>(json['jobId']),
      workerHost = nativeFromJson<String>(json['workerHost']),
      runId = nativeFromJson<String>(json['runId']),
      expectedUsageRevision = bigIntFromJson(json['expectedUsageRevision']),
      atMs = bigIntFromJson(json['atMs']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final HeartbeatBillingExecutionVariables otherTyped =
        other as HeartbeatBillingExecutionVariables;
    return teamId == otherTyped.teamId &&
        jobId == otherTyped.jobId &&
        workerHost == otherTyped.workerHost &&
        runId == otherTyped.runId &&
        expectedUsageRevision == otherTyped.expectedUsageRevision &&
        atMs == otherTyped.atMs;
  }

  @override
  int get hashCode => Object.hashAll([
    teamId.hashCode,
    jobId.hashCode,
    workerHost.hashCode,
    runId.hashCode,
    expectedUsageRevision.hashCode,
    atMs.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['jobId'] = nativeToJson<String>(jobId);
    json['workerHost'] = nativeToJson<String>(workerHost);
    json['runId'] = nativeToJson<String>(runId);
    json['expectedUsageRevision'] = bigIntToJson(expectedUsageRevision);
    json['atMs'] = bigIntToJson(atMs);
    return json;
  }

  HeartbeatBillingExecutionVariables({
    required this.teamId,
    required this.jobId,
    required this.workerHost,
    required this.runId,
    required this.expectedUsageRevision,
    required this.atMs,
  });
}
