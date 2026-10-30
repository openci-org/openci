part of 'billing.dart';

class CreateBillingPeriodVariablesBuilder {
  String id;
  String teamId;
  String planId;
  String periodType;
  BigInt startsAt;
  BigInt endsAt;
  Optional<BigInt> _allowanceSeconds = Optional.optional(
    bigIntFromJson,
    bigIntToJson,
  );

  final FirebaseDataConnect _dataConnect;
  CreateBillingPeriodVariablesBuilder allowanceSeconds(BigInt? t) {
    _allowanceSeconds.value = t;
    return this;
  }

  CreateBillingPeriodVariablesBuilder(
    this._dataConnect, {
    required this.id,
    required this.teamId,
    required this.planId,
    required this.periodType,
    required this.startsAt,
    required this.endsAt,
  });
  Deserializer<CreateBillingPeriodData> dataDeserializer = (dynamic json) =>
      CreateBillingPeriodData.fromJson(jsonDecode(json));
  Serializer<CreateBillingPeriodVariables> varsSerializer =
      (CreateBillingPeriodVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateBillingPeriodData, CreateBillingPeriodVariables>>
  execute() {
    return ref().execute();
  }

  MutationRef<CreateBillingPeriodData, CreateBillingPeriodVariables> ref() {
    CreateBillingPeriodVariables vars = CreateBillingPeriodVariables(
      id: id,
      teamId: teamId,
      planId: planId,
      periodType: periodType,
      startsAt: startsAt,
      endsAt: endsAt,
      allowanceSeconds: _allowanceSeconds,
    );
    return _dataConnect.mutation(
      "CreateBillingPeriod",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class CreateBillingPeriodBillingAccountUpsert {
  final String teamId;
  CreateBillingPeriodBillingAccountUpsert.fromJson(dynamic json)
    : teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreateBillingPeriodBillingAccountUpsert otherTyped =
        other as CreateBillingPeriodBillingAccountUpsert;
    return teamId == otherTyped.teamId;
  }

  @override
  int get hashCode => teamId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  CreateBillingPeriodBillingAccountUpsert({
    required this.teamId,
  });
}

@immutable
class CreateBillingPeriodBillingPeriodInsert {
  final String id;
  CreateBillingPeriodBillingPeriodInsert.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreateBillingPeriodBillingPeriodInsert otherTyped =
        other as CreateBillingPeriodBillingPeriodInsert;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateBillingPeriodBillingPeriodInsert({
    required this.id,
  });
}

@immutable
class CreateBillingPeriodData {
  final CreateBillingPeriodBillingAccountUpsert billingAccount_upsert;
  final CreateBillingPeriodBillingPeriodInsert billingPeriod_insert;
  CreateBillingPeriodData.fromJson(dynamic json)
    : billingAccount_upsert = CreateBillingPeriodBillingAccountUpsert.fromJson(
        json['billingAccount_upsert'],
      ),
      billingPeriod_insert = CreateBillingPeriodBillingPeriodInsert.fromJson(
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

    final CreateBillingPeriodData otherTyped = other as CreateBillingPeriodData;
    return billingAccount_upsert == otherTyped.billingAccount_upsert &&
        billingPeriod_insert == otherTyped.billingPeriod_insert;
  }

  @override
  int get hashCode => Object.hashAll([
    billingAccount_upsert.hashCode,
    billingPeriod_insert.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['billingAccount_upsert'] = billingAccount_upsert.toJson();
    json['billingPeriod_insert'] = billingPeriod_insert.toJson();
    return json;
  }

  CreateBillingPeriodData({
    required this.billingAccount_upsert,
    required this.billingPeriod_insert,
  });
}

@immutable
class CreateBillingPeriodVariables {
  final String id;
  final String teamId;
  final String planId;
  final String periodType;
  final BigInt startsAt;
  final BigInt endsAt;
  late final Optional<BigInt> allowanceSeconds;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  CreateBillingPeriodVariables.fromJson(Map<String, dynamic> json)
    : id = nativeFromJson<String>(json['id']),
      teamId = nativeFromJson<String>(json['teamId']),
      planId = nativeFromJson<String>(json['planId']),
      periodType = nativeFromJson<String>(json['periodType']),
      startsAt = bigIntFromJson(json['startsAt']),
      endsAt = bigIntFromJson(json['endsAt']) {
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

    final CreateBillingPeriodVariables otherTyped =
        other as CreateBillingPeriodVariables;
    return id == otherTyped.id &&
        teamId == otherTyped.teamId &&
        planId == otherTyped.planId &&
        periodType == otherTyped.periodType &&
        startsAt == otherTyped.startsAt &&
        endsAt == otherTyped.endsAt &&
        allowanceSeconds == otherTyped.allowanceSeconds;
  }

  @override
  int get hashCode => Object.hashAll([
    id.hashCode,
    teamId.hashCode,
    planId.hashCode,
    periodType.hashCode,
    startsAt.hashCode,
    endsAt.hashCode,
    allowanceSeconds.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['teamId'] = nativeToJson<String>(teamId);
    json['planId'] = nativeToJson<String>(planId);
    json['periodType'] = nativeToJson<String>(periodType);
    json['startsAt'] = bigIntToJson(startsAt);
    json['endsAt'] = bigIntToJson(endsAt);
    if (allowanceSeconds.state == OptionalState.set) {
      json['allowanceSeconds'] = allowanceSeconds.toJson();
    }
    return json;
  }

  CreateBillingPeriodVariables({
    required this.id,
    required this.teamId,
    required this.planId,
    required this.periodType,
    required this.startsAt,
    required this.endsAt,
    required this.allowanceSeconds,
  });
}
