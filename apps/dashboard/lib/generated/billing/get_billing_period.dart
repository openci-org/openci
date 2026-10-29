part of 'billing.dart';

class GetBillingPeriodVariablesBuilder {
  String teamId;
  String id;

  final FirebaseDataConnect _dataConnect;
  GetBillingPeriodVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.id,
  });
  Deserializer<GetBillingPeriodData> dataDeserializer = (dynamic json) =>
      GetBillingPeriodData.fromJson(jsonDecode(json));
  Serializer<GetBillingPeriodVariables> varsSerializer =
      (GetBillingPeriodVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetBillingPeriodData, GetBillingPeriodVariables>>
  execute() {
    return ref().execute();
  }

  QueryRef<GetBillingPeriodData, GetBillingPeriodVariables> ref() {
    GetBillingPeriodVariables vars = GetBillingPeriodVariables(
      teamId: teamId,
      id: id,
    );
    return _dataConnect.query(
      "GetBillingPeriod",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetBillingPeriodPeriod {
  final String id;
  final String teamId;
  final String planId;
  final String periodType;
  final BigInt startsAt;
  final BigInt endsAt;
  final BigInt? allowanceSeconds;
  GetBillingPeriodPeriod.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']),
      teamId = nativeFromJson<String>(json['teamId']),
      planId = nativeFromJson<String>(json['planId']),
      periodType = nativeFromJson<String>(json['periodType']),
      startsAt = bigIntFromJson(json['startsAt']),
      endsAt = bigIntFromJson(json['endsAt']),
      allowanceSeconds = json['allowanceSeconds'] == null
          ? null
          : bigIntFromJson(json['allowanceSeconds']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingPeriodPeriod otherTyped = other as GetBillingPeriodPeriod;
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
    if (allowanceSeconds != null) {
      json['allowanceSeconds'] = bigIntToJson(allowanceSeconds);
    }
    return json;
  }

  GetBillingPeriodPeriod({
    required this.id,
    required this.teamId,
    required this.planId,
    required this.periodType,
    required this.startsAt,
    required this.endsAt,
    this.allowanceSeconds,
  });
}

@immutable
class GetBillingPeriodData {
  final GetBillingPeriodPeriod? period;
  GetBillingPeriodData.fromJson(dynamic json)
    : period = json['period'] == null
          ? null
          : GetBillingPeriodPeriod.fromJson(json['period']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingPeriodData otherTyped = other as GetBillingPeriodData;
    return period == otherTyped.period;
  }

  @override
  int get hashCode => period.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (period != null) {
      json['period'] = period!.toJson();
    }
    return json;
  }

  GetBillingPeriodData({
    this.period,
  });
}

@immutable
class GetBillingPeriodVariables {
  final String teamId;
  final String id;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetBillingPeriodVariables.fromJson(Map<String, dynamic> json)
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

    final GetBillingPeriodVariables otherTyped =
        other as GetBillingPeriodVariables;
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

  GetBillingPeriodVariables({
    required this.teamId,
    required this.id,
  });
}
