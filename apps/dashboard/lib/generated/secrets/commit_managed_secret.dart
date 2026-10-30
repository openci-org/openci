part of 'secrets.dart';

class CommitManagedSecretVariablesBuilder {
  String teamId;
  String actorUid;
  String name;
  Optional<String> _expectedPath = Optional.optional(
    nativeFromJson,
    nativeToJson,
  );
  String path;

  final FirebaseDataConnect _dataConnect;
  CommitManagedSecretVariablesBuilder expectedPath(String? t) {
    _expectedPath.value = t;
    return this;
  }

  CommitManagedSecretVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.actorUid,
    required this.name,
    required this.path,
  });
  Deserializer<CommitManagedSecretData> dataDeserializer = (dynamic json) =>
      CommitManagedSecretData.fromJson(jsonDecode(json));
  Serializer<CommitManagedSecretVariables> varsSerializer =
      (CommitManagedSecretVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CommitManagedSecretData, CommitManagedSecretVariables>>
  execute() {
    return ref().execute();
  }

  MutationRef<CommitManagedSecretData, CommitManagedSecretVariables> ref() {
    CommitManagedSecretVariables vars = CommitManagedSecretVariables(
      teamId: teamId,
      actorUid: actorUid,
      name: name,
      expectedPath: _expectedPath,
      path: path,
    );
    return _dataConnect.mutation(
      "CommitManagedSecret",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class CommitManagedSecretTeamUpdate {
  final String id;
  CommitManagedSecretTeamUpdate.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CommitManagedSecretTeamUpdate otherTyped =
        other as CommitManagedSecretTeamUpdate;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CommitManagedSecretTeamUpdate({
    required this.id,
  });
}

@immutable
class CommitManagedSecretSecretReferenceUpsert {
  final String teamId;
  final String name;
  CommitManagedSecretSecretReferenceUpsert.fromJson(dynamic json)
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

    final CommitManagedSecretSecretReferenceUpsert otherTyped =
        other as CommitManagedSecretSecretReferenceUpsert;
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

  CommitManagedSecretSecretReferenceUpsert({
    required this.teamId,
    required this.name,
  });
}

@immutable
class CommitManagedSecretData {
  final CommitManagedSecretTeamUpdate? team_update;
  final CommitManagedSecretSecretReferenceUpsert secretReference_upsert;
  CommitManagedSecretData.fromJson(dynamic json)
    : team_update = json['team_update'] == null
          ? null
          : CommitManagedSecretTeamUpdate.fromJson(json['team_update']),
      secretReference_upsert =
          CommitManagedSecretSecretReferenceUpsert.fromJson(
            json['secretReference_upsert'],
          );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CommitManagedSecretData otherTyped = other as CommitManagedSecretData;
    return team_update == otherTyped.team_update &&
        secretReference_upsert == otherTyped.secretReference_upsert;
  }

  @override
  int get hashCode =>
      Object.hashAll([team_update.hashCode, secretReference_upsert.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (team_update != null) {
      json['team_update'] = team_update!.toJson();
    }
    json['secretReference_upsert'] = secretReference_upsert.toJson();
    return json;
  }

  CommitManagedSecretData({
    this.team_update,
    required this.secretReference_upsert,
  });
}

@immutable
class CommitManagedSecretVariables {
  final String teamId;
  final String actorUid;
  final String name;
  late final Optional<String> expectedPath;
  final String path;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  CommitManagedSecretVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']),
      actorUid = nativeFromJson<String>(json['actorUid']),
      name = nativeFromJson<String>(json['name']),
      path = nativeFromJson<String>(json['path']) {
    expectedPath = Optional.optional(nativeFromJson, nativeToJson);
    expectedPath.value = json['expectedPath'] == null
        ? null
        : nativeFromJson<String>(json['expectedPath']);
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CommitManagedSecretVariables otherTyped =
        other as CommitManagedSecretVariables;
    return teamId == otherTyped.teamId &&
        actorUid == otherTyped.actorUid &&
        name == otherTyped.name &&
        expectedPath == otherTyped.expectedPath &&
        path == otherTyped.path;
  }

  @override
  int get hashCode => Object.hashAll([
    teamId.hashCode,
    actorUid.hashCode,
    name.hashCode,
    expectedPath.hashCode,
    path.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['actorUid'] = nativeToJson<String>(actorUid);
    json['name'] = nativeToJson<String>(name);
    if (expectedPath.state == OptionalState.set) {
      json['expectedPath'] = expectedPath.toJson();
    }
    json['path'] = nativeToJson<String>(path);
    return json;
  }

  CommitManagedSecretVariables({
    required this.teamId,
    required this.actorUid,
    required this.name,
    required this.expectedPath,
    required this.path,
  });
}
