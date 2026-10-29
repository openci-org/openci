part of 'billing.dart';

class InitializeBillingStripeStateVariablesBuilder {
  String teamId;
  String stripeCustomerId;
  bool livemode;

  final FirebaseDataConnect _dataConnect;
  InitializeBillingStripeStateVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.stripeCustomerId,
    required this.livemode,
  });
  Deserializer<InitializeBillingStripeStateData> dataDeserializer =
      (dynamic json) =>
          InitializeBillingStripeStateData.fromJson(jsonDecode(json));
  Serializer<InitializeBillingStripeStateVariables> varsSerializer =
      (InitializeBillingStripeStateVariables vars) => jsonEncode(vars.toJson());
  Future<
    OperationResult<
      InitializeBillingStripeStateData,
      InitializeBillingStripeStateVariables
    >
  >
  execute() {
    return ref().execute();
  }

  MutationRef<
    InitializeBillingStripeStateData,
    InitializeBillingStripeStateVariables
  >
  ref() {
    InitializeBillingStripeStateVariables vars =
        InitializeBillingStripeStateVariables(
          teamId: teamId,
          stripeCustomerId: stripeCustomerId,
          livemode: livemode,
        );
    return _dataConnect.mutation(
      "InitializeBillingStripeState",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class InitializeBillingStripeStateBillingStripeStateInsert {
  final String teamId;
  InitializeBillingStripeStateBillingStripeStateInsert.fromJson(dynamic json)
    : teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final InitializeBillingStripeStateBillingStripeStateInsert otherTyped =
        other as InitializeBillingStripeStateBillingStripeStateInsert;
    return teamId == otherTyped.teamId;
  }

  @override
  int get hashCode => teamId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  InitializeBillingStripeStateBillingStripeStateInsert({
    required this.teamId,
  });
}

@immutable
class InitializeBillingStripeStateData {
  final InitializeBillingStripeStateBillingStripeStateInsert
  billingStripeState_insert;
  InitializeBillingStripeStateData.fromJson(dynamic json)
    : billingStripeState_insert =
          InitializeBillingStripeStateBillingStripeStateInsert.fromJson(
            json['billingStripeState_insert'],
          );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final InitializeBillingStripeStateData otherTyped =
        other as InitializeBillingStripeStateData;
    return billingStripeState_insert == otherTyped.billingStripeState_insert;
  }

  @override
  int get hashCode => billingStripeState_insert.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['billingStripeState_insert'] = billingStripeState_insert.toJson();
    return json;
  }

  InitializeBillingStripeStateData({
    required this.billingStripeState_insert,
  });
}

@immutable
class InitializeBillingStripeStateVariables {
  final String teamId;
  final String stripeCustomerId;
  final bool livemode;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  InitializeBillingStripeStateVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']),
      stripeCustomerId = nativeFromJson<String>(json['stripeCustomerId']),
      livemode = nativeFromJson<bool>(json['livemode']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final InitializeBillingStripeStateVariables otherTyped =
        other as InitializeBillingStripeStateVariables;
    return teamId == otherTyped.teamId &&
        stripeCustomerId == otherTyped.stripeCustomerId &&
        livemode == otherTyped.livemode;
  }

  @override
  int get hashCode => Object.hashAll([
    teamId.hashCode,
    stripeCustomerId.hashCode,
    livemode.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['stripeCustomerId'] = nativeToJson<String>(stripeCustomerId);
    json['livemode'] = nativeToJson<bool>(livemode);
    return json;
  }

  InitializeBillingStripeStateVariables({
    required this.teamId,
    required this.stripeCustomerId,
    required this.livemode,
  });
}
