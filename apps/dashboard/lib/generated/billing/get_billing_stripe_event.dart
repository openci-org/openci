part of 'billing.dart';

class GetBillingStripeEventVariablesBuilder {
  String eventId;

  final FirebaseDataConnect _dataConnect;
  GetBillingStripeEventVariablesBuilder(
    this._dataConnect, {
    required this.eventId,
  });
  Deserializer<GetBillingStripeEventData> dataDeserializer = (dynamic json) =>
      GetBillingStripeEventData.fromJson(jsonDecode(json));
  Serializer<GetBillingStripeEventVariables> varsSerializer =
      (GetBillingStripeEventVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetBillingStripeEventData, GetBillingStripeEventVariables>>
  execute() {
    return ref().execute();
  }

  QueryRef<GetBillingStripeEventData, GetBillingStripeEventVariables> ref() {
    GetBillingStripeEventVariables vars = GetBillingStripeEventVariables(
      eventId: eventId,
    );
    return _dataConnect.query(
      "GetBillingStripeEvent",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetBillingStripeEventBillingStripeEvent {
  final String eventId;
  final String eventType;
  final BigInt eventCreated;
  final BigInt processedAt;
  GetBillingStripeEventBillingStripeEvent.fromJson(dynamic json)
    : eventId = nativeFromJson<String>(json['eventId']),
      eventType = nativeFromJson<String>(json['eventType']),
      eventCreated = bigIntFromJson(json['eventCreated']),
      processedAt = bigIntFromJson(json['processedAt']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingStripeEventBillingStripeEvent otherTyped =
        other as GetBillingStripeEventBillingStripeEvent;
    return eventId == otherTyped.eventId &&
        eventType == otherTyped.eventType &&
        eventCreated == otherTyped.eventCreated &&
        processedAt == otherTyped.processedAt;
  }

  @override
  int get hashCode => Object.hashAll([
    eventId.hashCode,
    eventType.hashCode,
    eventCreated.hashCode,
    processedAt.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['eventId'] = nativeToJson<String>(eventId);
    json['eventType'] = nativeToJson<String>(eventType);
    json['eventCreated'] = bigIntToJson(eventCreated);
    json['processedAt'] = bigIntToJson(processedAt);
    return json;
  }

  GetBillingStripeEventBillingStripeEvent({
    required this.eventId,
    required this.eventType,
    required this.eventCreated,
    required this.processedAt,
  });
}

@immutable
class GetBillingStripeEventData {
  final GetBillingStripeEventBillingStripeEvent? billingStripeEvent;
  GetBillingStripeEventData.fromJson(dynamic json)
    : billingStripeEvent = json['billingStripeEvent'] == null
          ? null
          : GetBillingStripeEventBillingStripeEvent.fromJson(
              json['billingStripeEvent'],
            );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingStripeEventData otherTyped =
        other as GetBillingStripeEventData;
    return billingStripeEvent == otherTyped.billingStripeEvent;
  }

  @override
  int get hashCode => billingStripeEvent.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (billingStripeEvent != null) {
      json['billingStripeEvent'] = billingStripeEvent!.toJson();
    }
    return json;
  }

  GetBillingStripeEventData({
    this.billingStripeEvent,
  });
}

@immutable
class GetBillingStripeEventVariables {
  final String eventId;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetBillingStripeEventVariables.fromJson(Map<String, dynamic> json)
    : eventId = nativeFromJson<String>(json['eventId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingStripeEventVariables otherTyped =
        other as GetBillingStripeEventVariables;
    return eventId == otherTyped.eventId;
  }

  @override
  int get hashCode => eventId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['eventId'] = nativeToJson<String>(eventId);
    return json;
  }

  GetBillingStripeEventVariables({
    required this.eventId,
  });
}
