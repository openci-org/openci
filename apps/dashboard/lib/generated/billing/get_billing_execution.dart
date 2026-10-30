part of 'billing.dart';

class GetBillingExecutionVariablesBuilder {
  String teamId;
  String runId;

  final FirebaseDataConnect _dataConnect;
  GetBillingExecutionVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.runId,
  });
  Deserializer<GetBillingExecutionData> dataDeserializer = (dynamic json) =>
      GetBillingExecutionData.fromJson(jsonDecode(json));
  Serializer<GetBillingExecutionVariables> varsSerializer =
      (GetBillingExecutionVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetBillingExecutionData, GetBillingExecutionVariables>>
  execute() {
    return ref().execute();
  }

  QueryRef<GetBillingExecutionData, GetBillingExecutionVariables> ref() {
    GetBillingExecutionVariables vars = GetBillingExecutionVariables(
      teamId: teamId,
      runId: runId,
    );
    return _dataConnect.query(
      "GetBillingExecution",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetBillingExecutionBillingAccount {
  final BigInt usageRevision;
  GetBillingExecutionBillingAccount.fromJson(dynamic json)
    : usageRevision = bigIntFromJson(json['usageRevision']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingExecutionBillingAccount otherTyped =
        other as GetBillingExecutionBillingAccount;
    return usageRevision == otherTyped.usageRevision;
  }

  @override
  int get hashCode => usageRevision.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['usageRevision'] = bigIntToJson(usageRevision);
    return json;
  }

  GetBillingExecutionBillingAccount({
    required this.usageRevision,
  });
}

@immutable
class GetBillingExecutionBillingExecution {
  final String runId;
  final String teamId;
  final String jobId;
  final String workerHost;
  final String periodId;
  final BigInt startedAtMs;
  final BigInt observedAtMs;
  final BigInt leaseUntilMs;
  final BigInt? finishedAtMs;
  final String? outcome;
  final bool measurementIncomplete;
  GetBillingExecutionBillingExecution.fromJson(dynamic json)
    : runId = nativeFromJson<String>(json['runId']),
      teamId = nativeFromJson<String>(json['teamId']),
      jobId = nativeFromJson<String>(json['jobId']),
      workerHost = nativeFromJson<String>(json['workerHost']),
      periodId = nativeFromJson<String>(json['periodId']),
      startedAtMs = bigIntFromJson(json['startedAtMs']),
      observedAtMs = bigIntFromJson(json['observedAtMs']),
      leaseUntilMs = bigIntFromJson(json['leaseUntilMs']),
      finishedAtMs = json['finishedAtMs'] == null
          ? null
          : bigIntFromJson(json['finishedAtMs']),
      outcome = json['outcome'] == null
          ? null
          : nativeFromJson<String>(json['outcome']),
      measurementIncomplete = nativeFromJson<bool>(
        json['measurementIncomplete'],
      );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingExecutionBillingExecution otherTyped =
        other as GetBillingExecutionBillingExecution;
    return runId == otherTyped.runId &&
        teamId == otherTyped.teamId &&
        jobId == otherTyped.jobId &&
        workerHost == otherTyped.workerHost &&
        periodId == otherTyped.periodId &&
        startedAtMs == otherTyped.startedAtMs &&
        observedAtMs == otherTyped.observedAtMs &&
        leaseUntilMs == otherTyped.leaseUntilMs &&
        finishedAtMs == otherTyped.finishedAtMs &&
        outcome == otherTyped.outcome &&
        measurementIncomplete == otherTyped.measurementIncomplete;
  }

  @override
  int get hashCode => Object.hashAll([
    runId.hashCode,
    teamId.hashCode,
    jobId.hashCode,
    workerHost.hashCode,
    periodId.hashCode,
    startedAtMs.hashCode,
    observedAtMs.hashCode,
    leaseUntilMs.hashCode,
    finishedAtMs.hashCode,
    outcome.hashCode,
    measurementIncomplete.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['runId'] = nativeToJson<String>(runId);
    json['teamId'] = nativeToJson<String>(teamId);
    json['jobId'] = nativeToJson<String>(jobId);
    json['workerHost'] = nativeToJson<String>(workerHost);
    json['periodId'] = nativeToJson<String>(periodId);
    json['startedAtMs'] = bigIntToJson(startedAtMs);
    json['observedAtMs'] = bigIntToJson(observedAtMs);
    json['leaseUntilMs'] = bigIntToJson(leaseUntilMs);
    if (finishedAtMs != null) {
      json['finishedAtMs'] = bigIntToJson(finishedAtMs);
    }
    if (outcome != null) {
      json['outcome'] = nativeToJson<String?>(outcome);
    }
    json['measurementIncomplete'] = nativeToJson<bool>(measurementIncomplete);
    return json;
  }

  GetBillingExecutionBillingExecution({
    required this.runId,
    required this.teamId,
    required this.jobId,
    required this.workerHost,
    required this.periodId,
    required this.startedAtMs,
    required this.observedAtMs,
    required this.leaseUntilMs,
    this.finishedAtMs,
    this.outcome,
    required this.measurementIncomplete,
  });
}

@immutable
class GetBillingExecutionData {
  final GetBillingExecutionBillingAccount? billingAccount;
  final GetBillingExecutionBillingExecution? billingExecution;
  GetBillingExecutionData.fromJson(dynamic json)
    : billingAccount = json['billingAccount'] == null
          ? null
          : GetBillingExecutionBillingAccount.fromJson(json['billingAccount']),
      billingExecution = json['billingExecution'] == null
          ? null
          : GetBillingExecutionBillingExecution.fromJson(
              json['billingExecution'],
            );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingExecutionData otherTyped = other as GetBillingExecutionData;
    return billingAccount == otherTyped.billingAccount &&
        billingExecution == otherTyped.billingExecution;
  }

  @override
  int get hashCode =>
      Object.hashAll([billingAccount.hashCode, billingExecution.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (billingAccount != null) {
      json['billingAccount'] = billingAccount!.toJson();
    }
    if (billingExecution != null) {
      json['billingExecution'] = billingExecution!.toJson();
    }
    return json;
  }

  GetBillingExecutionData({
    this.billingAccount,
    this.billingExecution,
  });
}

@immutable
class GetBillingExecutionVariables {
  final String teamId;
  final String runId;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetBillingExecutionVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']),
      runId = nativeFromJson<String>(json['runId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingExecutionVariables otherTyped =
        other as GetBillingExecutionVariables;
    return teamId == otherTyped.teamId && runId == otherTyped.runId;
  }

  @override
  int get hashCode => Object.hashAll([teamId.hashCode, runId.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['runId'] = nativeToJson<String>(runId);
    return json;
  }

  GetBillingExecutionVariables({
    required this.teamId,
    required this.runId,
  });
}
