part of 'billing.dart';

class GetOpenBillingCheckoutCreationVariablesBuilder {
  String teamId;
  bool livemode;

  final FirebaseDataConnect _dataConnect;
  GetOpenBillingCheckoutCreationVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.livemode,
  });
  Deserializer<GetOpenBillingCheckoutCreationData> dataDeserializer =
      (dynamic json) =>
          GetOpenBillingCheckoutCreationData.fromJson(jsonDecode(json));
  Serializer<GetOpenBillingCheckoutCreationVariables> varsSerializer =
      (GetOpenBillingCheckoutCreationVariables vars) =>
          jsonEncode(vars.toJson());
  Future<
    QueryResult<
      GetOpenBillingCheckoutCreationData,
      GetOpenBillingCheckoutCreationVariables
    >
  >
  execute() {
    return ref().execute();
  }

  QueryRef<
    GetOpenBillingCheckoutCreationData,
    GetOpenBillingCheckoutCreationVariables
  >
  ref() {
    GetOpenBillingCheckoutCreationVariables vars =
        GetOpenBillingCheckoutCreationVariables(
          teamId: teamId,
          livemode: livemode,
        );
    return _dataConnect.query(
      "GetOpenBillingCheckoutCreation",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetOpenBillingCheckoutCreationBillingCheckoutCreation {
  final String idempotencyKey;
  final String teamId;
  final String planId;
  final String stripeCustomerId;
  final String stripePriceId;
  final String successUrl;
  final String cancelUrl;
  final bool livemode;
  final BigInt createdAt;
  final String? stripeCheckoutSessionId;
  GetOpenBillingCheckoutCreationBillingCheckoutCreation.fromJson(dynamic json)
    : idempotencyKey = nativeFromJson<String>(json['idempotencyKey']),
      teamId = nativeFromJson<String>(json['teamId']),
      planId = nativeFromJson<String>(json['planId']),
      stripeCustomerId = nativeFromJson<String>(json['stripeCustomerId']),
      stripePriceId = nativeFromJson<String>(json['stripePriceId']),
      successUrl = nativeFromJson<String>(json['successUrl']),
      cancelUrl = nativeFromJson<String>(json['cancelUrl']),
      livemode = nativeFromJson<bool>(json['livemode']),
      createdAt = bigIntFromJson(json['createdAt']),
      stripeCheckoutSessionId = json['stripeCheckoutSessionId'] == null
          ? null
          : nativeFromJson<String>(json['stripeCheckoutSessionId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetOpenBillingCheckoutCreationBillingCheckoutCreation otherTyped =
        other as GetOpenBillingCheckoutCreationBillingCheckoutCreation;
    return idempotencyKey == otherTyped.idempotencyKey &&
        teamId == otherTyped.teamId &&
        planId == otherTyped.planId &&
        stripeCustomerId == otherTyped.stripeCustomerId &&
        stripePriceId == otherTyped.stripePriceId &&
        successUrl == otherTyped.successUrl &&
        cancelUrl == otherTyped.cancelUrl &&
        livemode == otherTyped.livemode &&
        createdAt == otherTyped.createdAt &&
        stripeCheckoutSessionId == otherTyped.stripeCheckoutSessionId;
  }

  @override
  int get hashCode => Object.hashAll([
    idempotencyKey.hashCode,
    teamId.hashCode,
    planId.hashCode,
    stripeCustomerId.hashCode,
    stripePriceId.hashCode,
    successUrl.hashCode,
    cancelUrl.hashCode,
    livemode.hashCode,
    createdAt.hashCode,
    stripeCheckoutSessionId.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['idempotencyKey'] = nativeToJson<String>(idempotencyKey);
    json['teamId'] = nativeToJson<String>(teamId);
    json['planId'] = nativeToJson<String>(planId);
    json['stripeCustomerId'] = nativeToJson<String>(stripeCustomerId);
    json['stripePriceId'] = nativeToJson<String>(stripePriceId);
    json['successUrl'] = nativeToJson<String>(successUrl);
    json['cancelUrl'] = nativeToJson<String>(cancelUrl);
    json['livemode'] = nativeToJson<bool>(livemode);
    json['createdAt'] = bigIntToJson(createdAt);
    if (stripeCheckoutSessionId != null) {
      json['stripeCheckoutSessionId'] = nativeToJson<String?>(
        stripeCheckoutSessionId,
      );
    }
    return json;
  }

  GetOpenBillingCheckoutCreationBillingCheckoutCreation({
    required this.idempotencyKey,
    required this.teamId,
    required this.planId,
    required this.stripeCustomerId,
    required this.stripePriceId,
    required this.successUrl,
    required this.cancelUrl,
    required this.livemode,
    required this.createdAt,
    this.stripeCheckoutSessionId,
  });
}

@immutable
class GetOpenBillingCheckoutCreationData {
  final GetOpenBillingCheckoutCreationBillingCheckoutCreation?
  billingCheckoutCreation;
  GetOpenBillingCheckoutCreationData.fromJson(dynamic json)
    : billingCheckoutCreation = json['billingCheckoutCreation'] == null
          ? null
          : GetOpenBillingCheckoutCreationBillingCheckoutCreation.fromJson(
              json['billingCheckoutCreation'],
            );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetOpenBillingCheckoutCreationData otherTyped =
        other as GetOpenBillingCheckoutCreationData;
    return billingCheckoutCreation == otherTyped.billingCheckoutCreation;
  }

  @override
  int get hashCode => billingCheckoutCreation.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (billingCheckoutCreation != null) {
      json['billingCheckoutCreation'] = billingCheckoutCreation!.toJson();
    }
    return json;
  }

  GetOpenBillingCheckoutCreationData({
    this.billingCheckoutCreation,
  });
}

@immutable
class GetOpenBillingCheckoutCreationVariables {
  final String teamId;
  final bool livemode;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetOpenBillingCheckoutCreationVariables.fromJson(Map<String, dynamic> json)
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

    final GetOpenBillingCheckoutCreationVariables otherTyped =
        other as GetOpenBillingCheckoutCreationVariables;
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

  GetOpenBillingCheckoutCreationVariables({
    required this.teamId,
    required this.livemode,
  });
}
