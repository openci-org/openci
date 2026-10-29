part of 'billing.dart';

class BindBillingAdmissionRunVariablesBuilder {
  String id;
  String teamId;
  String jobId;
  String workerHost;
  String runId;
  BigInt expectedUsageRevision;
  BigInt atMs;

  final FirebaseDataConnect _dataConnect;
  BindBillingAdmissionRunVariablesBuilder(
    this._dataConnect, {
    required this.id,
    required this.teamId,
    required this.jobId,
    required this.workerHost,
    required this.runId,
    required this.expectedUsageRevision,
    required this.atMs,
  });
  Deserializer<BindBillingAdmissionRunData> dataDeserializer = (dynamic json) =>
      BindBillingAdmissionRunData.fromJson(jsonDecode(json));
  Serializer<BindBillingAdmissionRunVariables> varsSerializer =
      (BindBillingAdmissionRunVariables vars) => jsonEncode(vars.toJson());
  Future<
    OperationResult<
      BindBillingAdmissionRunData,
      BindBillingAdmissionRunVariables
    >
  >
  execute() {
    return ref().execute();
  }

  MutationRef<BindBillingAdmissionRunData, BindBillingAdmissionRunVariables>
  ref() {
    BindBillingAdmissionRunVariables vars = BindBillingAdmissionRunVariables(
      id: id,
      teamId: teamId,
      jobId: jobId,
      workerHost: workerHost,
      runId: runId,
      expectedUsageRevision: expectedUsageRevision,
      atMs: atMs,
    );
    return _dataConnect.mutation(
      "BindBillingAdmissionRun",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class BindBillingAdmissionRunBuildRunInsert {
  final String id;
  BindBillingAdmissionRunBuildRunInsert.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final BindBillingAdmissionRunBuildRunInsert otherTyped =
        other as BindBillingAdmissionRunBuildRunInsert;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  BindBillingAdmissionRunBuildRunInsert({
    required this.id,
  });
}

@immutable
class BindBillingAdmissionRunData {
  final int billingAccount_updateMany;
  final int billingAdmission_updateMany;
  final int buildJob_updateMany;
  final BindBillingAdmissionRunBuildRunInsert buildRun_insert;
  BindBillingAdmissionRunData.fromJson(dynamic json)
    : billingAccount_updateMany = nativeFromJson<int>(
        json['billingAccount_updateMany'],
      ),
      billingAdmission_updateMany = nativeFromJson<int>(
        json['billingAdmission_updateMany'],
      ),
      buildJob_updateMany = nativeFromJson<int>(json['buildJob_updateMany']),
      buildRun_insert = BindBillingAdmissionRunBuildRunInsert.fromJson(
        json['buildRun_insert'],
      );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final BindBillingAdmissionRunData otherTyped =
        other as BindBillingAdmissionRunData;
    return billingAccount_updateMany == otherTyped.billingAccount_updateMany &&
        billingAdmission_updateMany == otherTyped.billingAdmission_updateMany &&
        buildJob_updateMany == otherTyped.buildJob_updateMany &&
        buildRun_insert == otherTyped.buildRun_insert;
  }

  @override
  int get hashCode => Object.hashAll([
    billingAccount_updateMany.hashCode,
    billingAdmission_updateMany.hashCode,
    buildJob_updateMany.hashCode,
    buildRun_insert.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['billingAccount_updateMany'] = nativeToJson<int>(
      billingAccount_updateMany,
    );
    json['billingAdmission_updateMany'] = nativeToJson<int>(
      billingAdmission_updateMany,
    );
    json['buildJob_updateMany'] = nativeToJson<int>(buildJob_updateMany);
    json['buildRun_insert'] = buildRun_insert.toJson();
    return json;
  }

  BindBillingAdmissionRunData({
    required this.billingAccount_updateMany,
    required this.billingAdmission_updateMany,
    required this.buildJob_updateMany,
    required this.buildRun_insert,
  });
}

@immutable
class BindBillingAdmissionRunVariables {
  final String id;
  final String teamId;
  final String jobId;
  final String workerHost;
  final String runId;
  final BigInt expectedUsageRevision;
  final BigInt atMs;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  BindBillingAdmissionRunVariables.fromJson(Map<String, dynamic> json)
    : id = nativeFromJson<String>(json['id']),
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

    final BindBillingAdmissionRunVariables otherTyped =
        other as BindBillingAdmissionRunVariables;
    return id == otherTyped.id &&
        teamId == otherTyped.teamId &&
        jobId == otherTyped.jobId &&
        workerHost == otherTyped.workerHost &&
        runId == otherTyped.runId &&
        expectedUsageRevision == otherTyped.expectedUsageRevision &&
        atMs == otherTyped.atMs;
  }

  @override
  int get hashCode => Object.hashAll([
    id.hashCode,
    teamId.hashCode,
    jobId.hashCode,
    workerHost.hashCode,
    runId.hashCode,
    expectedUsageRevision.hashCode,
    atMs.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['teamId'] = nativeToJson<String>(teamId);
    json['jobId'] = nativeToJson<String>(jobId);
    json['workerHost'] = nativeToJson<String>(workerHost);
    json['runId'] = nativeToJson<String>(runId);
    json['expectedUsageRevision'] = bigIntToJson(expectedUsageRevision);
    json['atMs'] = bigIntToJson(atMs);
    return json;
  }

  BindBillingAdmissionRunVariables({
    required this.id,
    required this.teamId,
    required this.jobId,
    required this.workerHost,
    required this.runId,
    required this.expectedUsageRevision,
    required this.atMs,
  });
}
