part of 'billing.dart';

class GetBillingAdmissionVariablesBuilder {
  String teamId;
  String id;

  final FirebaseDataConnect _dataConnect;
  GetBillingAdmissionVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.id,
  });
  Deserializer<GetBillingAdmissionData> dataDeserializer = (dynamic json) =>
      GetBillingAdmissionData.fromJson(jsonDecode(json));
  Serializer<GetBillingAdmissionVariables> varsSerializer =
      (GetBillingAdmissionVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetBillingAdmissionData, GetBillingAdmissionVariables>>
  execute() {
    return ref().execute();
  }

  QueryRef<GetBillingAdmissionData, GetBillingAdmissionVariables> ref() {
    GetBillingAdmissionVariables vars = GetBillingAdmissionVariables(
      teamId: teamId,
      id: id,
    );
    return _dataConnect.query(
      "GetBillingAdmission",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetBillingAdmissionBillingAccount {
  final BigInt usageRevision;
  GetBillingAdmissionBillingAccount.fromJson(dynamic json)
    : usageRevision = bigIntFromJson(json['usageRevision']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingAdmissionBillingAccount otherTyped =
        other as GetBillingAdmissionBillingAccount;
    return usageRevision == otherTyped.usageRevision;
  }

  @override
  int get hashCode => usageRevision.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['usageRevision'] = bigIntToJson(usageRevision);
    return json;
  }

  GetBillingAdmissionBillingAccount({
    required this.usageRevision,
  });
}

@immutable
class GetBillingAdmissionBillingAdmission {
  final String id;
  final String teamId;
  final String jobId;
  final String workerHost;
  final String periodId;
  final BigInt claimedAtMs;
  final BigInt startByMs;
  final BigInt reservedMillis;
  final String? runId;
  final BigInt? closedAtMs;
  final String? openJobId;
  GetBillingAdmissionBillingAdmission.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']),
      teamId = nativeFromJson<String>(json['teamId']),
      jobId = nativeFromJson<String>(json['jobId']),
      workerHost = nativeFromJson<String>(json['workerHost']),
      periodId = nativeFromJson<String>(json['periodId']),
      claimedAtMs = bigIntFromJson(json['claimedAtMs']),
      startByMs = bigIntFromJson(json['startByMs']),
      reservedMillis = bigIntFromJson(json['reservedMillis']),
      runId = json['runId'] == null
          ? null
          : nativeFromJson<String>(json['runId']),
      closedAtMs = json['closedAtMs'] == null
          ? null
          : bigIntFromJson(json['closedAtMs']),
      openJobId = json['openJobId'] == null
          ? null
          : nativeFromJson<String>(json['openJobId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingAdmissionBillingAdmission otherTyped =
        other as GetBillingAdmissionBillingAdmission;
    return id == otherTyped.id &&
        teamId == otherTyped.teamId &&
        jobId == otherTyped.jobId &&
        workerHost == otherTyped.workerHost &&
        periodId == otherTyped.periodId &&
        claimedAtMs == otherTyped.claimedAtMs &&
        startByMs == otherTyped.startByMs &&
        reservedMillis == otherTyped.reservedMillis &&
        runId == otherTyped.runId &&
        closedAtMs == otherTyped.closedAtMs &&
        openJobId == otherTyped.openJobId;
  }

  @override
  int get hashCode => Object.hashAll([
    id.hashCode,
    teamId.hashCode,
    jobId.hashCode,
    workerHost.hashCode,
    periodId.hashCode,
    claimedAtMs.hashCode,
    startByMs.hashCode,
    reservedMillis.hashCode,
    runId.hashCode,
    closedAtMs.hashCode,
    openJobId.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['teamId'] = nativeToJson<String>(teamId);
    json['jobId'] = nativeToJson<String>(jobId);
    json['workerHost'] = nativeToJson<String>(workerHost);
    json['periodId'] = nativeToJson<String>(periodId);
    json['claimedAtMs'] = bigIntToJson(claimedAtMs);
    json['startByMs'] = bigIntToJson(startByMs);
    json['reservedMillis'] = bigIntToJson(reservedMillis);
    if (runId != null) {
      json['runId'] = nativeToJson<String?>(runId);
    }
    if (closedAtMs != null) {
      json['closedAtMs'] = bigIntToJson(closedAtMs);
    }
    if (openJobId != null) {
      json['openJobId'] = nativeToJson<String?>(openJobId);
    }
    return json;
  }

  GetBillingAdmissionBillingAdmission({
    required this.id,
    required this.teamId,
    required this.jobId,
    required this.workerHost,
    required this.periodId,
    required this.claimedAtMs,
    required this.startByMs,
    required this.reservedMillis,
    this.runId,
    this.closedAtMs,
    this.openJobId,
  });
}

@immutable
class GetBillingAdmissionData {
  final GetBillingAdmissionBillingAccount? billingAccount;
  final GetBillingAdmissionBillingAdmission? billingAdmission;
  GetBillingAdmissionData.fromJson(dynamic json)
    : billingAccount = json['billingAccount'] == null
          ? null
          : GetBillingAdmissionBillingAccount.fromJson(json['billingAccount']),
      billingAdmission = json['billingAdmission'] == null
          ? null
          : GetBillingAdmissionBillingAdmission.fromJson(
              json['billingAdmission'],
            );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingAdmissionData otherTyped = other as GetBillingAdmissionData;
    return billingAccount == otherTyped.billingAccount &&
        billingAdmission == otherTyped.billingAdmission;
  }

  @override
  int get hashCode =>
      Object.hashAll([billingAccount.hashCode, billingAdmission.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (billingAccount != null) {
      json['billingAccount'] = billingAccount!.toJson();
    }
    if (billingAdmission != null) {
      json['billingAdmission'] = billingAdmission!.toJson();
    }
    return json;
  }

  GetBillingAdmissionData({
    this.billingAccount,
    this.billingAdmission,
  });
}

@immutable
class GetBillingAdmissionVariables {
  final String teamId;
  final String id;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetBillingAdmissionVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']),
      id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingAdmissionVariables otherTyped =
        other as GetBillingAdmissionVariables;
    return teamId == otherTyped.teamId && id == otherTyped.id;
  }

  @override
  int get hashCode => Object.hashAll([teamId.hashCode, id.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetBillingAdmissionVariables({
    required this.teamId,
    required this.id,
  });
}
