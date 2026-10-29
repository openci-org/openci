part of 'billing.dart';

class RecordBillingStripeEventVariablesBuilder {
  String teamId;
  String stripeCustomerId;
  bool livemode;
  BigInt expectedRevision;
  Optional<String> _stripeSubscriptionId = Optional.optional(
    nativeFromJson,
    nativeToJson,
  );
  String subscriptionStatus;
  Optional<String> _planId = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _paidPeriodId = Optional.optional(
    nativeFromJson,
    nativeToJson,
  );
  bool cancelAtPeriodEnd;
  String eventId;
  String eventType;
  BigInt eventCreated;
  BigInt processedAt;

  final FirebaseDataConnect _dataConnect;
  RecordBillingStripeEventVariablesBuilder stripeSubscriptionId(String? t) {
    _stripeSubscriptionId.value = t;
    return this;
  }

  RecordBillingStripeEventVariablesBuilder planId(String? t) {
    _planId.value = t;
    return this;
  }

  RecordBillingStripeEventVariablesBuilder paidPeriodId(String? t) {
    _paidPeriodId.value = t;
    return this;
  }

  RecordBillingStripeEventVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.stripeCustomerId,
    required this.livemode,
    required this.expectedRevision,
    required this.subscriptionStatus,
    required this.cancelAtPeriodEnd,
    required this.eventId,
    required this.eventType,
    required this.eventCreated,
    required this.processedAt,
  });
  Deserializer<RecordBillingStripeEventData> dataDeserializer =
      (dynamic json) => RecordBillingStripeEventData.fromJson(jsonDecode(json));
  Serializer<RecordBillingStripeEventVariables> varsSerializer =
      (RecordBillingStripeEventVariables vars) => jsonEncode(vars.toJson());
  Future<
    OperationResult<
      RecordBillingStripeEventData,
      RecordBillingStripeEventVariables
    >
  >
  execute() {
    return ref().execute();
  }

  MutationRef<RecordBillingStripeEventData, RecordBillingStripeEventVariables>
  ref() {
    RecordBillingStripeEventVariables vars = RecordBillingStripeEventVariables(
      teamId: teamId,
      stripeCustomerId: stripeCustomerId,
      livemode: livemode,
      expectedRevision: expectedRevision,
      stripeSubscriptionId: _stripeSubscriptionId,
      subscriptionStatus: subscriptionStatus,
      planId: _planId,
      paidPeriodId: _paidPeriodId,
      cancelAtPeriodEnd: cancelAtPeriodEnd,
      eventId: eventId,
      eventType: eventType,
      eventCreated: eventCreated,
      processedAt: processedAt,
    );
    return _dataConnect.mutation(
      "RecordBillingStripeEvent",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class RecordBillingStripeEventBillingStripeEventInsert {
  final String eventId;
  RecordBillingStripeEventBillingStripeEventInsert.fromJson(dynamic json)
    : eventId = nativeFromJson<String>(json['eventId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final RecordBillingStripeEventBillingStripeEventInsert otherTyped =
        other as RecordBillingStripeEventBillingStripeEventInsert;
    return eventId == otherTyped.eventId;
  }

  @override
  int get hashCode => eventId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['eventId'] = nativeToJson<String>(eventId);
    return json;
  }

  RecordBillingStripeEventBillingStripeEventInsert({
    required this.eventId,
  });
}

@immutable
class RecordBillingStripeEventData {
  final int billingStripeState_updateMany;
  final RecordBillingStripeEventBillingStripeEventInsert
  billingStripeEvent_insert;
  RecordBillingStripeEventData.fromJson(dynamic json)
    : billingStripeState_updateMany = nativeFromJson<int>(
        json['billingStripeState_updateMany'],
      ),
      billingStripeEvent_insert =
          RecordBillingStripeEventBillingStripeEventInsert.fromJson(
            json['billingStripeEvent_insert'],
          );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final RecordBillingStripeEventData otherTyped =
        other as RecordBillingStripeEventData;
    return billingStripeState_updateMany ==
            otherTyped.billingStripeState_updateMany &&
        billingStripeEvent_insert == otherTyped.billingStripeEvent_insert;
  }

  @override
  int get hashCode => Object.hashAll([
    billingStripeState_updateMany.hashCode,
    billingStripeEvent_insert.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['billingStripeState_updateMany'] = nativeToJson<int>(
      billingStripeState_updateMany,
    );
    json['billingStripeEvent_insert'] = billingStripeEvent_insert.toJson();
    return json;
  }

  RecordBillingStripeEventData({
    required this.billingStripeState_updateMany,
    required this.billingStripeEvent_insert,
  });
}

@immutable
class RecordBillingStripeEventVariables {
  final String teamId;
  final String stripeCustomerId;
  final bool livemode;
  final BigInt expectedRevision;
  late final Optional<String> stripeSubscriptionId;
  final String subscriptionStatus;
  late final Optional<String> planId;
  late final Optional<String> paidPeriodId;
  final bool cancelAtPeriodEnd;
  final String eventId;
  final String eventType;
  final BigInt eventCreated;
  final BigInt processedAt;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  RecordBillingStripeEventVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']),
      stripeCustomerId = nativeFromJson<String>(json['stripeCustomerId']),
      livemode = nativeFromJson<bool>(json['livemode']),
      expectedRevision = bigIntFromJson(json['expectedRevision']),
      subscriptionStatus = nativeFromJson<String>(json['subscriptionStatus']),
      cancelAtPeriodEnd = nativeFromJson<bool>(json['cancelAtPeriodEnd']),
      eventId = nativeFromJson<String>(json['eventId']),
      eventType = nativeFromJson<String>(json['eventType']),
      eventCreated = bigIntFromJson(json['eventCreated']),
      processedAt = bigIntFromJson(json['processedAt']) {
    stripeSubscriptionId = Optional.optional(nativeFromJson, nativeToJson);
    stripeSubscriptionId.value = json['stripeSubscriptionId'] == null
        ? null
        : nativeFromJson<String>(json['stripeSubscriptionId']);

    planId = Optional.optional(nativeFromJson, nativeToJson);
    planId.value = json['planId'] == null
        ? null
        : nativeFromJson<String>(json['planId']);

    paidPeriodId = Optional.optional(nativeFromJson, nativeToJson);
    paidPeriodId.value = json['paidPeriodId'] == null
        ? null
        : nativeFromJson<String>(json['paidPeriodId']);
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final RecordBillingStripeEventVariables otherTyped =
        other as RecordBillingStripeEventVariables;
    return teamId == otherTyped.teamId &&
        stripeCustomerId == otherTyped.stripeCustomerId &&
        livemode == otherTyped.livemode &&
        expectedRevision == otherTyped.expectedRevision &&
        stripeSubscriptionId == otherTyped.stripeSubscriptionId &&
        subscriptionStatus == otherTyped.subscriptionStatus &&
        planId == otherTyped.planId &&
        paidPeriodId == otherTyped.paidPeriodId &&
        cancelAtPeriodEnd == otherTyped.cancelAtPeriodEnd &&
        eventId == otherTyped.eventId &&
        eventType == otherTyped.eventType &&
        eventCreated == otherTyped.eventCreated &&
        processedAt == otherTyped.processedAt;
  }

  @override
  int get hashCode => Object.hashAll([
    teamId.hashCode,
    stripeCustomerId.hashCode,
    livemode.hashCode,
    expectedRevision.hashCode,
    stripeSubscriptionId.hashCode,
    subscriptionStatus.hashCode,
    planId.hashCode,
    paidPeriodId.hashCode,
    cancelAtPeriodEnd.hashCode,
    eventId.hashCode,
    eventType.hashCode,
    eventCreated.hashCode,
    processedAt.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['stripeCustomerId'] = nativeToJson<String>(stripeCustomerId);
    json['livemode'] = nativeToJson<bool>(livemode);
    json['expectedRevision'] = bigIntToJson(expectedRevision);
    if (stripeSubscriptionId.state == OptionalState.set) {
      json['stripeSubscriptionId'] = stripeSubscriptionId.toJson();
    }
    json['subscriptionStatus'] = nativeToJson<String>(subscriptionStatus);
    if (planId.state == OptionalState.set) {
      json['planId'] = planId.toJson();
    }
    if (paidPeriodId.state == OptionalState.set) {
      json['paidPeriodId'] = paidPeriodId.toJson();
    }
    json['cancelAtPeriodEnd'] = nativeToJson<bool>(cancelAtPeriodEnd);
    json['eventId'] = nativeToJson<String>(eventId);
    json['eventType'] = nativeToJson<String>(eventType);
    json['eventCreated'] = bigIntToJson(eventCreated);
    json['processedAt'] = bigIntToJson(processedAt);
    return json;
  }

  RecordBillingStripeEventVariables({
    required this.teamId,
    required this.stripeCustomerId,
    required this.livemode,
    required this.expectedRevision,
    required this.stripeSubscriptionId,
    required this.subscriptionStatus,
    required this.planId,
    required this.paidPeriodId,
    required this.cancelAtPeriodEnd,
    required this.eventId,
    required this.eventType,
    required this.eventCreated,
    required this.processedAt,
  });
}
