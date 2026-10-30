part of 'billing.dart';

class DeferBillingTeamCleanupVariablesBuilder {
  String teamId;

  final FirebaseDataConnect _dataConnect;
  DeferBillingTeamCleanupVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
  });
  Deserializer<DeferBillingTeamCleanupData> dataDeserializer = (dynamic json) =>
      DeferBillingTeamCleanupData.fromJson(jsonDecode(json));
  Serializer<DeferBillingTeamCleanupVariables> varsSerializer =
      (DeferBillingTeamCleanupVariables vars) => jsonEncode(vars.toJson());
  Future<
    OperationResult<
      DeferBillingTeamCleanupData,
      DeferBillingTeamCleanupVariables
    >
  >
  execute() {
    return ref().execute();
  }

  MutationRef<DeferBillingTeamCleanupData, DeferBillingTeamCleanupVariables>
  ref() {
    DeferBillingTeamCleanupVariables vars = DeferBillingTeamCleanupVariables(
      teamId: teamId,
    );
    return _dataConnect.mutation(
      "DeferBillingTeamCleanup",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class DeferBillingTeamCleanupBillingTeamDeletionUpdate {
  final String teamId;
  DeferBillingTeamCleanupBillingTeamDeletionUpdate.fromJson(dynamic json)
    : teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final DeferBillingTeamCleanupBillingTeamDeletionUpdate otherTyped =
        other as DeferBillingTeamCleanupBillingTeamDeletionUpdate;
    return teamId == otherTyped.teamId;
  }

  @override
  int get hashCode => teamId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  DeferBillingTeamCleanupBillingTeamDeletionUpdate({
    required this.teamId,
  });
}

@immutable
class DeferBillingTeamCleanupData {
  final DeferBillingTeamCleanupBillingTeamDeletionUpdate?
  billingTeamDeletion_update;
  DeferBillingTeamCleanupData.fromJson(dynamic json)
    : billingTeamDeletion_update = json['billingTeamDeletion_update'] == null
          ? null
          : DeferBillingTeamCleanupBillingTeamDeletionUpdate.fromJson(
              json['billingTeamDeletion_update'],
            );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final DeferBillingTeamCleanupData otherTyped =
        other as DeferBillingTeamCleanupData;
    return billingTeamDeletion_update == otherTyped.billingTeamDeletion_update;
  }

  @override
  int get hashCode => billingTeamDeletion_update.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (billingTeamDeletion_update != null) {
      json['billingTeamDeletion_update'] = billingTeamDeletion_update!.toJson();
    }
    return json;
  }

  DeferBillingTeamCleanupData({
    this.billingTeamDeletion_update,
  });
}

@immutable
class DeferBillingTeamCleanupVariables {
  final String teamId;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  DeferBillingTeamCleanupVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final DeferBillingTeamCleanupVariables otherTyped =
        other as DeferBillingTeamCleanupVariables;
    return teamId == otherTyped.teamId;
  }

  @override
  int get hashCode => teamId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  DeferBillingTeamCleanupVariables({
    required this.teamId,
  });
}
