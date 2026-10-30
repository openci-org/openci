part of 'secrets.dart';

class RenameManagedSecretVariablesBuilder {
  String teamId;
  String actorUid;
  String name;
  String newName;
  String expectedPath;
  Optional<String> _path = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;
  RenameManagedSecretVariablesBuilder path(String? t) {
    _path.value = t;
    return this;
  }

  RenameManagedSecretVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.actorUid,
    required this.name,
    required this.newName,
    required this.expectedPath,
  });
  Deserializer<RenameManagedSecretData> dataDeserializer = (dynamic json) =>
      RenameManagedSecretData.fromJson(jsonDecode(json));
  Serializer<RenameManagedSecretVariables> varsSerializer =
      (RenameManagedSecretVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<RenameManagedSecretData, RenameManagedSecretVariables>>
  execute() {
    return ref().execute();
  }

  MutationRef<RenameManagedSecretData, RenameManagedSecretVariables> ref() {
    RenameManagedSecretVariables vars = RenameManagedSecretVariables(
      teamId: teamId,
      actorUid: actorUid,
      name: name,
      newName: newName,
      expectedPath: expectedPath,
      path: _path,
    );
    return _dataConnect.mutation(
      "RenameManagedSecret",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class RenameManagedSecretTeamUpdate {
  final String id;
  RenameManagedSecretTeamUpdate.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final RenameManagedSecretTeamUpdate otherTyped =
        other as RenameManagedSecretTeamUpdate;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  RenameManagedSecretTeamUpdate({
    required this.id,
  });
}

@immutable
class RenameManagedSecretSecretReferenceDelete {
  final String teamId;
  final String name;
  RenameManagedSecretSecretReferenceDelete.fromJson(dynamic json)
    : teamId = nativeFromJson<String>(json['teamId']),
      name = nativeFromJson<String>(json['name']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final RenameManagedSecretSecretReferenceDelete otherTyped =
        other as RenameManagedSecretSecretReferenceDelete;
    return teamId == otherTyped.teamId && name == otherTyped.name;
  }

  @override
  int get hashCode => Object.hashAll([teamId.hashCode, name.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['name'] = nativeToJson<String>(name);
    return json;
  }

  RenameManagedSecretSecretReferenceDelete({
    required this.teamId,
    required this.name,
  });
}

@immutable
class RenameManagedSecretSecretReferenceInsert {
  final String teamId;
  final String name;
  RenameManagedSecretSecretReferenceInsert.fromJson(dynamic json)
    : teamId = nativeFromJson<String>(json['teamId']),
      name = nativeFromJson<String>(json['name']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final RenameManagedSecretSecretReferenceInsert otherTyped =
        other as RenameManagedSecretSecretReferenceInsert;
    return teamId == otherTyped.teamId && name == otherTyped.name;
  }

  @override
  int get hashCode => Object.hashAll([teamId.hashCode, name.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['name'] = nativeToJson<String>(name);
    return json;
  }

  RenameManagedSecretSecretReferenceInsert({
    required this.teamId,
    required this.name,
  });
}

@immutable
class RenameManagedSecretData {
  final RenameManagedSecretTeamUpdate? team_update;
  final RenameManagedSecretSecretReferenceDelete? secretReference_delete;
  final RenameManagedSecretSecretReferenceInsert secretReference_insert;
  RenameManagedSecretData.fromJson(dynamic json)
    : team_update = json['team_update'] == null
          ? null
          : RenameManagedSecretTeamUpdate.fromJson(json['team_update']),
      secretReference_delete = json['secretReference_delete'] == null
          ? null
          : RenameManagedSecretSecretReferenceDelete.fromJson(
              json['secretReference_delete'],
            ),
      secretReference_insert =
          RenameManagedSecretSecretReferenceInsert.fromJson(
            json['secretReference_insert'],
          );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final RenameManagedSecretData otherTyped = other as RenameManagedSecretData;
    return team_update == otherTyped.team_update &&
        secretReference_delete == otherTyped.secretReference_delete &&
        secretReference_insert == otherTyped.secretReference_insert;
  }

  @override
  int get hashCode => Object.hashAll([
    team_update.hashCode,
    secretReference_delete.hashCode,
    secretReference_insert.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (team_update != null) {
      json['team_update'] = team_update!.toJson();
    }
    if (secretReference_delete != null) {
      json['secretReference_delete'] = secretReference_delete!.toJson();
    }
    json['secretReference_insert'] = secretReference_insert.toJson();
    return json;
  }

  RenameManagedSecretData({
    this.team_update,
    this.secretReference_delete,
    required this.secretReference_insert,
  });
}

@immutable
class RenameManagedSecretVariables {
  final String teamId;
  final String actorUid;
  final String name;
  final String newName;
  final String expectedPath;
  late final Optional<String> path;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  RenameManagedSecretVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']),
      actorUid = nativeFromJson<String>(json['actorUid']),
      name = nativeFromJson<String>(json['name']),
      newName = nativeFromJson<String>(json['newName']),
      expectedPath = nativeFromJson<String>(json['expectedPath']) {
    path = Optional.optional(nativeFromJson, nativeToJson);
    path.value = json['path'] == null
        ? null
        : nativeFromJson<String>(json['path']);
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final RenameManagedSecretVariables otherTyped =
        other as RenameManagedSecretVariables;
    return teamId == otherTyped.teamId &&
        actorUid == otherTyped.actorUid &&
        name == otherTyped.name &&
        newName == otherTyped.newName &&
        expectedPath == otherTyped.expectedPath &&
        path == otherTyped.path;
  }

  @override
  int get hashCode => Object.hashAll([
    teamId.hashCode,
    actorUid.hashCode,
    name.hashCode,
    newName.hashCode,
    expectedPath.hashCode,
    path.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['actorUid'] = nativeToJson<String>(actorUid);
    json['name'] = nativeToJson<String>(name);
    json['newName'] = nativeToJson<String>(newName);
    json['expectedPath'] = nativeToJson<String>(expectedPath);
    if (path.state == OptionalState.set) {
      json['path'] = path.toJson();
    }
    return json;
  }

  RenameManagedSecretVariables({
    required this.teamId,
    required this.actorUid,
    required this.name,
    required this.newName,
    required this.expectedPath,
    required this.path,
  });
}
