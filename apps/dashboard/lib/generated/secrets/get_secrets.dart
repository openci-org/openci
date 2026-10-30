part of 'secrets.dart';

class GetSecretsVariablesBuilder {
  String teamId;

  final FirebaseDataConnect _dataConnect;
  GetSecretsVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
  });
  Deserializer<GetSecretsData> dataDeserializer = (dynamic json) =>
      GetSecretsData.fromJson(jsonDecode(json));
  Serializer<GetSecretsVariables> varsSerializer = (GetSecretsVariables vars) =>
      jsonEncode(vars.toJson());
  Future<QueryResult<GetSecretsData, GetSecretsVariables>> execute({
    QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache,
  }) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetSecretsData, GetSecretsVariables> ref() {
    GetSecretsVariables vars = GetSecretsVariables(
      teamId: teamId,
    );
    return _dataConnect.query(
      "GetSecrets",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetSecretsSecrets {
  final String teamId;
  final String name;
  final BigInt createdAt;
  final BigInt updatedAt;
  GetSecretsSecrets.fromJson(dynamic json)
    : teamId = nativeFromJson<String>(json['teamId']),
      name = nativeFromJson<String>(json['name']),
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

    final GetSecretsSecrets otherTyped = other as GetSecretsSecrets;
    return teamId == otherTyped.teamId &&
        name == otherTyped.name &&
        createdAt == otherTyped.createdAt &&
        updatedAt == otherTyped.updatedAt;
  }

  @override
  int get hashCode => Object.hashAll([
    teamId.hashCode,
    name.hashCode,
    createdAt.hashCode,
    updatedAt.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['name'] = nativeToJson<String>(name);
    json['createdAt'] = bigIntToJson(createdAt);
    json['updatedAt'] = bigIntToJson(updatedAt);
    return json;
  }

  GetSecretsSecrets({
    required this.teamId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });
}

@immutable
class GetSecretsData {
  final List<GetSecretsSecrets> secrets;
  GetSecretsData.fromJson(dynamic json)
    : secrets = (json['secrets'] as List<dynamic>)
          .map((e) => GetSecretsSecrets.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetSecretsData otherTyped = other as GetSecretsData;
    return secrets == otherTyped.secrets;
  }

  @override
  int get hashCode => secrets.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['secrets'] = secrets.map((e) => e.toJson()).toList();
    return json;
  }

  GetSecretsData({
    required this.secrets,
  });
}

@immutable
class GetSecretsVariables {
  final String teamId;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetSecretsVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetSecretsVariables otherTyped = other as GetSecretsVariables;
    return teamId == otherTyped.teamId;
  }

  @override
  int get hashCode => teamId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  GetSecretsVariables({
    required this.teamId,
  });
}
