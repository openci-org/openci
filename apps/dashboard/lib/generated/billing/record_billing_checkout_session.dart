part of 'billing.dart';

class RecordBillingCheckoutSessionVariablesBuilder {
  String idempotencyKey;
  String teamId;
  String planId;
  String stripeCustomerId;
  String stripePriceId;
  String successUrl;
  String cancelUrl;
  bool livemode;
  BigInt createdAt;
  String stripeCheckoutSessionId;

  final FirebaseDataConnect _dataConnect;
  RecordBillingCheckoutSessionVariablesBuilder(
    this._dataConnect, {
    required this.idempotencyKey,
    required this.teamId,
    required this.planId,
    required this.stripeCustomerId,
    required this.stripePriceId,
    required this.successUrl,
    required this.cancelUrl,
    required this.livemode,
    required this.createdAt,
    required this.stripeCheckoutSessionId,
  });
  Deserializer<RecordBillingCheckoutSessionData> dataDeserializer =
      (dynamic json) =>
          RecordBillingCheckoutSessionData.fromJson(jsonDecode(json));
  Serializer<RecordBillingCheckoutSessionVariables> varsSerializer =
      (RecordBillingCheckoutSessionVariables vars) => jsonEncode(vars.toJson());
  Future<
    OperationResult<
      RecordBillingCheckoutSessionData,
      RecordBillingCheckoutSessionVariables
    >
  >
  execute() {
    return ref().execute();
  }

  MutationRef<
    RecordBillingCheckoutSessionData,
    RecordBillingCheckoutSessionVariables
  >
  ref() {
    RecordBillingCheckoutSessionVariables vars =
        RecordBillingCheckoutSessionVariables(
          idempotencyKey: idempotencyKey,
          teamId: teamId,
          planId: planId,
          stripeCustomerId: stripeCustomerId,
          stripePriceId: stripePriceId,
          successUrl: successUrl,
          cancelUrl: cancelUrl,
          livemode: livemode,
          createdAt: createdAt,
          stripeCheckoutSessionId: stripeCheckoutSessionId,
        );
    return _dataConnect.mutation(
      "RecordBillingCheckoutSession",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class RecordBillingCheckoutSessionData {
  final int billingCheckoutCreation_updateMany;
  RecordBillingCheckoutSessionData.fromJson(dynamic json)
    : billingCheckoutCreation_updateMany = nativeFromJson<int>(
        json['billingCheckoutCreation_updateMany'],
      );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final RecordBillingCheckoutSessionData otherTyped =
        other as RecordBillingCheckoutSessionData;
    return billingCheckoutCreation_updateMany ==
        otherTyped.billingCheckoutCreation_updateMany;
  }

  @override
  int get hashCode => billingCheckoutCreation_updateMany.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['billingCheckoutCreation_updateMany'] = nativeToJson<int>(
      billingCheckoutCreation_updateMany,
    );
    return json;
  }

  RecordBillingCheckoutSessionData({
    required this.billingCheckoutCreation_updateMany,
  });
}

@immutable
class RecordBillingCheckoutSessionVariables {
  final String idempotencyKey;
  final String teamId;
  final String planId;
  final String stripeCustomerId;
  final String stripePriceId;
  final String successUrl;
  final String cancelUrl;
  final bool livemode;
  final BigInt createdAt;
  final String stripeCheckoutSessionId;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  RecordBillingCheckoutSessionVariables.fromJson(Map<String, dynamic> json)
    : idempotencyKey = nativeFromJson<String>(json['idempotencyKey']),
      teamId = nativeFromJson<String>(json['teamId']),
      planId = nativeFromJson<String>(json['planId']),
      stripeCustomerId = nativeFromJson<String>(json['stripeCustomerId']),
      stripePriceId = nativeFromJson<String>(json['stripePriceId']),
      successUrl = nativeFromJson<String>(json['successUrl']),
      cancelUrl = nativeFromJson<String>(json['cancelUrl']),
      livemode = nativeFromJson<bool>(json['livemode']),
      createdAt = bigIntFromJson(json['createdAt']),
      stripeCheckoutSessionId = nativeFromJson<String>(
        json['stripeCheckoutSessionId'],
      );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final RecordBillingCheckoutSessionVariables otherTyped =
        other as RecordBillingCheckoutSessionVariables;
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
    json['stripeCheckoutSessionId'] = nativeToJson<String>(
      stripeCheckoutSessionId,
    );
    return json;
  }

  RecordBillingCheckoutSessionVariables({
    required this.idempotencyKey,
    required this.teamId,
    required this.planId,
    required this.stripeCustomerId,
    required this.stripePriceId,
    required this.successUrl,
    required this.cancelUrl,
    required this.livemode,
    required this.createdAt,
    required this.stripeCheckoutSessionId,
  });
}
