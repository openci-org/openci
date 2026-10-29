part of 'billing.dart';

class FinishBillingExecutionVariablesBuilder {
  String teamId;
  String jobId;
  String workerHost;
  String runId;
  BigInt expectedUsageRevision;
  BigInt atMs;
  String outcome;

  final FirebaseDataConnect _dataConnect;
  FinishBillingExecutionVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.jobId,
    required this.workerHost,
    required this.runId,
    required this.expectedUsageRevision,
    required this.atMs,
    required this.outcome,
  });
  Deserializer<FinishBillingExecutionData> dataDeserializer = (dynamic json) =>
      FinishBillingExecutionData.fromJson(jsonDecode(json));
  Serializer<FinishBillingExecutionVariables> varsSerializer =
      (FinishBillingExecutionVariables vars) => jsonEncode(vars.toJson());
  Future<
    OperationResult<FinishBillingExecutionData, FinishBillingExecutionVariables>
  >
  execute() {
    return ref().execute();
  }

  MutationRef<FinishBillingExecutionData, FinishBillingExecutionVariables>
  ref() {
    FinishBillingExecutionVariables vars = FinishBillingExecutionVariables(
      teamId: teamId,
      jobId: jobId,
      workerHost: workerHost,
      runId: runId,
      expectedUsageRevision: expectedUsageRevision,
      atMs: atMs,
      outcome: outcome,
    );
    return _dataConnect.mutation(
      "FinishBillingExecution",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class FinishBillingExecutionBillingExecutionUpdate {
  final String runId;
  FinishBillingExecutionBillingExecutionUpdate.fromJson(dynamic json)
    : runId = nativeFromJson<String>(json['runId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final FinishBillingExecutionBillingExecutionUpdate otherTyped =
        other as FinishBillingExecutionBillingExecutionUpdate;
    return runId == otherTyped.runId;
  }

  @override
  int get hashCode => runId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['runId'] = nativeToJson<String>(runId);
    return json;
  }

  FinishBillingExecutionBillingExecutionUpdate({
    required this.runId,
  });
}

@immutable
class FinishBillingExecutionData {
  final int billingAccount_updateMany;
  final int buildJob_updateMany;
  final FinishBillingExecutionBillingExecutionUpdate? billingExecution_update;
  final int billingAdmission_updateMany;
  FinishBillingExecutionData.fromJson(dynamic json)
    : billingAccount_updateMany = nativeFromJson<int>(
        json['billingAccount_updateMany'],
      ),
      buildJob_updateMany = nativeFromJson<int>(json['buildJob_updateMany']),
      billingExecution_update = json['billingExecution_update'] == null
          ? null
          : FinishBillingExecutionBillingExecutionUpdate.fromJson(
              json['billingExecution_update'],
            ),
      billingAdmission_updateMany = nativeFromJson<int>(
        json['billingAdmission_updateMany'],
      );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final FinishBillingExecutionData otherTyped =
        other as FinishBillingExecutionData;
    return billingAccount_updateMany == otherTyped.billingAccount_updateMany &&
        buildJob_updateMany == otherTyped.buildJob_updateMany &&
        billingExecution_update == otherTyped.billingExecution_update &&
        billingAdmission_updateMany == otherTyped.billingAdmission_updateMany;
  }

  @override
  int get hashCode => Object.hashAll([
    billingAccount_updateMany.hashCode,
    buildJob_updateMany.hashCode,
    billingExecution_update.hashCode,
    billingAdmission_updateMany.hashCode,
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
    json['billingAdmission_updateMany'] = nativeToJson<int>(
      billingAdmission_updateMany,
    );
    return json;
  }

  FinishBillingExecutionData({
    required this.billingAccount_updateMany,
    required this.buildJob_updateMany,
    this.billingExecution_update,
    required this.billingAdmission_updateMany,
  });
}

@immutable
class FinishBillingExecutionVariables {
  final String teamId;
  final String jobId;
  final String workerHost;
  final String runId;
  final BigInt expectedUsageRevision;
  final BigInt atMs;
  final String outcome;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  FinishBillingExecutionVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']),
      jobId = nativeFromJson<String>(json['jobId']),
      workerHost = nativeFromJson<String>(json['workerHost']),
      runId = nativeFromJson<String>(json['runId']),
      expectedUsageRevision = bigIntFromJson(json['expectedUsageRevision']),
      atMs = bigIntFromJson(json['atMs']),
      outcome = nativeFromJson<String>(json['outcome']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final FinishBillingExecutionVariables otherTyped =
        other as FinishBillingExecutionVariables;
    return teamId == otherTyped.teamId &&
        jobId == otherTyped.jobId &&
        workerHost == otherTyped.workerHost &&
        runId == otherTyped.runId &&
        expectedUsageRevision == otherTyped.expectedUsageRevision &&
        atMs == otherTyped.atMs &&
        outcome == otherTyped.outcome;
  }

  @override
  int get hashCode => Object.hashAll([
    teamId.hashCode,
    jobId.hashCode,
    workerHost.hashCode,
    runId.hashCode,
    expectedUsageRevision.hashCode,
    atMs.hashCode,
    outcome.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['jobId'] = nativeToJson<String>(jobId);
    json['workerHost'] = nativeToJson<String>(workerHost);
    json['runId'] = nativeToJson<String>(runId);
    json['expectedUsageRevision'] = bigIntToJson(expectedUsageRevision);
    json['atMs'] = bigIntToJson(atMs);
    json['outcome'] = nativeToJson<String>(outcome);
    return json;
  }

  FinishBillingExecutionVariables({
    required this.teamId,
    required this.jobId,
    required this.workerHost,
    required this.runId,
    required this.expectedUsageRevision,
    required this.atMs,
    required this.outcome,
  });
}
