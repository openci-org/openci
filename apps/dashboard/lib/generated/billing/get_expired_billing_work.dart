part of 'billing.dart';

class GetExpiredBillingWorkVariablesBuilder {
  BigInt atMs;

  final FirebaseDataConnect _dataConnect;
  GetExpiredBillingWorkVariablesBuilder(
    this._dataConnect, {
    required this.atMs,
  });
  Deserializer<GetExpiredBillingWorkData> dataDeserializer = (dynamic json) =>
      GetExpiredBillingWorkData.fromJson(jsonDecode(json));
  Serializer<GetExpiredBillingWorkVariables> varsSerializer =
      (GetExpiredBillingWorkVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetExpiredBillingWorkData, GetExpiredBillingWorkVariables>>
  execute() {
    return ref().execute();
  }

  QueryRef<GetExpiredBillingWorkData, GetExpiredBillingWorkVariables> ref() {
    GetExpiredBillingWorkVariables vars = GetExpiredBillingWorkVariables(
      atMs: atMs,
    );
    return _dataConnect.query(
      "GetExpiredBillingWork",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetExpiredBillingWorkBillingExecutions {
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
  GetExpiredBillingWorkBillingExecutions.fromJson(dynamic json)
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

    final GetExpiredBillingWorkBillingExecutions otherTyped =
        other as GetExpiredBillingWorkBillingExecutions;
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

  GetExpiredBillingWorkBillingExecutions({
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
class GetExpiredBillingWorkData {
  final List<GetExpiredBillingWorkBillingExecutions> billingExecutions;
  final List<AnyValue>? admissions;
  GetExpiredBillingWorkData.fromJson(dynamic json)
    : billingExecutions = (json['billingExecutions'] as List<dynamic>)
          .map((e) => GetExpiredBillingWorkBillingExecutions.fromJson(e))
          .toList(),
      admissions = json['admissions'] == null
          ? null
          : (json['admissions'] as List<dynamic>)
                .map((e) => AnyValue.fromJson(e))
                .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetExpiredBillingWorkData otherTyped =
        other as GetExpiredBillingWorkData;
    return billingExecutions == otherTyped.billingExecutions &&
        admissions == otherTyped.admissions;
  }

  @override
  int get hashCode =>
      Object.hashAll([billingExecutions.hashCode, admissions.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['billingExecutions'] = billingExecutions
        .map((e) => e.toJson())
        .toList();
    if (admissions != null) {
      json['admissions'] = admissions?.map((e) => e!.toJson()).toList();
    }
    return json;
  }

  GetExpiredBillingWorkData({
    required this.billingExecutions,
    this.admissions,
  });
}

@immutable
class GetExpiredBillingWorkVariables {
  final BigInt atMs;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetExpiredBillingWorkVariables.fromJson(Map<String, dynamic> json)
    : atMs = bigIntFromJson(json['atMs']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetExpiredBillingWorkVariables otherTyped =
        other as GetExpiredBillingWorkVariables;
    return atMs == otherTyped.atMs;
  }

  @override
  int get hashCode => atMs.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['atMs'] = bigIntToJson(atMs);
    return json;
  }

  GetExpiredBillingWorkVariables({
    required this.atMs,
  });
}
