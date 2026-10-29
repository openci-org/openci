part of 'billing.dart';

class GetBillingStripeStateVariablesBuilder {
  String teamId;
  bool livemode;

  final FirebaseDataConnect _dataConnect;
  GetBillingStripeStateVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.livemode,
  });
  Deserializer<GetBillingStripeStateData> dataDeserializer = (dynamic json) =>
      GetBillingStripeStateData.fromJson(jsonDecode(json));
  Serializer<GetBillingStripeStateVariables> varsSerializer =
      (GetBillingStripeStateVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetBillingStripeStateData, GetBillingStripeStateVariables>>
  execute() {
    return ref().execute();
  }

  QueryRef<GetBillingStripeStateData, GetBillingStripeStateVariables> ref() {
    GetBillingStripeStateVariables vars = GetBillingStripeStateVariables(
      teamId: teamId,
      livemode: livemode,
    );
    return _dataConnect.query(
      "GetBillingStripeState",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetBillingStripeStateBillingStripeState {
  final String teamId;
  final String stripeCustomerId;
  final bool livemode;
  final String? stripeSubscriptionId;
  final String subscriptionStatus;
  final String? planId;
  final String? paidPeriodId;
  final GetBillingStripeStateBillingStripeStatePaidPeriod? paidPeriod;
  final bool cancelAtPeriodEnd;
  final BigInt syncedAt;
  final BigInt revision;
  GetBillingStripeStateBillingStripeState.fromJson(dynamic json)
    : teamId = nativeFromJson<String>(json['teamId']),
      stripeCustomerId = nativeFromJson<String>(json['stripeCustomerId']),
      livemode = nativeFromJson<bool>(json['livemode']),
      stripeSubscriptionId = json['stripeSubscriptionId'] == null
          ? null
          : nativeFromJson<String>(json['stripeSubscriptionId']),
      subscriptionStatus = nativeFromJson<String>(json['subscriptionStatus']),
      planId = json['planId'] == null
          ? null
          : nativeFromJson<String>(json['planId']),
      paidPeriodId = json['paidPeriodId'] == null
          ? null
          : nativeFromJson<String>(json['paidPeriodId']),
      paidPeriod = json['paidPeriod'] == null
          ? null
          : GetBillingStripeStateBillingStripeStatePaidPeriod.fromJson(
              json['paidPeriod'],
            ),
      cancelAtPeriodEnd = nativeFromJson<bool>(json['cancelAtPeriodEnd']),
      syncedAt = bigIntFromJson(json['syncedAt']),
      revision = bigIntFromJson(json['revision']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingStripeStateBillingStripeState otherTyped =
        other as GetBillingStripeStateBillingStripeState;
    return teamId == otherTyped.teamId &&
        stripeCustomerId == otherTyped.stripeCustomerId &&
        livemode == otherTyped.livemode &&
        stripeSubscriptionId == otherTyped.stripeSubscriptionId &&
        subscriptionStatus == otherTyped.subscriptionStatus &&
        planId == otherTyped.planId &&
        paidPeriodId == otherTyped.paidPeriodId &&
        paidPeriod == otherTyped.paidPeriod &&
        cancelAtPeriodEnd == otherTyped.cancelAtPeriodEnd &&
        syncedAt == otherTyped.syncedAt &&
        revision == otherTyped.revision;
  }

  @override
  int get hashCode => Object.hashAll([
    teamId.hashCode,
    stripeCustomerId.hashCode,
    livemode.hashCode,
    stripeSubscriptionId.hashCode,
    subscriptionStatus.hashCode,
    planId.hashCode,
    paidPeriodId.hashCode,
    paidPeriod.hashCode,
    cancelAtPeriodEnd.hashCode,
    syncedAt.hashCode,
    revision.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['stripeCustomerId'] = nativeToJson<String>(stripeCustomerId);
    json['livemode'] = nativeToJson<bool>(livemode);
    if (stripeSubscriptionId != null) {
      json['stripeSubscriptionId'] = nativeToJson<String?>(
        stripeSubscriptionId,
      );
    }
    json['subscriptionStatus'] = nativeToJson<String>(subscriptionStatus);
    if (planId != null) {
      json['planId'] = nativeToJson<String?>(planId);
    }
    if (paidPeriodId != null) {
      json['paidPeriodId'] = nativeToJson<String?>(paidPeriodId);
    }
    if (paidPeriod != null) {
      json['paidPeriod'] = paidPeriod!.toJson();
    }
    json['cancelAtPeriodEnd'] = nativeToJson<bool>(cancelAtPeriodEnd);
    json['syncedAt'] = bigIntToJson(syncedAt);
    json['revision'] = bigIntToJson(revision);
    return json;
  }

  GetBillingStripeStateBillingStripeState({
    required this.teamId,
    required this.stripeCustomerId,
    required this.livemode,
    this.stripeSubscriptionId,
    required this.subscriptionStatus,
    this.planId,
    this.paidPeriodId,
    this.paidPeriod,
    required this.cancelAtPeriodEnd,
    required this.syncedAt,
    required this.revision,
  });
}

@immutable
class GetBillingStripeStateBillingStripeStatePaidPeriod {
  final BigInt endsAt;
  GetBillingStripeStateBillingStripeStatePaidPeriod.fromJson(dynamic json)
    : endsAt = bigIntFromJson(json['endsAt']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingStripeStateBillingStripeStatePaidPeriod otherTyped =
        other as GetBillingStripeStateBillingStripeStatePaidPeriod;
    return endsAt == otherTyped.endsAt;
  }

  @override
  int get hashCode => endsAt.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['endsAt'] = bigIntToJson(endsAt);
    return json;
  }

  GetBillingStripeStateBillingStripeStatePaidPeriod({
    required this.endsAt,
  });
}

@immutable
class GetBillingStripeStateData {
  final GetBillingStripeStateBillingStripeState? billingStripeState;
  GetBillingStripeStateData.fromJson(dynamic json)
    : billingStripeState = json['billingStripeState'] == null
          ? null
          : GetBillingStripeStateBillingStripeState.fromJson(
              json['billingStripeState'],
            );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingStripeStateData otherTyped =
        other as GetBillingStripeStateData;
    return billingStripeState == otherTyped.billingStripeState;
  }

  @override
  int get hashCode => billingStripeState.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (billingStripeState != null) {
      json['billingStripeState'] = billingStripeState!.toJson();
    }
    return json;
  }

  GetBillingStripeStateData({
    this.billingStripeState,
  });
}

@immutable
class GetBillingStripeStateVariables {
  final String teamId;
  final bool livemode;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetBillingStripeStateVariables.fromJson(Map<String, dynamic> json)
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

    final GetBillingStripeStateVariables otherTyped =
        other as GetBillingStripeStateVariables;
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

  GetBillingStripeStateVariables({
    required this.teamId,
    required this.livemode,
  });
}
