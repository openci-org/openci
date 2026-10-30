part of 'secrets.dart';

class DeleteManagedSecretVariablesBuilder {
  String teamId;
  String actorUid;
  String name;
  String expectedPath;

  final FirebaseDataConnect _dataConnect;
  DeleteManagedSecretVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.actorUid,
    required this.name,
    required this.expectedPath,
  });
  Deserializer<DeleteManagedSecretData> dataDeserializer = (dynamic json) =>
      DeleteManagedSecretData.fromJson(jsonDecode(json));
  Serializer<DeleteManagedSecretVariables> varsSerializer =
      (DeleteManagedSecretVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeleteManagedSecretData, DeleteManagedSecretVariables>>
  execute() {
    return ref().execute();
  }

  MutationRef<DeleteManagedSecretData, DeleteManagedSecretVariables> ref() {
    DeleteManagedSecretVariables vars = DeleteManagedSecretVariables(
      teamId: teamId,
      actorUid: actorUid,
      name: name,
      expectedPath: expectedPath,
    );
    return _dataConnect.mutation(
      "DeleteManagedSecret",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class DeleteManagedSecretTeamUpdate {
  final String id;
  DeleteManagedSecretTeamUpdate.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteManagedSecretTeamUpdate otherTyped =
        other as DeleteManagedSecretTeamUpdate;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteManagedSecretTeamUpdate({
    required this.id,
  });
}

@immutable
class DeleteManagedSecretData {
  final DeleteManagedSecretTeamUpdate? team_update;
  final int secretReference_deleteMany;
  DeleteManagedSecretData.fromJson(dynamic json)
    : team_update = json['team_update'] == null
          ? null
          : DeleteManagedSecretTeamUpdate.fromJson(json['team_update']),
      secretReference_deleteMany = nativeFromJson<int>(
        json['secretReference_deleteMany'],
      );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteManagedSecretData otherTyped = other as DeleteManagedSecretData;
    return team_update == otherTyped.team_update &&
        secretReference_deleteMany == otherTyped.secretReference_deleteMany;
  }

  @override
  int get hashCode => Object.hashAll([
    team_update.hashCode,
    secretReference_deleteMany.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (team_update != null) {
      json['team_update'] = team_update!.toJson();
    }
    json['secretReference_deleteMany'] = nativeToJson<int>(
      secretReference_deleteMany,
    );
    return json;
  }

  DeleteManagedSecretData({
    this.team_update,
    required this.secretReference_deleteMany,
  });
}

@immutable
class DeleteManagedSecretVariables {
  final String teamId;
  final String actorUid;
  final String name;
  final String expectedPath;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  DeleteManagedSecretVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']),
      actorUid = nativeFromJson<String>(json['actorUid']),
      name = nativeFromJson<String>(json['name']),
      expectedPath = nativeFromJson<String>(json['expectedPath']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteManagedSecretVariables otherTyped =
        other as DeleteManagedSecretVariables;
    return teamId == otherTyped.teamId &&
        actorUid == otherTyped.actorUid &&
        name == otherTyped.name &&
        expectedPath == otherTyped.expectedPath;
  }

  @override
  int get hashCode => Object.hashAll([
    teamId.hashCode,
    actorUid.hashCode,
    name.hashCode,
    expectedPath.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['actorUid'] = nativeToJson<String>(actorUid);
    json['name'] = nativeToJson<String>(name);
    json['expectedPath'] = nativeToJson<String>(expectedPath);
    return json;
  }

  DeleteManagedSecretVariables({
    required this.teamId,
    required this.actorUid,
    required this.name,
    required this.expectedPath,
  });
}
