part of 'billing.dart';

class ExpireBillingAdmissionVariablesBuilder {
  String id;
  String teamId;
  Optional<String> _runId = Optional.optional(nativeFromJson, nativeToJson);
  BigInt expectedUsageRevision;
  BigInt atMs;

  final FirebaseDataConnect _dataConnect;
  ExpireBillingAdmissionVariablesBuilder runId(String? t) {
    _runId.value = t;
    return this;
  }

  ExpireBillingAdmissionVariablesBuilder(
    this._dataConnect, {
    required this.id,
    required this.teamId,
    required this.expectedUsageRevision,
    required this.atMs,
  });
  Deserializer<ExpireBillingAdmissionData> dataDeserializer = (dynamic json) =>
      ExpireBillingAdmissionData.fromJson(jsonDecode(json));
  Serializer<ExpireBillingAdmissionVariables> varsSerializer =
      (ExpireBillingAdmissionVariables vars) => jsonEncode(vars.toJson());
  Future<
    OperationResult<ExpireBillingAdmissionData, ExpireBillingAdmissionVariables>
  >
  execute() {
    return ref().execute();
  }

  MutationRef<ExpireBillingAdmissionData, ExpireBillingAdmissionVariables>
  ref() {
    ExpireBillingAdmissionVariables vars = ExpireBillingAdmissionVariables(
      id: id,
      teamId: teamId,
      runId: _runId,
      expectedUsageRevision: expectedUsageRevision,
      atMs: atMs,
    );
    return _dataConnect.mutation(
      "ExpireBillingAdmission",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class ExpireBillingAdmissionBillingAdmissionUpdate {
  final String id;
  ExpireBillingAdmissionBillingAdmissionUpdate.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ExpireBillingAdmissionBillingAdmissionUpdate otherTyped =
        other as ExpireBillingAdmissionBillingAdmissionUpdate;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  ExpireBillingAdmissionBillingAdmissionUpdate({
    required this.id,
  });
}

@immutable
class ExpireBillingAdmissionData {
  final int billingAccount_updateMany;
  final int buildJob_updateMany;
  final int buildRun_updateMany;
  final ExpireBillingAdmissionBillingAdmissionUpdate? billingAdmission_update;
  ExpireBillingAdmissionData.fromJson(dynamic json)
    : billingAccount_updateMany = nativeFromJson<int>(
        json['billingAccount_updateMany'],
      ),
      buildJob_updateMany = nativeFromJson<int>(json['buildJob_updateMany']),
      buildRun_updateMany = nativeFromJson<int>(json['buildRun_updateMany']),
      billingAdmission_update = json['billingAdmission_update'] == null
          ? null
          : ExpireBillingAdmissionBillingAdmissionUpdate.fromJson(
              json['billingAdmission_update'],
            );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ExpireBillingAdmissionData otherTyped =
        other as ExpireBillingAdmissionData;
    return billingAccount_updateMany == otherTyped.billingAccount_updateMany &&
        buildJob_updateMany == otherTyped.buildJob_updateMany &&
        buildRun_updateMany == otherTyped.buildRun_updateMany &&
        billingAdmission_update == otherTyped.billingAdmission_update;
  }

  @override
  int get hashCode => Object.hashAll([
    billingAccount_updateMany.hashCode,
    buildJob_updateMany.hashCode,
    buildRun_updateMany.hashCode,
    billingAdmission_update.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['billingAccount_updateMany'] = nativeToJson<int>(
      billingAccount_updateMany,
    );
    json['buildJob_updateMany'] = nativeToJson<int>(buildJob_updateMany);
    json['buildRun_updateMany'] = nativeToJson<int>(buildRun_updateMany);
    if (billingAdmission_update != null) {
      json['billingAdmission_update'] = billingAdmission_update!.toJson();
    }
    return json;
  }

  ExpireBillingAdmissionData({
    required this.billingAccount_updateMany,
    required this.buildJob_updateMany,
    required this.buildRun_updateMany,
    this.billingAdmission_update,
  });
}

@immutable
class ExpireBillingAdmissionVariables {
  final String id;
  final String teamId;
  late final Optional<String> runId;
  final BigInt expectedUsageRevision;
  final BigInt atMs;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  ExpireBillingAdmissionVariables.fromJson(Map<String, dynamic> json)
    : id = nativeFromJson<String>(json['id']),
      teamId = nativeFromJson<String>(json['teamId']),
      expectedUsageRevision = bigIntFromJson(json['expectedUsageRevision']),
      atMs = bigIntFromJson(json['atMs']) {
    runId = Optional.optional(nativeFromJson, nativeToJson);
    runId.value = json['runId'] == null
        ? null
        : nativeFromJson<String>(json['runId']);
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ExpireBillingAdmissionVariables otherTyped =
        other as ExpireBillingAdmissionVariables;
    return id == otherTyped.id &&
        teamId == otherTyped.teamId &&
        runId == otherTyped.runId &&
        expectedUsageRevision == otherTyped.expectedUsageRevision &&
        atMs == otherTyped.atMs;
  }

  @override
  int get hashCode => Object.hashAll([
    id.hashCode,
    teamId.hashCode,
    runId.hashCode,
    expectedUsageRevision.hashCode,
    atMs.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['teamId'] = nativeToJson<String>(teamId);
    if (runId.state == OptionalState.set) {
      json['runId'] = runId.toJson();
    }
    json['expectedUsageRevision'] = bigIntToJson(expectedUsageRevision);
    json['atMs'] = bigIntToJson(atMs);
    return json;
  }

  ExpireBillingAdmissionVariables({
    required this.id,
    required this.teamId,
    required this.runId,
    required this.expectedUsageRevision,
    required this.atMs,
  });
}
