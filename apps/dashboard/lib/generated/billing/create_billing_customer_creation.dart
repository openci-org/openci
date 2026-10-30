part of 'billing.dart';

class CreateBillingCustomerCreationVariablesBuilder {
  String teamId;
  String userId;
  String idempotencyKey;
  bool livemode;
  BigInt createdAt;

  final FirebaseDataConnect _dataConnect;
  CreateBillingCustomerCreationVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.userId,
    required this.idempotencyKey,
    required this.livemode,
    required this.createdAt,
  });
  Deserializer<CreateBillingCustomerCreationData> dataDeserializer =
      (dynamic json) =>
          CreateBillingCustomerCreationData.fromJson(jsonDecode(json));
  Serializer<CreateBillingCustomerCreationVariables> varsSerializer =
      (CreateBillingCustomerCreationVariables vars) =>
          jsonEncode(vars.toJson());
  Future<
    OperationResult<
      CreateBillingCustomerCreationData,
      CreateBillingCustomerCreationVariables
    >
  >
  execute() {
    return ref().execute();
  }

  MutationRef<
    CreateBillingCustomerCreationData,
    CreateBillingCustomerCreationVariables
  >
  ref() {
    CreateBillingCustomerCreationVariables vars =
        CreateBillingCustomerCreationVariables(
          teamId: teamId,
          userId: userId,
          idempotencyKey: idempotencyKey,
          livemode: livemode,
          createdAt: createdAt,
        );
    return _dataConnect.mutation(
      "CreateBillingCustomerCreation",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class CreateBillingCustomerCreationBillingAccountUpsert {
  final String teamId;
  CreateBillingCustomerCreationBillingAccountUpsert.fromJson(dynamic json)
    : teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreateBillingCustomerCreationBillingAccountUpsert otherTyped =
        other as CreateBillingCustomerCreationBillingAccountUpsert;
    return teamId == otherTyped.teamId;
  }

  @override
  int get hashCode => teamId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  CreateBillingCustomerCreationBillingAccountUpsert({
    required this.teamId,
  });
}

@immutable
class CreateBillingCustomerCreationBillingCustomerCreationInsert {
  final String teamId;
  CreateBillingCustomerCreationBillingCustomerCreationInsert.fromJson(
    dynamic json,
  ) : teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreateBillingCustomerCreationBillingCustomerCreationInsert
    otherTyped =
        other as CreateBillingCustomerCreationBillingCustomerCreationInsert;
    return teamId == otherTyped.teamId;
  }

  @override
  int get hashCode => teamId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  CreateBillingCustomerCreationBillingCustomerCreationInsert({
    required this.teamId,
  });
}

@immutable
class CreateBillingCustomerCreationData {
  final CreateBillingCustomerCreationBillingAccountUpsert billingAccount_upsert;
  final CreateBillingCustomerCreationBillingCustomerCreationInsert
  billingCustomerCreation_insert;
  CreateBillingCustomerCreationData.fromJson(dynamic json)
    : billingAccount_upsert =
          CreateBillingCustomerCreationBillingAccountUpsert.fromJson(
            json['billingAccount_upsert'],
          ),
      billingCustomerCreation_insert =
          CreateBillingCustomerCreationBillingCustomerCreationInsert.fromJson(
            json['billingCustomerCreation_insert'],
          );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreateBillingCustomerCreationData otherTyped =
        other as CreateBillingCustomerCreationData;
    return billingAccount_upsert == otherTyped.billingAccount_upsert &&
        billingCustomerCreation_insert ==
            otherTyped.billingCustomerCreation_insert;
  }

  @override
  int get hashCode => Object.hashAll([
    billingAccount_upsert.hashCode,
    billingCustomerCreation_insert.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['billingAccount_upsert'] = billingAccount_upsert.toJson();
    json['billingCustomerCreation_insert'] = billingCustomerCreation_insert
        .toJson();
    return json;
  }

  CreateBillingCustomerCreationData({
    required this.billingAccount_upsert,
    required this.billingCustomerCreation_insert,
  });
}

@immutable
class CreateBillingCustomerCreationVariables {
  final String teamId;
  final String userId;
  final String idempotencyKey;
  final bool livemode;
  final BigInt createdAt;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  CreateBillingCustomerCreationVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']),
      userId = nativeFromJson<String>(json['userId']),
      idempotencyKey = nativeFromJson<String>(json['idempotencyKey']),
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

    final CreateBillingCustomerCreationVariables otherTyped =
        other as CreateBillingCustomerCreationVariables;
    return teamId == otherTyped.teamId &&
        userId == otherTyped.userId &&
        idempotencyKey == otherTyped.idempotencyKey &&
        livemode == otherTyped.livemode &&
        createdAt == otherTyped.createdAt;
  }

  @override
  int get hashCode => Object.hashAll([
    teamId.hashCode,
    userId.hashCode,
    idempotencyKey.hashCode,
    livemode.hashCode,
    createdAt.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['userId'] = nativeToJson<String>(userId);
    json['idempotencyKey'] = nativeToJson<String>(idempotencyKey);
    json['livemode'] = nativeToJson<bool>(livemode);
    json['createdAt'] = bigIntToJson(createdAt);
    return json;
  }

  CreateBillingCustomerCreationVariables({
    required this.teamId,
    required this.userId,
    required this.idempotencyKey,
    required this.livemode,
    required this.createdAt,
  });
}
