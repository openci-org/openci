part of 'secrets.dart';

class GetManagedSecretContextVariablesBuilder {
  String teamId;
  String actorUid;

  final FirebaseDataConnect _dataConnect;
  GetManagedSecretContextVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.actorUid,
  });
  Deserializer<GetManagedSecretContextData> dataDeserializer = (dynamic json) =>
      GetManagedSecretContextData.fromJson(jsonDecode(json));
  Serializer<GetManagedSecretContextVariables> varsSerializer =
      (GetManagedSecretContextVariables vars) => jsonEncode(vars.toJson());
  Future<
    QueryResult<GetManagedSecretContextData, GetManagedSecretContextVariables>
  >
  execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetManagedSecretContextData, GetManagedSecretContextVariables>
  ref() {
    GetManagedSecretContextVariables vars = GetManagedSecretContextVariables(
      teamId: teamId,
      actorUid: actorUid,
    );
    return _dataConnect.query(
      "GetManagedSecretContext",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetManagedSecretContextTeamMember {
  final BigInt id;
  GetManagedSecretContextTeamMember.fromJson(dynamic json)
    : id = bigIntFromJson(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetManagedSecretContextTeamMember otherTyped =
        other as GetManagedSecretContextTeamMember;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = bigIntToJson(id);
    return json;
  }

  GetManagedSecretContextTeamMember({
    required this.id,
  });
}

@immutable
class GetManagedSecretContextSecrets {
  final String name;
  final String secretVersionPath;
  final BigInt createdAt;
  final BigInt updatedAt;
  GetManagedSecretContextSecrets.fromJson(dynamic json)
    : name = nativeFromJson<String>(json['name']),
      secretVersionPath = nativeFromJson<String>(json['secretVersionPath']),
      createdAt = bigIntFromJson(json['createdAt']),
      updatedAt = bigIntFromJson(json['updatedAt']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetManagedSecretContextSecrets otherTyped =
        other as GetManagedSecretContextSecrets;
    return name == otherTyped.name &&
        secretVersionPath == otherTyped.secretVersionPath &&
        createdAt == otherTyped.createdAt &&
        updatedAt == otherTyped.updatedAt;
  }

  @override
  int get hashCode => Object.hashAll([
    name.hashCode,
    secretVersionPath.hashCode,
    createdAt.hashCode,
    updatedAt.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['name'] = nativeToJson<String>(name);
    json['secretVersionPath'] = nativeToJson<String>(secretVersionPath);
    json['createdAt'] = bigIntToJson(createdAt);
    json['updatedAt'] = bigIntToJson(updatedAt);
    return json;
  }

  GetManagedSecretContextSecrets({
    required this.name,
    required this.secretVersionPath,
    required this.createdAt,
    required this.updatedAt,
  });
}

@immutable
class GetManagedSecretContextData {
  final GetManagedSecretContextTeamMember? teamMember;
  final List<GetManagedSecretContextSecrets> secrets;
  GetManagedSecretContextData.fromJson(dynamic json)
    : teamMember = json['teamMember'] == null
          ? null
          : GetManagedSecretContextTeamMember.fromJson(json['teamMember']),
      secrets = (json['secrets'] as List<dynamic>)
          .map((e) => GetManagedSecretContextSecrets.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetManagedSecretContextData otherTyped =
        other as GetManagedSecretContextData;
    return teamMember == otherTyped.teamMember && secrets == otherTyped.secrets;
  }

  @override
  int get hashCode => Object.hashAll([teamMember.hashCode, secrets.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (teamMember != null) {
      json['teamMember'] = teamMember!.toJson();
    }
    json['secrets'] = secrets.map((e) => e.toJson()).toList();
    return json;
  }

  GetManagedSecretContextData({
    this.teamMember,
    required this.secrets,
  });
}

@immutable
class GetManagedSecretContextVariables {
  final String teamId;
  final String actorUid;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetManagedSecretContextVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']),
      actorUid = nativeFromJson<String>(json['actorUid']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetManagedSecretContextVariables otherTyped =
        other as GetManagedSecretContextVariables;
    return teamId == otherTyped.teamId && actorUid == otherTyped.actorUid;
  }

  @override
  int get hashCode => Object.hashAll([teamId.hashCode, actorUid.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['actorUid'] = nativeToJson<String>(actorUid);
    return json;
  }

  GetManagedSecretContextVariables({
    required this.teamId,
    required this.actorUid,
  });
}
