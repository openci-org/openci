part of 'secrets.dart';

class GetSecretReferenceVariablesBuilder {
  String teamId;
  String name;

  final FirebaseDataConnect _dataConnect;
  GetSecretReferenceVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.name,
  });
  Deserializer<GetSecretReferenceData> dataDeserializer = (dynamic json) =>
      GetSecretReferenceData.fromJson(jsonDecode(json));
  Serializer<GetSecretReferenceVariables> varsSerializer =
      (GetSecretReferenceVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetSecretReferenceData, GetSecretReferenceVariables>>
  execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetSecretReferenceData, GetSecretReferenceVariables> ref() {
    GetSecretReferenceVariables vars = GetSecretReferenceVariables(
      teamId: teamId,
      name: name,
    );
    return _dataConnect.query(
      "GetSecretReference",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetSecretReferenceSecretReference {
  final String teamId;
  final String name;
  final String secretVersionPath;
  final BigInt createdAt;
  final BigInt updatedAt;
  GetSecretReferenceSecretReference.fromJson(dynamic json)
    : teamId = nativeFromJson<String>(json['teamId']),
      name = nativeFromJson<String>(json['name']),
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

    final GetSecretReferenceSecretReference otherTyped =
        other as GetSecretReferenceSecretReference;
    return teamId == otherTyped.teamId &&
        name == otherTyped.name &&
        secretVersionPath == otherTyped.secretVersionPath &&
        createdAt == otherTyped.createdAt &&
        updatedAt == otherTyped.updatedAt;
  }

  @override
  int get hashCode => Object.hashAll([
    teamId.hashCode,
    name.hashCode,
    secretVersionPath.hashCode,
    createdAt.hashCode,
    updatedAt.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['name'] = nativeToJson<String>(name);
    json['secretVersionPath'] = nativeToJson<String>(secretVersionPath);
    json['createdAt'] = bigIntToJson(createdAt);
    json['updatedAt'] = bigIntToJson(updatedAt);
    return json;
  }

  GetSecretReferenceSecretReference({
    required this.teamId,
    required this.name,
    required this.secretVersionPath,
    required this.createdAt,
    required this.updatedAt,
  });
}

@immutable
class GetSecretReferenceData {
  final GetSecretReferenceSecretReference? secretReference;
  GetSecretReferenceData.fromJson(dynamic json)
    : secretReference = json['secretReference'] == null
          ? null
          : GetSecretReferenceSecretReference.fromJson(json['secretReference']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetSecretReferenceData otherTyped = other as GetSecretReferenceData;
    return secretReference == otherTyped.secretReference;
  }

  @override
  int get hashCode => secretReference.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (secretReference != null) {
      json['secretReference'] = secretReference!.toJson();
    }
    return json;
  }

  GetSecretReferenceData({
    this.secretReference,
  });
}

@immutable
class GetSecretReferenceVariables {
  final String teamId;
  final String name;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetSecretReferenceVariables.fromJson(Map<String, dynamic> json)
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

    final GetSecretReferenceVariables otherTyped =
        other as GetSecretReferenceVariables;
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

  GetSecretReferenceVariables({
    required this.teamId,
    required this.name,
  });
}
