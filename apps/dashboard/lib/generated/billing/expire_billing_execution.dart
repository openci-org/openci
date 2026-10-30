part of 'billing.dart';

class ExpireBillingExecutionVariablesBuilder {
  String teamId;
  String runId;
  BigInt expectedUsageRevision;
  BigInt atMs;

  final FirebaseDataConnect _dataConnect;
  ExpireBillingExecutionVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.runId,
    required this.expectedUsageRevision,
    required this.atMs,
  });
  Deserializer<ExpireBillingExecutionData> dataDeserializer = (dynamic json) =>
      ExpireBillingExecutionData.fromJson(jsonDecode(json));
  Serializer<ExpireBillingExecutionVariables> varsSerializer =
      (ExpireBillingExecutionVariables vars) => jsonEncode(vars.toJson());
  Future<
    OperationResult<ExpireBillingExecutionData, ExpireBillingExecutionVariables>
  >
  execute() {
    return ref().execute();
  }

  MutationRef<ExpireBillingExecutionData, ExpireBillingExecutionVariables>
  ref() {
    ExpireBillingExecutionVariables vars = ExpireBillingExecutionVariables(
      teamId: teamId,
      runId: runId,
      expectedUsageRevision: expectedUsageRevision,
      atMs: atMs,
    );
    return _dataConnect.mutation(
      "ExpireBillingExecution",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class ExpireBillingExecutionBillingExecutionUpdate {
  final String runId;
  ExpireBillingExecutionBillingExecutionUpdate.fromJson(dynamic json)
    : runId = nativeFromJson<String>(json['runId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ExpireBillingExecutionBillingExecutionUpdate otherTyped =
        other as ExpireBillingExecutionBillingExecutionUpdate;
    return runId == otherTyped.runId;
  }

  @override
  int get hashCode => runId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['runId'] = nativeToJson<String>(runId);
    return json;
  }

  ExpireBillingExecutionBillingExecutionUpdate({
    required this.runId,
  });
}

@immutable
class ExpireBillingExecutionData {
  final int billingAccount_updateMany;
  final ExpireBillingExecutionBillingExecutionUpdate? billingExecution_update;
  final int billingAdmission_updateMany;
  ExpireBillingExecutionData.fromJson(dynamic json)
    : billingAccount_updateMany = nativeFromJson<int>(
        json['billingAccount_updateMany'],
      ),
      billingExecution_update = json['billingExecution_update'] == null
          ? null
          : ExpireBillingExecutionBillingExecutionUpdate.fromJson(
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

    final ExpireBillingExecutionData otherTyped =
        other as ExpireBillingExecutionData;
    return billingAccount_updateMany == otherTyped.billingAccount_updateMany &&
        billingExecution_update == otherTyped.billingExecution_update &&
        billingAdmission_updateMany == otherTyped.billingAdmission_updateMany;
  }

  @override
  int get hashCode => Object.hashAll([
    billingAccount_updateMany.hashCode,
    billingExecution_update.hashCode,
    billingAdmission_updateMany.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['billingAccount_updateMany'] = nativeToJson<int>(
      billingAccount_updateMany,
    );
    if (billingExecution_update != null) {
      json['billingExecution_update'] = billingExecution_update!.toJson();
    }
    json['billingAdmission_updateMany'] = nativeToJson<int>(
      billingAdmission_updateMany,
    );
    return json;
  }

  ExpireBillingExecutionData({
    required this.billingAccount_updateMany,
    this.billingExecution_update,
    required this.billingAdmission_updateMany,
  });
}

@immutable
class ExpireBillingExecutionVariables {
  final String teamId;
  final String runId;
  final BigInt expectedUsageRevision;
  final BigInt atMs;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  ExpireBillingExecutionVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']),
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

    final ExpireBillingExecutionVariables otherTyped =
        other as ExpireBillingExecutionVariables;
    return teamId == otherTyped.teamId &&
        runId == otherTyped.runId &&
        expectedUsageRevision == otherTyped.expectedUsageRevision &&
        atMs == otherTyped.atMs;
  }

  @override
  int get hashCode => Object.hashAll([
    teamId.hashCode,
    runId.hashCode,
    expectedUsageRevision.hashCode,
    atMs.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['runId'] = nativeToJson<String>(runId);
    json['expectedUsageRevision'] = bigIntToJson(expectedUsageRevision);
    json['atMs'] = bigIntToJson(atMs);
    return json;
  }

  ExpireBillingExecutionVariables({
    required this.teamId,
    required this.runId,
    required this.expectedUsageRevision,
    required this.atMs,
  });
}
