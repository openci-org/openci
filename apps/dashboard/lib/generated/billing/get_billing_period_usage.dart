part of 'billing.dart';

class GetBillingPeriodUsageVariablesBuilder {
  String teamId;
  String periodId;
  BigInt atMs;

  final FirebaseDataConnect _dataConnect;
  GetBillingPeriodUsageVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.periodId,
    required this.atMs,
  });
  Deserializer<GetBillingPeriodUsageData> dataDeserializer = (dynamic json) =>
      GetBillingPeriodUsageData.fromJson(jsonDecode(json));
  Serializer<GetBillingPeriodUsageVariables> varsSerializer =
      (GetBillingPeriodUsageVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetBillingPeriodUsageData, GetBillingPeriodUsageVariables>>
  execute() {
    return ref().execute();
  }

  QueryRef<GetBillingPeriodUsageData, GetBillingPeriodUsageVariables> ref() {
    GetBillingPeriodUsageVariables vars = GetBillingPeriodUsageVariables(
      teamId: teamId,
      periodId: periodId,
      atMs: atMs,
    );
    return _dataConnect.query(
      "GetBillingPeriodUsage",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetBillingPeriodUsageData {
  final AnyValue? usage;
  GetBillingPeriodUsageData.fromJson(dynamic json)
    : usage = json['usage'] == null ? null : AnyValue.fromJson(json['usage']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingPeriodUsageData otherTyped =
        other as GetBillingPeriodUsageData;
    return usage == otherTyped.usage;
  }

  @override
  int get hashCode => usage.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (usage != null) {
      json['usage'] = usage!.toJson();
    }
    return json;
  }

  GetBillingPeriodUsageData({
    this.usage,
  });
}

@immutable
class GetBillingPeriodUsageVariables {
  final String teamId;
  final String periodId;
  final BigInt atMs;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetBillingPeriodUsageVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']),
      periodId = nativeFromJson<String>(json['periodId']),
      atMs = bigIntFromJson(json['atMs']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingPeriodUsageVariables otherTyped =
        other as GetBillingPeriodUsageVariables;
    return teamId == otherTyped.teamId &&
        periodId == otherTyped.periodId &&
        atMs == otherTyped.atMs;
  }

  @override
  int get hashCode =>
      Object.hashAll([teamId.hashCode, periodId.hashCode, atMs.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['periodId'] = nativeToJson<String>(periodId);
    json['atMs'] = bigIntToJson(atMs);
    return json;
  }

  GetBillingPeriodUsageVariables({
    required this.teamId,
    required this.periodId,
    required this.atMs,
  });
}
