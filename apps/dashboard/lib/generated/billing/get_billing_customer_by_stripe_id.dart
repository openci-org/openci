part of 'billing.dart';

class GetBillingCustomerByStripeIdVariablesBuilder {
  String stripeCustomerId;
  bool livemode;

  final FirebaseDataConnect _dataConnect;
  GetBillingCustomerByStripeIdVariablesBuilder(
    this._dataConnect, {
    required this.stripeCustomerId,
    required this.livemode,
  });
  Deserializer<GetBillingCustomerByStripeIdData> dataDeserializer =
      (dynamic json) =>
          GetBillingCustomerByStripeIdData.fromJson(jsonDecode(json));
  Serializer<GetBillingCustomerByStripeIdVariables> varsSerializer =
      (GetBillingCustomerByStripeIdVariables vars) => jsonEncode(vars.toJson());
  Future<
    QueryResult<
      GetBillingCustomerByStripeIdData,
      GetBillingCustomerByStripeIdVariables
    >
  >
  execute() {
    return ref().execute();
  }

  QueryRef<
    GetBillingCustomerByStripeIdData,
    GetBillingCustomerByStripeIdVariables
  >
  ref() {
    GetBillingCustomerByStripeIdVariables vars =
        GetBillingCustomerByStripeIdVariables(
          stripeCustomerId: stripeCustomerId,
          livemode: livemode,
        );
    return _dataConnect.query(
      "GetBillingCustomerByStripeId",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetBillingCustomerByStripeIdCustomer {
  final String teamId;
  final String idempotencyKey;
  final bool livemode;
  final BigInt createdAt;
  final String? stripeCustomerId;
  GetBillingCustomerByStripeIdCustomer.fromJson(dynamic json)
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

    final GetBillingCustomerByStripeIdCustomer otherTyped =
        other as GetBillingCustomerByStripeIdCustomer;
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

  GetBillingCustomerByStripeIdCustomer({
    required this.teamId,
    required this.idempotencyKey,
    required this.livemode,
    required this.createdAt,
    this.stripeCustomerId,
  });
}

@immutable
class GetBillingCustomerByStripeIdData {
  final GetBillingCustomerByStripeIdCustomer? customer;
  GetBillingCustomerByStripeIdData.fromJson(dynamic json)
    : customer = json['customer'] == null
          ? null
          : GetBillingCustomerByStripeIdCustomer.fromJson(json['customer']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingCustomerByStripeIdData otherTyped =
        other as GetBillingCustomerByStripeIdData;
    return customer == otherTyped.customer;
  }

  @override
  int get hashCode => customer.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (customer != null) {
      json['customer'] = customer!.toJson();
    }
    return json;
  }

  GetBillingCustomerByStripeIdData({
    this.customer,
  });
}

@immutable
class GetBillingCustomerByStripeIdVariables {
  final String stripeCustomerId;
  final bool livemode;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetBillingCustomerByStripeIdVariables.fromJson(Map<String, dynamic> json)
    : stripeCustomerId = nativeFromJson<String>(json['stripeCustomerId']),
      livemode = nativeFromJson<bool>(json['livemode']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingCustomerByStripeIdVariables otherTyped =
        other as GetBillingCustomerByStripeIdVariables;
    return stripeCustomerId == otherTyped.stripeCustomerId &&
        livemode == otherTyped.livemode;
  }

  @override
  int get hashCode =>
      Object.hashAll([stripeCustomerId.hashCode, livemode.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['stripeCustomerId'] = nativeToJson<String>(stripeCustomerId);
    json['livemode'] = nativeToJson<bool>(livemode);
    return json;
  }

  GetBillingCustomerByStripeIdVariables({
    required this.stripeCustomerId,
    required this.livemode,
  });
}
