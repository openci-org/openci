part of 'github.dart';

class GetGitHubConnectionSessionVariablesBuilder {
  String teamId;
  String userId;
  String referenceHash;

  final FirebaseDataConnect _dataConnect;
  GetGitHubConnectionSessionVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.userId,
    required this.referenceHash,
  });
  Deserializer<GetGitHubConnectionSessionData> dataDeserializer =
      (dynamic json) =>
          GetGitHubConnectionSessionData.fromJson(jsonDecode(json));
  Serializer<GetGitHubConnectionSessionVariables> varsSerializer =
      (GetGitHubConnectionSessionVariables vars) => jsonEncode(vars.toJson());
  Future<
    QueryResult<
      GetGitHubConnectionSessionData,
      GetGitHubConnectionSessionVariables
    >
  >
  execute() {
    return ref().execute();
  }

  QueryRef<GetGitHubConnectionSessionData, GetGitHubConnectionSessionVariables>
  ref() {
    GetGitHubConnectionSessionVariables vars =
        GetGitHubConnectionSessionVariables(
          teamId: teamId,
          userId: userId,
          referenceHash: referenceHash,
        );
    return _dataConnect.query(
      "GetGitHubConnectionSession",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetGitHubConnectionSessionSession {
  final String id;
  final String teamId;
  final String userId;
  final BigInt githubUserId;
  final String? accessTokenSecretVersionPath;
  final BigInt expiresAt;
  GetGitHubConnectionSessionSession.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']),
      teamId = nativeFromJson<String>(json['teamId']),
      userId = nativeFromJson<String>(json['userId']),
      githubUserId = bigIntFromJson(json['githubUserId']),
      accessTokenSecretVersionPath =
          json['accessTokenSecretVersionPath'] == null
          ? null
          : nativeFromJson<String>(json['accessTokenSecretVersionPath']),
      expiresAt = bigIntFromJson(json['expiresAt']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetGitHubConnectionSessionSession otherTyped =
        other as GetGitHubConnectionSessionSession;
    return id == otherTyped.id &&
        teamId == otherTyped.teamId &&
        userId == otherTyped.userId &&
        githubUserId == otherTyped.githubUserId &&
        accessTokenSecretVersionPath ==
            otherTyped.accessTokenSecretVersionPath &&
        expiresAt == otherTyped.expiresAt;
  }

  @override
  int get hashCode => Object.hashAll([
    id.hashCode,
    teamId.hashCode,
    userId.hashCode,
    githubUserId.hashCode,
    accessTokenSecretVersionPath.hashCode,
    expiresAt.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['teamId'] = nativeToJson<String>(teamId);
    json['userId'] = nativeToJson<String>(userId);
    json['githubUserId'] = bigIntToJson(githubUserId);
    if (accessTokenSecretVersionPath != null) {
      json['accessTokenSecretVersionPath'] = nativeToJson<String?>(
        accessTokenSecretVersionPath,
      );
    }
    json['expiresAt'] = bigIntToJson(expiresAt);
    return json;
  }

  GetGitHubConnectionSessionSession({
    required this.id,
    required this.teamId,
    required this.userId,
    required this.githubUserId,
    this.accessTokenSecretVersionPath,
    required this.expiresAt,
  });
}

@immutable
class GetGitHubConnectionSessionData {
  final GetGitHubConnectionSessionSession? session;
  GetGitHubConnectionSessionData.fromJson(dynamic json)
    : session = json['session'] == null
          ? null
          : GetGitHubConnectionSessionSession.fromJson(json['session']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetGitHubConnectionSessionData otherTyped =
        other as GetGitHubConnectionSessionData;
    return session == otherTyped.session;
  }

  @override
  int get hashCode => session.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (session != null) {
      json['session'] = session!.toJson();
    }
    return json;
  }

  GetGitHubConnectionSessionData({
    this.session,
  });
}

@immutable
class GetGitHubConnectionSessionVariables {
  final String teamId;
  final String userId;
  final String referenceHash;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetGitHubConnectionSessionVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']),
      userId = nativeFromJson<String>(json['userId']),
      referenceHash = nativeFromJson<String>(json['referenceHash']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetGitHubConnectionSessionVariables otherTyped =
        other as GetGitHubConnectionSessionVariables;
    return teamId == otherTyped.teamId &&
        userId == otherTyped.userId &&
        referenceHash == otherTyped.referenceHash;
  }

  @override
  int get hashCode => Object.hashAll([
    teamId.hashCode,
    userId.hashCode,
    referenceHash.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['userId'] = nativeToJson<String>(userId);
    json['referenceHash'] = nativeToJson<String>(referenceHash);
    return json;
  }

  GetGitHubConnectionSessionVariables({
    required this.teamId,
    required this.userId,
    required this.referenceHash,
  });
}
