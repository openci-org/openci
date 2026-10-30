part of 'billing.dart';

class AcknowledgeBillingCredentialCleanupVariablesBuilder {
  String teamId;
  String path;
  String kind;

  final FirebaseDataConnect _dataConnect;
  AcknowledgeBillingCredentialCleanupVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.path,
    required this.kind,
  });
  Deserializer<AcknowledgeBillingCredentialCleanupData> dataDeserializer =
      (dynamic json) =>
          AcknowledgeBillingCredentialCleanupData.fromJson(jsonDecode(json));
  Serializer<AcknowledgeBillingCredentialCleanupVariables> varsSerializer =
      (AcknowledgeBillingCredentialCleanupVariables vars) =>
          jsonEncode(vars.toJson());
  Future<
    OperationResult<
      AcknowledgeBillingCredentialCleanupData,
      AcknowledgeBillingCredentialCleanupVariables
    >
  >
  execute() {
    return ref().execute();
  }

  MutationRef<
    AcknowledgeBillingCredentialCleanupData,
    AcknowledgeBillingCredentialCleanupVariables
  >
  ref() {
    AcknowledgeBillingCredentialCleanupVariables vars =
        AcknowledgeBillingCredentialCleanupVariables(
          teamId: teamId,
          path: path,
          kind: kind,
        );
    return _dataConnect.mutation(
      "AcknowledgeBillingCredentialCleanup",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class AcknowledgeBillingCredentialCleanupLocked {
  final String teamId;
  AcknowledgeBillingCredentialCleanupLocked.fromJson(dynamic json)
    : teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final AcknowledgeBillingCredentialCleanupLocked otherTyped =
        other as AcknowledgeBillingCredentialCleanupLocked;
    return teamId == otherTyped.teamId;
  }

  @override
  int get hashCode => teamId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  AcknowledgeBillingCredentialCleanupLocked({
    required this.teamId,
  });
}

@immutable
class AcknowledgeBillingCredentialCleanupBillingTeamDeletionUpdate {
  final String teamId;
  AcknowledgeBillingCredentialCleanupBillingTeamDeletionUpdate.fromJson(
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

    final AcknowledgeBillingCredentialCleanupBillingTeamDeletionUpdate
    otherTyped =
        other as AcknowledgeBillingCredentialCleanupBillingTeamDeletionUpdate;
    return teamId == otherTyped.teamId;
  }

  @override
  int get hashCode => teamId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  AcknowledgeBillingCredentialCleanupBillingTeamDeletionUpdate({
    required this.teamId,
  });
}

@immutable
class AcknowledgeBillingCredentialCleanupData {
  final AcknowledgeBillingCredentialCleanupLocked? locked;
  final AcknowledgeBillingCredentialCleanupBillingTeamDeletionUpdate?
  billingTeamDeletion_update;
  AcknowledgeBillingCredentialCleanupData.fromJson(dynamic json)
    : locked = json['locked'] == null
          ? null
          : AcknowledgeBillingCredentialCleanupLocked.fromJson(json['locked']),
      billingTeamDeletion_update = json['billingTeamDeletion_update'] == null
          ? null
          : AcknowledgeBillingCredentialCleanupBillingTeamDeletionUpdate.fromJson(
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

    final AcknowledgeBillingCredentialCleanupData otherTyped =
        other as AcknowledgeBillingCredentialCleanupData;
    return locked == otherTyped.locked &&
        billingTeamDeletion_update == otherTyped.billingTeamDeletion_update;
  }

  @override
  int get hashCode =>
      Object.hashAll([locked.hashCode, billingTeamDeletion_update.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (locked != null) {
      json['locked'] = locked!.toJson();
    }
    if (billingTeamDeletion_update != null) {
      json['billingTeamDeletion_update'] = billingTeamDeletion_update!.toJson();
    }
    return json;
  }

  AcknowledgeBillingCredentialCleanupData({
    this.locked,
    this.billingTeamDeletion_update,
  });
}

@immutable
class AcknowledgeBillingCredentialCleanupVariables {
  final String teamId;
  final String path;
  final String kind;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  AcknowledgeBillingCredentialCleanupVariables.fromJson(
    Map<String, dynamic> json,
  ) : teamId = nativeFromJson<String>(json['teamId']),
      path = nativeFromJson<String>(json['path']),
      kind = nativeFromJson<String>(json['kind']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final AcknowledgeBillingCredentialCleanupVariables otherTyped =
        other as AcknowledgeBillingCredentialCleanupVariables;
    return teamId == otherTyped.teamId &&
        path == otherTyped.path &&
        kind == otherTyped.kind;
  }

  @override
  int get hashCode =>
      Object.hashAll([teamId.hashCode, path.hashCode, kind.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['path'] = nativeToJson<String>(path);
    json['kind'] = nativeToJson<String>(kind);
    return json;
  }

  AcknowledgeBillingCredentialCleanupVariables({
    required this.teamId,
    required this.path,
    required this.kind,
  });
}
