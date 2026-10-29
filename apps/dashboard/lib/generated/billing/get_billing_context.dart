part of 'billing.dart';

class GetBillingContextVariablesBuilder {
  String teamId;
  String userId;

  final FirebaseDataConnect _dataConnect;
  GetBillingContextVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.userId,
  });
  Deserializer<GetBillingContextData> dataDeserializer = (dynamic json) =>
      GetBillingContextData.fromJson(jsonDecode(json));
  Serializer<GetBillingContextVariables> varsSerializer =
      (GetBillingContextVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetBillingContextData, GetBillingContextVariables>>
  execute() {
    return ref().execute();
  }

  QueryRef<GetBillingContextData, GetBillingContextVariables> ref() {
    GetBillingContextVariables vars = GetBillingContextVariables(
      teamId: teamId,
      userId: userId,
    );
    return _dataConnect.query(
      "GetBillingContext",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetBillingContextAccount {
  final BigInt usageRevision;
  GetBillingContextAccount.fromJson(dynamic json)
    : usageRevision = bigIntFromJson(json['usageRevision']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingContextAccount otherTyped =
        other as GetBillingContextAccount;
    return usageRevision == otherTyped.usageRevision;
  }

  @override
  int get hashCode => usageRevision.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['usageRevision'] = bigIntToJson(usageRevision);
    return json;
  }

  GetBillingContextAccount({
    required this.usageRevision,
  });
}

@immutable
class GetBillingContextCustomer {
  final String teamId;
  final String idempotencyKey;
  final bool livemode;
  final BigInt createdAt;
  final String? stripeCustomerId;
  GetBillingContextCustomer.fromJson(dynamic json)
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

    final GetBillingContextCustomer otherTyped =
        other as GetBillingContextCustomer;
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

  GetBillingContextCustomer({
    required this.teamId,
    required this.idempotencyKey,
    required this.livemode,
    required this.createdAt,
    this.stripeCustomerId,
  });
}

@immutable
class GetBillingContextStripe {
  final String teamId;
  final String stripeCustomerId;
  final bool livemode;
  final String? stripeSubscriptionId;
  final String subscriptionStatus;
  final String? planId;
  final String? paidPeriodId;
  final GetBillingContextStripePaidPeriod? paidPeriod;
  final bool cancelAtPeriodEnd;
  final BigInt syncedAt;
  final BigInt revision;
  GetBillingContextStripe.fromJson(dynamic json)
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
          : GetBillingContextStripePaidPeriod.fromJson(json['paidPeriod']),
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

    final GetBillingContextStripe otherTyped = other as GetBillingContextStripe;
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

  GetBillingContextStripe({
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
class GetBillingContextStripePaidPeriod {
  final String id;
  final String teamId;
  final String planId;
  final String periodType;
  final BigInt startsAt;
  final BigInt endsAt;
  final BigInt? allowanceSeconds;
  GetBillingContextStripePaidPeriod.fromJson(dynamic json)
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

    final GetBillingContextStripePaidPeriod otherTyped =
        other as GetBillingContextStripePaidPeriod;
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

  GetBillingContextStripePaidPeriod({
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
class GetBillingContextCheckout {
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
  GetBillingContextCheckout.fromJson(dynamic json)
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

    final GetBillingContextCheckout otherTyped =
        other as GetBillingContextCheckout;
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

  GetBillingContextCheckout({
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
class GetBillingContextData {
  final GetBillingContextAccount? account;
  final GetBillingContextCustomer? customer;
  final GetBillingContextStripe? stripe;
  final GetBillingContextCheckout? checkout;
  GetBillingContextData.fromJson(dynamic json)
    : account = json['account'] == null
          ? null
          : GetBillingContextAccount.fromJson(json['account']),
      customer = json['customer'] == null
          ? null
          : GetBillingContextCustomer.fromJson(json['customer']),
      stripe = json['stripe'] == null
          ? null
          : GetBillingContextStripe.fromJson(json['stripe']),
      checkout = json['checkout'] == null
          ? null
          : GetBillingContextCheckout.fromJson(json['checkout']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingContextData otherTyped = other as GetBillingContextData;
    return account == otherTyped.account &&
        customer == otherTyped.customer &&
        stripe == otherTyped.stripe &&
        checkout == otherTyped.checkout;
  }

  @override
  int get hashCode => Object.hashAll([
    account.hashCode,
    customer.hashCode,
    stripe.hashCode,
    checkout.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (account != null) {
      json['account'] = account!.toJson();
    }
    if (customer != null) {
      json['customer'] = customer!.toJson();
    }
    if (stripe != null) {
      json['stripe'] = stripe!.toJson();
    }
    if (checkout != null) {
      json['checkout'] = checkout!.toJson();
    }
    return json;
  }

  GetBillingContextData({
    this.account,
    this.customer,
    this.stripe,
    this.checkout,
  });
}

@immutable
class GetBillingContextVariables {
  final String teamId;
  final String userId;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetBillingContextVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']),
      userId = nativeFromJson<String>(json['userId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingContextVariables otherTyped =
        other as GetBillingContextVariables;
    return teamId == otherTyped.teamId && userId == otherTyped.userId;
  }

  @override
  int get hashCode => Object.hashAll([teamId.hashCode, userId.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['userId'] = nativeToJson<String>(userId);
    return json;
  }

  GetBillingContextVariables({
    required this.teamId,
    required this.userId,
  });
}
