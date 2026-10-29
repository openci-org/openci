part of 'billing.dart';

class CreateBillingAdmissionVariablesBuilder {
  String id;
  String teamId;
  String jobId;
  String workerHost;
  String periodId;
  BigInt atMs;
  Optional<String> _vmName = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;
  CreateBillingAdmissionVariablesBuilder vmName(String? t) {
    _vmName.value = t;
    return this;
  }

  CreateBillingAdmissionVariablesBuilder(
    this._dataConnect, {
    required this.id,
    required this.teamId,
    required this.jobId,
    required this.workerHost,
    required this.periodId,
    required this.atMs,
  });
  Deserializer<CreateBillingAdmissionData> dataDeserializer = (dynamic json) =>
      CreateBillingAdmissionData.fromJson(jsonDecode(json));
  Serializer<CreateBillingAdmissionVariables> varsSerializer =
      (CreateBillingAdmissionVariables vars) => jsonEncode(vars.toJson());
  Future<
    OperationResult<CreateBillingAdmissionData, CreateBillingAdmissionVariables>
  >
  execute() {
    return ref().execute();
  }

  MutationRef<CreateBillingAdmissionData, CreateBillingAdmissionVariables>
  ref() {
    CreateBillingAdmissionVariables vars = CreateBillingAdmissionVariables(
      id: id,
      teamId: teamId,
      jobId: jobId,
      workerHost: workerHost,
      periodId: periodId,
      atMs: atMs,
      vmName: _vmName,
    );
    return _dataConnect.mutation(
      "CreateBillingAdmission",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class CreateBillingAdmissionBillingAdmissionInsert {
  final String id;
  CreateBillingAdmissionBillingAdmissionInsert.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreateBillingAdmissionBillingAdmissionInsert otherTyped =
        other as CreateBillingAdmissionBillingAdmissionInsert;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateBillingAdmissionBillingAdmissionInsert({
    required this.id,
  });
}

@immutable
class CreateBillingAdmissionData {
  final int billingAccount_updateMany;
  final int buildJob_updateMany;
  final CreateBillingAdmissionBillingAdmissionInsert billingAdmission_insert;
  CreateBillingAdmissionData.fromJson(dynamic json)
    : billingAccount_updateMany = nativeFromJson<int>(
        json['billingAccount_updateMany'],
      ),
      buildJob_updateMany = nativeFromJson<int>(json['buildJob_updateMany']),
      billingAdmission_insert =
          CreateBillingAdmissionBillingAdmissionInsert.fromJson(
            json['billingAdmission_insert'],
          );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreateBillingAdmissionData otherTyped =
        other as CreateBillingAdmissionData;
    return billingAccount_updateMany == otherTyped.billingAccount_updateMany &&
        buildJob_updateMany == otherTyped.buildJob_updateMany &&
        billingAdmission_insert == otherTyped.billingAdmission_insert;
  }

  @override
  int get hashCode => Object.hashAll([
    billingAccount_updateMany.hashCode,
    buildJob_updateMany.hashCode,
    billingAdmission_insert.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['billingAccount_updateMany'] = nativeToJson<int>(
      billingAccount_updateMany,
    );
    json['buildJob_updateMany'] = nativeToJson<int>(buildJob_updateMany);
    json['billingAdmission_insert'] = billingAdmission_insert.toJson();
    return json;
  }

  CreateBillingAdmissionData({
    required this.billingAccount_updateMany,
    required this.buildJob_updateMany,
    required this.billingAdmission_insert,
  });
}

@immutable
class CreateBillingAdmissionVariables {
  final String id;
  final String teamId;
  final String jobId;
  final String workerHost;
  final String periodId;
  final BigInt atMs;
  late final Optional<String> vmName;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  CreateBillingAdmissionVariables.fromJson(Map<String, dynamic> json)
    : id = nativeFromJson<String>(json['id']),
      teamId = nativeFromJson<String>(json['teamId']),
      jobId = nativeFromJson<String>(json['jobId']),
      workerHost = nativeFromJson<String>(json['workerHost']),
      periodId = nativeFromJson<String>(json['periodId']),
      atMs = bigIntFromJson(json['atMs']) {
    vmName = Optional.optional(nativeFromJson, nativeToJson);
    vmName.value = json['vmName'] == null
        ? null
        : nativeFromJson<String>(json['vmName']);
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreateBillingAdmissionVariables otherTyped =
        other as CreateBillingAdmissionVariables;
    return id == otherTyped.id &&
        teamId == otherTyped.teamId &&
        jobId == otherTyped.jobId &&
        workerHost == otherTyped.workerHost &&
        periodId == otherTyped.periodId &&
        atMs == otherTyped.atMs &&
        vmName == otherTyped.vmName;
  }

  @override
  int get hashCode => Object.hashAll([
    id.hashCode,
    teamId.hashCode,
    jobId.hashCode,
    workerHost.hashCode,
    periodId.hashCode,
    atMs.hashCode,
    vmName.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['teamId'] = nativeToJson<String>(teamId);
    json['jobId'] = nativeToJson<String>(jobId);
    json['workerHost'] = nativeToJson<String>(workerHost);
    json['periodId'] = nativeToJson<String>(periodId);
    json['atMs'] = bigIntToJson(atMs);
    if (vmName.state == OptionalState.set) {
      json['vmName'] = vmName.toJson();
    }
    return json;
  }

  CreateBillingAdmissionVariables({
    required this.id,
    required this.teamId,
    required this.jobId,
    required this.workerHost,
    required this.periodId,
    required this.atMs,
    required this.vmName,
  });
}
