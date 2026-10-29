part of 'billing.dart';

class CloseBillingCheckoutCreationVariablesBuilder {
  String idempotencyKey;
  String teamId;
  String stripeCustomerId;
  bool livemode;
  String stripeCheckoutSessionId;
  BigInt closedAt;

  final FirebaseDataConnect _dataConnect;
  CloseBillingCheckoutCreationVariablesBuilder(
    this._dataConnect, {
    required this.idempotencyKey,
    required this.teamId,
    required this.stripeCustomerId,
    required this.livemode,
    required this.stripeCheckoutSessionId,
    required this.closedAt,
  });
  Deserializer<CloseBillingCheckoutCreationData> dataDeserializer =
      (dynamic json) =>
          CloseBillingCheckoutCreationData.fromJson(jsonDecode(json));
  Serializer<CloseBillingCheckoutCreationVariables> varsSerializer =
      (CloseBillingCheckoutCreationVariables vars) => jsonEncode(vars.toJson());
  Future<
    OperationResult<
      CloseBillingCheckoutCreationData,
      CloseBillingCheckoutCreationVariables
    >
  >
  execute() {
    return ref().execute();
  }

  MutationRef<
    CloseBillingCheckoutCreationData,
    CloseBillingCheckoutCreationVariables
  >
  ref() {
    CloseBillingCheckoutCreationVariables vars =
        CloseBillingCheckoutCreationVariables(
          idempotencyKey: idempotencyKey,
          teamId: teamId,
          stripeCustomerId: stripeCustomerId,
          livemode: livemode,
          stripeCheckoutSessionId: stripeCheckoutSessionId,
          closedAt: closedAt,
        );
    return _dataConnect.mutation(
      "CloseBillingCheckoutCreation",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class CloseBillingCheckoutCreationData {
  final int billingCheckoutCreation_updateMany;
  CloseBillingCheckoutCreationData.fromJson(dynamic json)
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

    final CloseBillingCheckoutCreationData otherTyped =
        other as CloseBillingCheckoutCreationData;
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

  CloseBillingCheckoutCreationData({
    required this.billingCheckoutCreation_updateMany,
  });
}

@immutable
class CloseBillingCheckoutCreationVariables {
  final String idempotencyKey;
  final String teamId;
  final String stripeCustomerId;
  final bool livemode;
  final String stripeCheckoutSessionId;
  final BigInt closedAt;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  CloseBillingCheckoutCreationVariables.fromJson(Map<String, dynamic> json)
    : idempotencyKey = nativeFromJson<String>(json['idempotencyKey']),
      teamId = nativeFromJson<String>(json['teamId']),
      stripeCustomerId = nativeFromJson<String>(json['stripeCustomerId']),
      livemode = nativeFromJson<bool>(json['livemode']),
      stripeCheckoutSessionId = nativeFromJson<String>(
        json['stripeCheckoutSessionId'],
      ),
      closedAt = bigIntFromJson(json['closedAt']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CloseBillingCheckoutCreationVariables otherTyped =
        other as CloseBillingCheckoutCreationVariables;
    return idempotencyKey == otherTyped.idempotencyKey &&
        teamId == otherTyped.teamId &&
        stripeCustomerId == otherTyped.stripeCustomerId &&
        livemode == otherTyped.livemode &&
        stripeCheckoutSessionId == otherTyped.stripeCheckoutSessionId &&
        closedAt == otherTyped.closedAt;
  }

  @override
  int get hashCode => Object.hashAll([
    idempotencyKey.hashCode,
    teamId.hashCode,
    stripeCustomerId.hashCode,
    livemode.hashCode,
    stripeCheckoutSessionId.hashCode,
    closedAt.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['idempotencyKey'] = nativeToJson<String>(idempotencyKey);
    json['teamId'] = nativeToJson<String>(teamId);
    json['stripeCustomerId'] = nativeToJson<String>(stripeCustomerId);
    json['livemode'] = nativeToJson<bool>(livemode);
    json['stripeCheckoutSessionId'] = nativeToJson<String>(
      stripeCheckoutSessionId,
    );
    json['closedAt'] = bigIntToJson(closedAt);
    return json;
  }

  CloseBillingCheckoutCreationVariables({
    required this.idempotencyKey,
    required this.teamId,
    required this.stripeCustomerId,
    required this.livemode,
    required this.stripeCheckoutSessionId,
    required this.closedAt,
  });
}
