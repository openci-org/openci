part of 'billing.dart';

class GetBillingCustomerCreationVariablesBuilder {
  String teamId;
  bool livemode;

  final FirebaseDataConnect _dataConnect;
  GetBillingCustomerCreationVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.livemode,
  });
  Deserializer<GetBillingCustomerCreationData> dataDeserializer =
      (dynamic json) =>
          GetBillingCustomerCreationData.fromJson(jsonDecode(json));
  Serializer<GetBillingCustomerCreationVariables> varsSerializer =
      (GetBillingCustomerCreationVariables vars) => jsonEncode(vars.toJson());
  Future<
    QueryResult<
      GetBillingCustomerCreationData,
      GetBillingCustomerCreationVariables
    >
  >
  execute() {
    return ref().execute();
  }

  QueryRef<GetBillingCustomerCreationData, GetBillingCustomerCreationVariables>
  ref() {
    GetBillingCustomerCreationVariables vars =
        GetBillingCustomerCreationVariables(
          teamId: teamId,
          livemode: livemode,
        );
    return _dataConnect.query(
      "GetBillingCustomerCreation",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetBillingCustomerCreationBillingCustomerCreation {
  final String teamId;
  final String idempotencyKey;
  final bool livemode;
  final BigInt createdAt;
  final String? stripeCustomerId;
  GetBillingCustomerCreationBillingCustomerCreation.fromJson(dynamic json)
    : teamId = nativeFromJson<String>(json['teamId']),
      idempotencyKey = nativeFromJson<String>(json['idempotencyKey']),
      livemode = nativeFromJson<bool>(json['livemode']),
      createdAt = bigIntFromJson(json['createdAt']),
      stripeCustomerId = json['stripeCustomerId'] == null
          ? null
          : nativeFromJson<String>(json['stripeCustomerId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingCustomerCreationBillingCustomerCreation otherTyped =
        other as GetBillingCustomerCreationBillingCustomerCreation;
    return teamId == otherTyped.teamId &&
        idempotencyKey == otherTyped.idempotencyKey &&
        livemode == otherTyped.livemode &&
        createdAt == otherTyped.createdAt &&
        stripeCustomerId == otherTyped.stripeCustomerId;
  }

  @override
  int get hashCode => Object.hashAll([
    teamId.hashCode,
    idempotencyKey.hashCode,
    livemode.hashCode,
    createdAt.hashCode,
    stripeCustomerId.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['idempotencyKey'] = nativeToJson<String>(idempotencyKey);
    json['livemode'] = nativeToJson<bool>(livemode);
    json['createdAt'] = bigIntToJson(createdAt);
    if (stripeCustomerId != null) {
      json['stripeCustomerId'] = nativeToJson<String?>(stripeCustomerId);
    }
    return json;
  }

  GetBillingCustomerCreationBillingCustomerCreation({
    required this.teamId,
    required this.idempotencyKey,
    required this.livemode,
    required this.createdAt,
    this.stripeCustomerId,
  });
}

@immutable
class GetBillingCustomerCreationData {
  final GetBillingCustomerCreationBillingCustomerCreation?
  billingCustomerCreation;
  GetBillingCustomerCreationData.fromJson(dynamic json)
    : billingCustomerCreation = json['billingCustomerCreation'] == null
          ? null
          : GetBillingCustomerCreationBillingCustomerCreation.fromJson(
              json['billingCustomerCreation'],
            );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingCustomerCreationData otherTyped =
        other as GetBillingCustomerCreationData;
    return billingCustomerCreation == otherTyped.billingCustomerCreation;
  }

  @override
  int get hashCode => billingCustomerCreation.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (billingCustomerCreation != null) {
      json['billingCustomerCreation'] = billingCustomerCreation!.toJson();
    }
    return json;
  }

  GetBillingCustomerCreationData({
    this.billingCustomerCreation,
  });
}

@immutable
class GetBillingCustomerCreationVariables {
  final String teamId;
  final bool livemode;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetBillingCustomerCreationVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']),
      livemode = nativeFromJson<bool>(json['livemode']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingCustomerCreationVariables otherTyped =
        other as GetBillingCustomerCreationVariables;
    return teamId == otherTyped.teamId && livemode == otherTyped.livemode;
  }

  @override
  int get hashCode => Object.hashAll([teamId.hashCode, livemode.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['livemode'] = nativeToJson<bool>(livemode);
    return json;
  }

  GetBillingCustomerCreationVariables({
    required this.teamId,
    required this.livemode,
  });
}
