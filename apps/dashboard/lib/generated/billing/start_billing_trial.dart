part of 'billing.dart';

class StartBillingTrialVariablesBuilder {
  String teamId;
  String userId;
  String periodId;
  Optional<BigInt> _allowanceSeconds = Optional.optional(
    bigIntFromJson,
    bigIntToJson,
  );

  final FirebaseDataConnect _dataConnect;
  StartBillingTrialVariablesBuilder allowanceSeconds(BigInt? t) {
    _allowanceSeconds.value = t;
    return this;
  }

  StartBillingTrialVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.userId,
    required this.periodId,
  });
  Deserializer<StartBillingTrialData> dataDeserializer = (dynamic json) =>
      StartBillingTrialData.fromJson(jsonDecode(json));
  Serializer<StartBillingTrialVariables> varsSerializer =
      (StartBillingTrialVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<StartBillingTrialData, StartBillingTrialVariables>>
  execute() {
    return ref().execute();
  }

  MutationRef<StartBillingTrialData, StartBillingTrialVariables> ref() {
    StartBillingTrialVariables vars = StartBillingTrialVariables(
      teamId: teamId,
      userId: userId,
      periodId: periodId,
      allowanceSeconds: _allowanceSeconds,
    );
    return _dataConnect.mutation(
      "StartBillingTrial",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class StartBillingTrialBillingAccountUpsert {
  final String teamId;
  StartBillingTrialBillingAccountUpsert.fromJson(dynamic json)
    : teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final StartBillingTrialBillingAccountUpsert otherTyped =
        other as StartBillingTrialBillingAccountUpsert;
    return teamId == otherTyped.teamId;
  }

  @override
  int get hashCode => teamId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  StartBillingTrialBillingAccountUpsert({
    required this.teamId,
  });
}

@immutable
class StartBillingTrialBillingTrialClaimInsert {
  final String userId;
  StartBillingTrialBillingTrialClaimInsert.fromJson(dynamic json)
    : userId = nativeFromJson<String>(json['userId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final StartBillingTrialBillingTrialClaimInsert otherTyped =
        other as StartBillingTrialBillingTrialClaimInsert;
    return userId == otherTyped.userId;
  }

  @override
  int get hashCode => userId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userId'] = nativeToJson<String>(userId);
    return json;
  }

  StartBillingTrialBillingTrialClaimInsert({
    required this.userId,
  });
}

@immutable
class StartBillingTrialBillingPeriodInsert {
  final String id;
  StartBillingTrialBillingPeriodInsert.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final StartBillingTrialBillingPeriodInsert otherTyped =
        other as StartBillingTrialBillingPeriodInsert;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  StartBillingTrialBillingPeriodInsert({
    required this.id,
  });
}

@immutable
class StartBillingTrialData {
  final StartBillingTrialBillingAccountUpsert billingAccount_upsert;
  final StartBillingTrialBillingTrialClaimInsert billingTrialClaim_insert;
  final StartBillingTrialBillingPeriodInsert billingPeriod_insert;
  StartBillingTrialData.fromJson(dynamic json)
    : billingAccount_upsert = StartBillingTrialBillingAccountUpsert.fromJson(
        json['billingAccount_upsert'],
      ),
      billingTrialClaim_insert =
          StartBillingTrialBillingTrialClaimInsert.fromJson(
            json['billingTrialClaim_insert'],
          ),
      billingPeriod_insert = StartBillingTrialBillingPeriodInsert.fromJson(
        json['billingPeriod_insert'],
      );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final StartBillingTrialData otherTyped = other as StartBillingTrialData;
    return billingAccount_upsert == otherTyped.billingAccount_upsert &&
        billingTrialClaim_insert == otherTyped.billingTrialClaim_insert &&
        billingPeriod_insert == otherTyped.billingPeriod_insert;
  }

  @override
  int get hashCode => Object.hashAll([
    billingAccount_upsert.hashCode,
    billingTrialClaim_insert.hashCode,
    billingPeriod_insert.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['billingAccount_upsert'] = billingAccount_upsert.toJson();
    json['billingTrialClaim_insert'] = billingTrialClaim_insert.toJson();
    json['billingPeriod_insert'] = billingPeriod_insert.toJson();
    return json;
  }

  StartBillingTrialData({
    required this.billingAccount_upsert,
    required this.billingTrialClaim_insert,
    required this.billingPeriod_insert,
  });
}

@immutable
class StartBillingTrialVariables {
  final String teamId;
  final String userId;
  final String periodId;
  late final Optional<BigInt> allowanceSeconds;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  StartBillingTrialVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']),
      userId = nativeFromJson<String>(json['userId']),
      periodId = nativeFromJson<String>(json['periodId']) {
    allowanceSeconds = Optional.optional(bigIntFromJson, bigIntToJson);
    allowanceSeconds.value = json['allowanceSeconds'] == null
        ? null
        : bigIntFromJson(json['allowanceSeconds']);
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final StartBillingTrialVariables otherTyped =
        other as StartBillingTrialVariables;
    return teamId == otherTyped.teamId &&
        userId == otherTyped.userId &&
        periodId == otherTyped.periodId &&
        allowanceSeconds == otherTyped.allowanceSeconds;
  }

  @override
  int get hashCode => Object.hashAll([
    teamId.hashCode,
    userId.hashCode,
    periodId.hashCode,
    allowanceSeconds.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['userId'] = nativeToJson<String>(userId);
    json['periodId'] = nativeToJson<String>(periodId);
    if (allowanceSeconds.state == OptionalState.set) {
      json['allowanceSeconds'] = allowanceSeconds.toJson();
    }
    return json;
  }

  StartBillingTrialVariables({
    required this.teamId,
    required this.userId,
    required this.periodId,
    required this.allowanceSeconds,
  });
}
