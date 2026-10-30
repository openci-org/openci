part of 'billing.dart';

class GetBillingCheckoutCreationVariablesBuilder {
  String teamId;
  String idempotencyKey;
  bool livemode;

  final FirebaseDataConnect _dataConnect;
  GetBillingCheckoutCreationVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.idempotencyKey,
    required this.livemode,
  });
  Deserializer<GetBillingCheckoutCreationData> dataDeserializer =
      (dynamic json) =>
          GetBillingCheckoutCreationData.fromJson(jsonDecode(json));
  Serializer<GetBillingCheckoutCreationVariables> varsSerializer =
      (GetBillingCheckoutCreationVariables vars) => jsonEncode(vars.toJson());
  Future<
    QueryResult<
      GetBillingCheckoutCreationData,
      GetBillingCheckoutCreationVariables
    >
  >
  execute() {
    return ref().execute();
  }

  QueryRef<GetBillingCheckoutCreationData, GetBillingCheckoutCreationVariables>
  ref() {
    GetBillingCheckoutCreationVariables vars =
        GetBillingCheckoutCreationVariables(
          teamId: teamId,
          idempotencyKey: idempotencyKey,
          livemode: livemode,
        );
    return _dataConnect.query(
      "GetBillingCheckoutCreation",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetBillingCheckoutCreationCheckout {
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
  final BigInt? closedAt;
  final String? openTeamId;
  GetBillingCheckoutCreationCheckout.fromJson(dynamic json)
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
          : nativeFromJson<String>(json['stripeCheckoutSessionId']),
      closedAt = json['closedAt'] == null
          ? null
          : bigIntFromJson(json['closedAt']),
      openTeamId = json['openTeamId'] == null
          ? null
          : nativeFromJson<String>(json['openTeamId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingCheckoutCreationCheckout otherTyped =
        other as GetBillingCheckoutCreationCheckout;
    return idempotencyKey == otherTyped.idempotencyKey &&
        teamId == otherTyped.teamId &&
        planId == otherTyped.planId &&
        stripeCustomerId == otherTyped.stripeCustomerId &&
        stripePriceId == otherTyped.stripePriceId &&
        successUrl == otherTyped.successUrl &&
        cancelUrl == otherTyped.cancelUrl &&
        livemode == otherTyped.livemode &&
        createdAt == otherTyped.createdAt &&
        stripeCheckoutSessionId == otherTyped.stripeCheckoutSessionId &&
        closedAt == otherTyped.closedAt &&
        openTeamId == otherTyped.openTeamId;
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
    closedAt.hashCode,
    openTeamId.hashCode,
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
    if (closedAt != null) {
      json['closedAt'] = bigIntToJson(closedAt);
    }
    if (openTeamId != null) {
      json['openTeamId'] = nativeToJson<String?>(openTeamId);
    }
    return json;
  }

  GetBillingCheckoutCreationCheckout({
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
    this.closedAt,
    this.openTeamId,
  });
}

@immutable
class GetBillingCheckoutCreationData {
  final GetBillingCheckoutCreationCheckout? checkout;
  GetBillingCheckoutCreationData.fromJson(dynamic json)
    : checkout = json['checkout'] == null
          ? null
          : GetBillingCheckoutCreationCheckout.fromJson(json['checkout']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingCheckoutCreationData otherTyped =
        other as GetBillingCheckoutCreationData;
    return checkout == otherTyped.checkout;
  }

  @override
  int get hashCode => checkout.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (checkout != null) {
      json['checkout'] = checkout!.toJson();
    }
    return json;
  }

  GetBillingCheckoutCreationData({
    this.checkout,
  });
}

@immutable
class GetBillingCheckoutCreationVariables {
  final String teamId;
  final String idempotencyKey;
  final bool livemode;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetBillingCheckoutCreationVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']),
      idempotencyKey = nativeFromJson<String>(json['idempotencyKey']),
      livemode = nativeFromJson<bool>(json['livemode']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingCheckoutCreationVariables otherTyped =
        other as GetBillingCheckoutCreationVariables;
    return teamId == otherTyped.teamId &&
        idempotencyKey == otherTyped.idempotencyKey &&
        livemode == otherTyped.livemode;
  }

  @override
  int get hashCode => Object.hashAll([
    teamId.hashCode,
    idempotencyKey.hashCode,
    livemode.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['idempotencyKey'] = nativeToJson<String>(idempotencyKey);
    json['livemode'] = nativeToJson<bool>(livemode);
    return json;
  }

  GetBillingCheckoutCreationVariables({
    required this.teamId,
    required this.idempotencyKey,
    required this.livemode,
  });
}
