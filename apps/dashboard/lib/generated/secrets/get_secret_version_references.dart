part of 'secrets.dart';

class GetSecretVersionReferencesVariablesBuilder {
  String path;

  final FirebaseDataConnect _dataConnect;
  GetSecretVersionReferencesVariablesBuilder(
    this._dataConnect, {
    required this.path,
  });
  Deserializer<GetSecretVersionReferencesData> dataDeserializer =
      (dynamic json) =>
          GetSecretVersionReferencesData.fromJson(jsonDecode(json));
  Serializer<GetSecretVersionReferencesVariables> varsSerializer =
      (GetSecretVersionReferencesVariables vars) => jsonEncode(vars.toJson());
  Future<
    QueryResult<
      GetSecretVersionReferencesData,
      GetSecretVersionReferencesVariables
    >
  >
  execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetSecretVersionReferencesData, GetSecretVersionReferencesVariables>
  ref() {
    GetSecretVersionReferencesVariables vars =
        GetSecretVersionReferencesVariables(
          path: path,
        );
    return _dataConnect.query(
      "GetSecretVersionReferences",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetSecretVersionReferencesReferences {
  final String name;
  GetSecretVersionReferencesReferences.fromJson(dynamic json)
    : name = nativeFromJson<String>(json['name']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetSecretVersionReferencesReferences otherTyped =
        other as GetSecretVersionReferencesReferences;
    return name == otherTyped.name;
  }

  @override
  int get hashCode => name.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['name'] = nativeToJson<String>(name);
    return json;
  }

  GetSecretVersionReferencesReferences({
    required this.name,
  });
}

@immutable
class GetSecretVersionReferencesData {
  final List<GetSecretVersionReferencesReferences> references;
  GetSecretVersionReferencesData.fromJson(dynamic json)
    : references = (json['references'] as List<dynamic>)
          .map((e) => GetSecretVersionReferencesReferences.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetSecretVersionReferencesData otherTyped =
        other as GetSecretVersionReferencesData;
    return references == otherTyped.references;
  }

  @override
  int get hashCode => references.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['references'] = references.map((e) => e.toJson()).toList();
    return json;
  }

  GetSecretVersionReferencesData({
    required this.references,
  });
}

@immutable
class GetSecretVersionReferencesVariables {
  final String path;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetSecretVersionReferencesVariables.fromJson(Map<String, dynamic> json)
    : path = nativeFromJson<String>(json['path']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetSecretVersionReferencesVariables otherTyped =
        other as GetSecretVersionReferencesVariables;
    return path == otherTyped.path;
  }

  @override
  int get hashCode => path.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['path'] = nativeToJson<String>(path);
    return json;
  }

  GetSecretVersionReferencesVariables({
    required this.path,
  });
}
