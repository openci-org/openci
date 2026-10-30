part of 'billing.dart';

class CompleteBillingTeamCleanupVariablesBuilder {
  String teamId;

  final FirebaseDataConnect _dataConnect;
  CompleteBillingTeamCleanupVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
  });
  Deserializer<CompleteBillingTeamCleanupData> dataDeserializer =
      (dynamic json) =>
          CompleteBillingTeamCleanupData.fromJson(jsonDecode(json));
  Serializer<CompleteBillingTeamCleanupVariables> varsSerializer =
      (CompleteBillingTeamCleanupVariables vars) => jsonEncode(vars.toJson());
  Future<
    OperationResult<
      CompleteBillingTeamCleanupData,
      CompleteBillingTeamCleanupVariables
    >
  >
  execute() {
    return ref().execute();
  }

  MutationRef<
    CompleteBillingTeamCleanupData,
    CompleteBillingTeamCleanupVariables
  >
  ref() {
    CompleteBillingTeamCleanupVariables vars =
        CompleteBillingTeamCleanupVariables(
          teamId: teamId,
        );
    return _dataConnect.mutation(
      "CompleteBillingTeamCleanup",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class CompleteBillingTeamCleanupBillingTeamDeletionUpdate {
  final String teamId;
  CompleteBillingTeamCleanupBillingTeamDeletionUpdate.fromJson(dynamic json)
    : teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CompleteBillingTeamCleanupBillingTeamDeletionUpdate otherTyped =
        other as CompleteBillingTeamCleanupBillingTeamDeletionUpdate;
    return teamId == otherTyped.teamId;
  }

  @override
  int get hashCode => teamId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  CompleteBillingTeamCleanupBillingTeamDeletionUpdate({
    required this.teamId,
  });
}

@immutable
class CompleteBillingTeamCleanupData {
  final CompleteBillingTeamCleanupBillingTeamDeletionUpdate?
  billingTeamDeletion_update;
  CompleteBillingTeamCleanupData.fromJson(dynamic json)
    : billingTeamDeletion_update = json['billingTeamDeletion_update'] == null
          ? null
          : CompleteBillingTeamCleanupBillingTeamDeletionUpdate.fromJson(
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

    final CompleteBillingTeamCleanupData otherTyped =
        other as CompleteBillingTeamCleanupData;
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

  CompleteBillingTeamCleanupData({
    this.billingTeamDeletion_update,
  });
}

@immutable
class CompleteBillingTeamCleanupVariables {
  final String teamId;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  CompleteBillingTeamCleanupVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CompleteBillingTeamCleanupVariables otherTyped =
        other as CompleteBillingTeamCleanupVariables;
    return teamId == otherTyped.teamId;
  }

  @override
  int get hashCode => teamId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  CompleteBillingTeamCleanupVariables({
    required this.teamId,
  });
}
