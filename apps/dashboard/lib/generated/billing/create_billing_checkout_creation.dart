part of 'billing.dart';

class CreateBillingCheckoutCreationVariablesBuilder {
  String idempotencyKey;
  String teamId;
  String userId;
  String planId;
  String stripeCustomerId;
  String stripePriceId;
  String successUrl;
  String cancelUrl;
  bool livemode;
  BigInt createdAt;

  final FirebaseDataConnect _dataConnect;
  CreateBillingCheckoutCreationVariablesBuilder(
    this._dataConnect, {
    required this.idempotencyKey,
    required this.teamId,
    required this.userId,
    required this.planId,
    required this.stripeCustomerId,
    required this.stripePriceId,
    required this.successUrl,
    required this.cancelUrl,
    required this.livemode,
    required this.createdAt,
  });
  Deserializer<CreateBillingCheckoutCreationData> dataDeserializer =
      (dynamic json) =>
          CreateBillingCheckoutCreationData.fromJson(jsonDecode(json));
  Serializer<CreateBillingCheckoutCreationVariables> varsSerializer =
      (CreateBillingCheckoutCreationVariables vars) =>
          jsonEncode(vars.toJson());
  Future<
    OperationResult<
      CreateBillingCheckoutCreationData,
      CreateBillingCheckoutCreationVariables
    >
  >
  execute() {
    return ref().execute();
  }

  MutationRef<
    CreateBillingCheckoutCreationData,
    CreateBillingCheckoutCreationVariables
  >
  ref() {
    CreateBillingCheckoutCreationVariables vars =
        CreateBillingCheckoutCreationVariables(
          idempotencyKey: idempotencyKey,
          teamId: teamId,
          userId: userId,
          planId: planId,
          stripeCustomerId: stripeCustomerId,
          stripePriceId: stripePriceId,
          successUrl: successUrl,
          cancelUrl: cancelUrl,
          livemode: livemode,
          createdAt: createdAt,
        );
    return _dataConnect.mutation(
      "CreateBillingCheckoutCreation",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class CreateBillingCheckoutCreationBillingCheckoutCreationInsert {
  final String idempotencyKey;
  CreateBillingCheckoutCreationBillingCheckoutCreationInsert.fromJson(
    dynamic json,
  ) : idempotencyKey = nativeFromJson<String>(json['idempotencyKey']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreateBillingCheckoutCreationBillingCheckoutCreationInsert
    otherTyped =
        other as CreateBillingCheckoutCreationBillingCheckoutCreationInsert;
    return idempotencyKey == otherTyped.idempotencyKey;
  }

  @override
  int get hashCode => idempotencyKey.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['idempotencyKey'] = nativeToJson<String>(idempotencyKey);
    return json;
  }

  CreateBillingCheckoutCreationBillingCheckoutCreationInsert({
    required this.idempotencyKey,
  });
}

@immutable
class CreateBillingCheckoutCreationData {
  final CreateBillingCheckoutCreationBillingCheckoutCreationInsert
  billingCheckoutCreation_insert;
  CreateBillingCheckoutCreationData.fromJson(dynamic json)
    : billingCheckoutCreation_insert =
          CreateBillingCheckoutCreationBillingCheckoutCreationInsert.fromJson(
            json['billingCheckoutCreation_insert'],
          );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreateBillingCheckoutCreationData otherTyped =
        other as CreateBillingCheckoutCreationData;
    return billingCheckoutCreation_insert ==
        otherTyped.billingCheckoutCreation_insert;
  }

  @override
  int get hashCode => billingCheckoutCreation_insert.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['billingCheckoutCreation_insert'] = billingCheckoutCreation_insert
        .toJson();
    return json;
  }

  CreateBillingCheckoutCreationData({
    required this.billingCheckoutCreation_insert,
  });
}

@immutable
class CreateBillingCheckoutCreationVariables {
  final String idempotencyKey;
  final String teamId;
  final String userId;
  final String planId;
  final String stripeCustomerId;
  final String stripePriceId;
  final String successUrl;
  final String cancelUrl;
  final bool livemode;
  final BigInt createdAt;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  CreateBillingCheckoutCreationVariables.fromJson(Map<String, dynamic> json)
    : idempotencyKey = nativeFromJson<String>(json['idempotencyKey']),
      teamId = nativeFromJson<String>(json['teamId']),
      userId = nativeFromJson<String>(json['userId']),
      planId = nativeFromJson<String>(json['planId']),
      stripeCustomerId = nativeFromJson<String>(json['stripeCustomerId']),
      stripePriceId = nativeFromJson<String>(json['stripePriceId']),
      successUrl = nativeFromJson<String>(json['successUrl']),
      cancelUrl = nativeFromJson<String>(json['cancelUrl']),
      livemode = nativeFromJson<bool>(json['livemode']),
      createdAt = bigIntFromJson(json['createdAt']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreateBillingCheckoutCreationVariables otherTyped =
        other as CreateBillingCheckoutCreationVariables;
    return idempotencyKey == otherTyped.idempotencyKey &&
        teamId == otherTyped.teamId &&
        userId == otherTyped.userId &&
        planId == otherTyped.planId &&
        stripeCustomerId == otherTyped.stripeCustomerId &&
        stripePriceId == otherTyped.stripePriceId &&
        successUrl == otherTyped.successUrl &&
        cancelUrl == otherTyped.cancelUrl &&
        livemode == otherTyped.livemode &&
        createdAt == otherTyped.createdAt;
  }

  @override
  int get hashCode => Object.hashAll([
    idempotencyKey.hashCode,
    teamId.hashCode,
    userId.hashCode,
    planId.hashCode,
    stripeCustomerId.hashCode,
    stripePriceId.hashCode,
    successUrl.hashCode,
    cancelUrl.hashCode,
    livemode.hashCode,
    createdAt.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['idempotencyKey'] = nativeToJson<String>(idempotencyKey);
    json['teamId'] = nativeToJson<String>(teamId);
    json['userId'] = nativeToJson<String>(userId);
    json['planId'] = nativeToJson<String>(planId);
    json['stripeCustomerId'] = nativeToJson<String>(stripeCustomerId);
    json['stripePriceId'] = nativeToJson<String>(stripePriceId);
    json['successUrl'] = nativeToJson<String>(successUrl);
    json['cancelUrl'] = nativeToJson<String>(cancelUrl);
    json['livemode'] = nativeToJson<bool>(livemode);
    json['createdAt'] = bigIntToJson(createdAt);
    return json;
  }

  CreateBillingCheckoutCreationVariables({
    required this.idempotencyKey,
    required this.teamId,
    required this.userId,
    required this.planId,
    required this.stripeCustomerId,
    required this.stripePriceId,
    required this.successUrl,
    required this.cancelUrl,
    required this.livemode,
    required this.createdAt,
  });
}
