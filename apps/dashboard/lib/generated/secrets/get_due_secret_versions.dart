part of 'secrets.dart';

class GetDueSecretVersionsVariablesBuilder {
  final FirebaseDataConnect _dataConnect;
  GetDueSecretVersionsVariablesBuilder(
    this._dataConnect,
  );
  Deserializer<GetDueSecretVersionsData> dataDeserializer = (dynamic json) =>
      GetDueSecretVersionsData.fromJson(jsonDecode(json));

  Future<QueryResult<GetDueSecretVersionsData, void>> execute({
    QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache,
  }) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetDueSecretVersionsData, void> ref() {
    return _dataConnect.query(
      "GetDueSecretVersions",
      dataDeserializer,
      emptySerializer,
      null,
    );
  }
}

@immutable
class GetDueSecretVersionsVersions {
  final String path;
  GetDueSecretVersionsVersions.fromJson(dynamic json)
    : path = nativeFromJson<String>(json['path']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetDueSecretVersionsVersions otherTyped =
        other as GetDueSecretVersionsVersions;
    return path == otherTyped.path;
  }

  @override
  int get hashCode => path.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['path'] = nativeToJson<String>(path);
    return json;
  }

  GetDueSecretVersionsVersions({
    required this.path,
  });
}

@immutable
class GetDueSecretVersionsData {
  final List<GetDueSecretVersionsVersions> versions;
  GetDueSecretVersionsData.fromJson(dynamic json)
    : versions = (json['versions'] as List<dynamic>)
          .map((e) => GetDueSecretVersionsVersions.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetDueSecretVersionsData otherTyped =
        other as GetDueSecretVersionsData;
    return versions == otherTyped.versions;
  }

  @override
  int get hashCode => versions.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['versions'] = versions.map((e) => e.toJson()).toList();
    return json;
  }

  GetDueSecretVersionsData({
    required this.versions,
  });
}
