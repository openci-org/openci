part of 'github.dart';

class GetExpiredGitHubConnectionCredentialsVariablesBuilder {
  final FirebaseDataConnect _dataConnect;
  GetExpiredGitHubConnectionCredentialsVariablesBuilder(
    this._dataConnect,
  );
  Deserializer<GetExpiredGitHubConnectionCredentialsData> dataDeserializer =
      (dynamic json) =>
          GetExpiredGitHubConnectionCredentialsData.fromJson(jsonDecode(json));

  Future<QueryResult<GetExpiredGitHubConnectionCredentialsData, void>>
  execute() {
    return ref().execute();
  }

  QueryRef<GetExpiredGitHubConnectionCredentialsData, void> ref() {
    return _dataConnect.query(
      "GetExpiredGitHubConnectionCredentials",
      dataDeserializer,
      emptySerializer,
      null,
    );
  }
}

@immutable
class GetExpiredGitHubConnectionCredentialsRequests {
  final String id;
  final String codeVerifierSecretVersionPath;
  GetExpiredGitHubConnectionCredentialsRequests.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']),
      codeVerifierSecretVersionPath = nativeFromJson<String>(
        json['codeVerifierSecretVersionPath'],
      );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetExpiredGitHubConnectionCredentialsRequests otherTyped =
        other as GetExpiredGitHubConnectionCredentialsRequests;
    return id == otherTyped.id &&
        codeVerifierSecretVersionPath ==
            otherTyped.codeVerifierSecretVersionPath;
  }

  @override
  int get hashCode =>
      Object.hashAll([id.hashCode, codeVerifierSecretVersionPath.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['codeVerifierSecretVersionPath'] = nativeToJson<String>(
      codeVerifierSecretVersionPath,
    );
    return json;
  }

  GetExpiredGitHubConnectionCredentialsRequests({
    required this.id,
    required this.codeVerifierSecretVersionPath,
  });
}

@immutable
class GetExpiredGitHubConnectionCredentialsSessions {
  final String id;
  final String? accessTokenSecretVersionPath;
  GetExpiredGitHubConnectionCredentialsSessions.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']),
      accessTokenSecretVersionPath =
          json['accessTokenSecretVersionPath'] == null
          ? null
          : nativeFromJson<String>(json['accessTokenSecretVersionPath']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetExpiredGitHubConnectionCredentialsSessions otherTyped =
        other as GetExpiredGitHubConnectionCredentialsSessions;
    return id == otherTyped.id &&
        accessTokenSecretVersionPath == otherTyped.accessTokenSecretVersionPath;
  }

  @override
  int get hashCode =>
      Object.hashAll([id.hashCode, accessTokenSecretVersionPath.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    if (accessTokenSecretVersionPath != null) {
      json['accessTokenSecretVersionPath'] = nativeToJson<String?>(
        accessTokenSecretVersionPath,
      );
    }
    return json;
  }

  GetExpiredGitHubConnectionCredentialsSessions({
    required this.id,
    this.accessTokenSecretVersionPath,
  });
}

@immutable
class GetExpiredGitHubConnectionCredentialsData {
  final List<GetExpiredGitHubConnectionCredentialsRequests> requests;
  final List<GetExpiredGitHubConnectionCredentialsSessions> sessions;
  GetExpiredGitHubConnectionCredentialsData.fromJson(dynamic json)
    : requests = (json['requests'] as List<dynamic>)
          .map((e) => GetExpiredGitHubConnectionCredentialsRequests.fromJson(e))
          .toList(),
      sessions = (json['sessions'] as List<dynamic>)
          .map((e) => GetExpiredGitHubConnectionCredentialsSessions.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetExpiredGitHubConnectionCredentialsData otherTyped =
        other as GetExpiredGitHubConnectionCredentialsData;
    return requests == otherTyped.requests && sessions == otherTyped.sessions;
  }

  @override
  int get hashCode => Object.hashAll([requests.hashCode, sessions.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['requests'] = requests.map((e) => e.toJson()).toList();
    json['sessions'] = sessions.map((e) => e.toJson()).toList();
    return json;
  }

  GetExpiredGitHubConnectionCredentialsData({
    required this.requests,
    required this.sessions,
  });
}
