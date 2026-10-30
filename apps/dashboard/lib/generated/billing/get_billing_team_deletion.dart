part of 'billing.dart';

class GetBillingTeamDeletionVariablesBuilder {
  String teamId;
  String userId;

  final FirebaseDataConnect _dataConnect;
  GetBillingTeamDeletionVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.userId,
  });
  Deserializer<GetBillingTeamDeletionData> dataDeserializer = (dynamic json) =>
      GetBillingTeamDeletionData.fromJson(jsonDecode(json));
  Serializer<GetBillingTeamDeletionVariables> varsSerializer =
      (GetBillingTeamDeletionVariables vars) => jsonEncode(vars.toJson());
  Future<
    QueryResult<GetBillingTeamDeletionData, GetBillingTeamDeletionVariables>
  >
  execute() {
    return ref().execute();
  }

  QueryRef<GetBillingTeamDeletionData, GetBillingTeamDeletionVariables> ref() {
    GetBillingTeamDeletionVariables vars = GetBillingTeamDeletionVariables(
      teamId: teamId,
      userId: userId,
    );
    return _dataConnect.query(
      "GetBillingTeamDeletion",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetBillingTeamDeletionReceipt {
  final String teamId;
  GetBillingTeamDeletionReceipt.fromJson(dynamic json)
    : teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingTeamDeletionReceipt otherTyped =
        other as GetBillingTeamDeletionReceipt;
    return teamId == otherTyped.teamId;
  }

  @override
  int get hashCode => teamId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  GetBillingTeamDeletionReceipt({
    required this.teamId,
  });
}

@immutable
class GetBillingTeamDeletionData {
  final GetBillingTeamDeletionReceipt? receipt;
  GetBillingTeamDeletionData.fromJson(dynamic json)
    : receipt = json['receipt'] == null
          ? null
          : GetBillingTeamDeletionReceipt.fromJson(json['receipt']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingTeamDeletionData otherTyped =
        other as GetBillingTeamDeletionData;
    return receipt == otherTyped.receipt;
  }

  @override
  int get hashCode => receipt.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (receipt != null) {
      json['receipt'] = receipt!.toJson();
    }
    return json;
  }

  GetBillingTeamDeletionData({
    this.receipt,
  });
}

@immutable
class GetBillingTeamDeletionVariables {
  final String teamId;
  final String userId;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetBillingTeamDeletionVariables.fromJson(Map<String, dynamic> json)
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

    final GetBillingTeamDeletionVariables otherTyped =
        other as GetBillingTeamDeletionVariables;
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

  GetBillingTeamDeletionVariables({
    required this.teamId,
    required this.userId,
  });
}
