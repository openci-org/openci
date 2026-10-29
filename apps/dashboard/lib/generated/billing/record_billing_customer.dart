part of 'billing.dart';

class RecordBillingCustomerVariablesBuilder {
  String teamId;
  String idempotencyKey;
  bool livemode;
  String stripeCustomerId;

  final FirebaseDataConnect _dataConnect;
  RecordBillingCustomerVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.idempotencyKey,
    required this.livemode,
    required this.stripeCustomerId,
  });
  Deserializer<RecordBillingCustomerData> dataDeserializer = (dynamic json) =>
      RecordBillingCustomerData.fromJson(jsonDecode(json));
  Serializer<RecordBillingCustomerVariables> varsSerializer =
      (RecordBillingCustomerVariables vars) => jsonEncode(vars.toJson());
  Future<
    OperationResult<RecordBillingCustomerData, RecordBillingCustomerVariables>
  >
  execute() {
    return ref().execute();
  }

  MutationRef<RecordBillingCustomerData, RecordBillingCustomerVariables> ref() {
    RecordBillingCustomerVariables vars = RecordBillingCustomerVariables(
      teamId: teamId,
      idempotencyKey: idempotencyKey,
      livemode: livemode,
      stripeCustomerId: stripeCustomerId,
    );
    return _dataConnect.mutation(
      "RecordBillingCustomer",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class RecordBillingCustomerData {
  final int billingCustomerCreation_updateMany;
  RecordBillingCustomerData.fromJson(dynamic json)
    : billingCustomerCreation_updateMany = nativeFromJson<int>(
        json['billingCustomerCreation_updateMany'],
      );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final RecordBillingCustomerData otherTyped =
        other as RecordBillingCustomerData;
    return billingCustomerCreation_updateMany ==
        otherTyped.billingCustomerCreation_updateMany;
  }

  @override
  int get hashCode => billingCustomerCreation_updateMany.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['billingCustomerCreation_updateMany'] = nativeToJson<int>(
      billingCustomerCreation_updateMany,
    );
    return json;
  }

  RecordBillingCustomerData({
    required this.billingCustomerCreation_updateMany,
  });
}

@immutable
class RecordBillingCustomerVariables {
  final String teamId;
  final String idempotencyKey;
  final bool livemode;
  final String stripeCustomerId;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  RecordBillingCustomerVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']),
      idempotencyKey = nativeFromJson<String>(json['idempotencyKey']),
      livemode = nativeFromJson<bool>(json['livemode']),
      stripeCustomerId = nativeFromJson<String>(json['stripeCustomerId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final RecordBillingCustomerVariables otherTyped =
        other as RecordBillingCustomerVariables;
    return teamId == otherTyped.teamId &&
        idempotencyKey == otherTyped.idempotencyKey &&
        livemode == otherTyped.livemode &&
        stripeCustomerId == otherTyped.stripeCustomerId;
  }

  @override
  int get hashCode => Object.hashAll([
    teamId.hashCode,
    idempotencyKey.hashCode,
    livemode.hashCode,
    stripeCustomerId.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['idempotencyKey'] = nativeToJson<String>(idempotencyKey);
    json['livemode'] = nativeToJson<bool>(livemode);
    json['stripeCustomerId'] = nativeToJson<String>(stripeCustomerId);
    return json;
  }

  RecordBillingCustomerVariables({
    required this.teamId,
    required this.idempotencyKey,
    required this.livemode,
    required this.stripeCustomerId,
  });
}
