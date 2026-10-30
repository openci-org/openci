part of 'billing.dart';

class StartBillingExecutionVariablesBuilder {
  String admissionId;
  String teamId;
  String jobId;
  String workerHost;
  String runId;
  BigInt expectedUsageRevision;
  BigInt atMs;

  final FirebaseDataConnect _dataConnect;
  StartBillingExecutionVariablesBuilder(
    this._dataConnect, {
    required this.admissionId,
    required this.teamId,
    required this.jobId,
    required this.workerHost,
    required this.runId,
    required this.expectedUsageRevision,
    required this.atMs,
  });
  Deserializer<StartBillingExecutionData> dataDeserializer = (dynamic json) =>
      StartBillingExecutionData.fromJson(jsonDecode(json));
  Serializer<StartBillingExecutionVariables> varsSerializer =
      (StartBillingExecutionVariables vars) => jsonEncode(vars.toJson());
  Future<
    OperationResult<StartBillingExecutionData, StartBillingExecutionVariables>
  >
  execute() {
    return ref().execute();
  }

  MutationRef<StartBillingExecutionData, StartBillingExecutionVariables> ref() {
    StartBillingExecutionVariables vars = StartBillingExecutionVariables(
      admissionId: admissionId,
      teamId: teamId,
      jobId: jobId,
      workerHost: workerHost,
      runId: runId,
      expectedUsageRevision: expectedUsageRevision,
      atMs: atMs,
    );
    return _dataConnect.mutation(
      "StartBillingExecution",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class StartBillingExecutionBillingExecutionInsert {
  final String runId;
  StartBillingExecutionBillingExecutionInsert.fromJson(dynamic json)
    : runId = nativeFromJson<String>(json['runId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final StartBillingExecutionBillingExecutionInsert otherTyped =
        other as StartBillingExecutionBillingExecutionInsert;
    return runId == otherTyped.runId;
  }

  @override
  int get hashCode => runId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['runId'] = nativeToJson<String>(runId);
    return json;
  }

  StartBillingExecutionBillingExecutionInsert({
    required this.runId,
  });
}

@immutable
class StartBillingExecutionData {
  final int billingAccount_updateMany;
  final int buildJob_updateMany;
  final StartBillingExecutionBillingExecutionInsert billingExecution_insert;
  StartBillingExecutionData.fromJson(dynamic json)
    : billingAccount_updateMany = nativeFromJson<int>(
        json['billingAccount_updateMany'],
      ),
      buildJob_updateMany = nativeFromJson<int>(json['buildJob_updateMany']),
      billingExecution_insert =
          StartBillingExecutionBillingExecutionInsert.fromJson(
            json['billingExecution_insert'],
          );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final StartBillingExecutionData otherTyped =
        other as StartBillingExecutionData;
    return billingAccount_updateMany == otherTyped.billingAccount_updateMany &&
        buildJob_updateMany == otherTyped.buildJob_updateMany &&
        billingExecution_insert == otherTyped.billingExecution_insert;
  }

  @override
  int get hashCode => Object.hashAll([
    billingAccount_updateMany.hashCode,
    buildJob_updateMany.hashCode,
    billingExecution_insert.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['billingAccount_updateMany'] = nativeToJson<int>(
      billingAccount_updateMany,
    );
    json['buildJob_updateMany'] = nativeToJson<int>(buildJob_updateMany);
    json['billingExecution_insert'] = billingExecution_insert.toJson();
    return json;
  }

  StartBillingExecutionData({
    required this.billingAccount_updateMany,
    required this.buildJob_updateMany,
    required this.billingExecution_insert,
  });
}

@immutable
class StartBillingExecutionVariables {
  final String admissionId;
  final String teamId;
  final String jobId;
  final String workerHost;
  final String runId;
  final BigInt expectedUsageRevision;
  final BigInt atMs;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  StartBillingExecutionVariables.fromJson(Map<String, dynamic> json)
    : admissionId = nativeFromJson<String>(json['admissionId']),
      teamId = nativeFromJson<String>(json['teamId']),
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

    final StartBillingExecutionVariables otherTyped =
        other as StartBillingExecutionVariables;
    return admissionId == otherTyped.admissionId &&
        teamId == otherTyped.teamId &&
        jobId == otherTyped.jobId &&
        workerHost == otherTyped.workerHost &&
        runId == otherTyped.runId &&
        expectedUsageRevision == otherTyped.expectedUsageRevision &&
        atMs == otherTyped.atMs;
  }

  @override
  int get hashCode => Object.hashAll([
    admissionId.hashCode,
    teamId.hashCode,
    jobId.hashCode,
    workerHost.hashCode,
    runId.hashCode,
    expectedUsageRevision.hashCode,
    atMs.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['admissionId'] = nativeToJson<String>(admissionId);
    json['teamId'] = nativeToJson<String>(teamId);
    json['jobId'] = nativeToJson<String>(jobId);
    json['workerHost'] = nativeToJson<String>(workerHost);
    json['runId'] = nativeToJson<String>(runId);
    json['expectedUsageRevision'] = bigIntToJson(expectedUsageRevision);
    json['atMs'] = bigIntToJson(atMs);
    return json;
  }

  StartBillingExecutionVariables({
    required this.admissionId,
    required this.teamId,
    required this.jobId,
    required this.workerHost,
    required this.runId,
    required this.expectedUsageRevision,
    required this.atMs,
  });
}
