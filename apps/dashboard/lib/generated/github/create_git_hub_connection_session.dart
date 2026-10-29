part of 'github.dart';

class CreateGitHubConnectionSessionVariablesBuilder {
  String id;
  String userId;
  String teamId;
  BigInt githubUserId;
  String referenceHash;
  String accessTokenSecretVersionPath;

  final FirebaseDataConnect _dataConnect;
  CreateGitHubConnectionSessionVariablesBuilder(
    this._dataConnect, {
    required this.id,
    required this.userId,
    required this.teamId,
    required this.githubUserId,
    required this.referenceHash,
    required this.accessTokenSecretVersionPath,
  });
  Deserializer<CreateGitHubConnectionSessionData> dataDeserializer =
      (dynamic json) =>
          CreateGitHubConnectionSessionData.fromJson(jsonDecode(json));
  Serializer<CreateGitHubConnectionSessionVariables> varsSerializer =
      (CreateGitHubConnectionSessionVariables vars) =>
          jsonEncode(vars.toJson());
  Future<
    OperationResult<
      CreateGitHubConnectionSessionData,
      CreateGitHubConnectionSessionVariables
    >
  >
  execute() {
    return ref().execute();
  }

  MutationRef<
    CreateGitHubConnectionSessionData,
    CreateGitHubConnectionSessionVariables
  >
  ref() {
    CreateGitHubConnectionSessionVariables vars =
        CreateGitHubConnectionSessionVariables(
          id: id,
          userId: userId,
          teamId: teamId,
          githubUserId: githubUserId,
          referenceHash: referenceHash,
          accessTokenSecretVersionPath: accessTokenSecretVersionPath,
        );
    return _dataConnect.mutation(
      "CreateGitHubConnectionSession",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class CreateGitHubConnectionSessionGitHubConnectionSessionInsert {
  final String id;
  CreateGitHubConnectionSessionGitHubConnectionSessionInsert.fromJson(
    dynamic json,
  ) : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreateGitHubConnectionSessionGitHubConnectionSessionInsert
    otherTyped =
        other as CreateGitHubConnectionSessionGitHubConnectionSessionInsert;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateGitHubConnectionSessionGitHubConnectionSessionInsert({
    required this.id,
  });
}

@immutable
class CreateGitHubConnectionSessionData {
  final CreateGitHubConnectionSessionGitHubConnectionSessionInsert
  gitHubConnectionSession_insert;
  CreateGitHubConnectionSessionData.fromJson(dynamic json)
    : gitHubConnectionSession_insert =
          CreateGitHubConnectionSessionGitHubConnectionSessionInsert.fromJson(
            json['gitHubConnectionSession_insert'],
          );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreateGitHubConnectionSessionData otherTyped =
        other as CreateGitHubConnectionSessionData;
    return gitHubConnectionSession_insert ==
        otherTyped.gitHubConnectionSession_insert;
  }

  @override
  int get hashCode => gitHubConnectionSession_insert.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['gitHubConnectionSession_insert'] = gitHubConnectionSession_insert
        .toJson();
    return json;
  }

  CreateGitHubConnectionSessionData({
    required this.gitHubConnectionSession_insert,
  });
}

@immutable
class CreateGitHubConnectionSessionVariables {
  final String id;
  final String userId;
  final String teamId;
  final BigInt githubUserId;
  final String referenceHash;
  final String accessTokenSecretVersionPath;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  CreateGitHubConnectionSessionVariables.fromJson(Map<String, dynamic> json)
    : id = nativeFromJson<String>(json['id']),
      userId = nativeFromJson<String>(json['userId']),
      teamId = nativeFromJson<String>(json['teamId']),
      githubUserId = bigIntFromJson(json['githubUserId']),
      referenceHash = nativeFromJson<String>(json['referenceHash']),
      accessTokenSecretVersionPath = nativeFromJson<String>(
        json['accessTokenSecretVersionPath'],
      );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreateGitHubConnectionSessionVariables otherTyped =
        other as CreateGitHubConnectionSessionVariables;
    return id == otherTyped.id &&
        userId == otherTyped.userId &&
        teamId == otherTyped.teamId &&
        githubUserId == otherTyped.githubUserId &&
        referenceHash == otherTyped.referenceHash &&
        accessTokenSecretVersionPath == otherTyped.accessTokenSecretVersionPath;
  }

  @override
  int get hashCode => Object.hashAll([
    id.hashCode,
    userId.hashCode,
    teamId.hashCode,
    githubUserId.hashCode,
    referenceHash.hashCode,
    accessTokenSecretVersionPath.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['userId'] = nativeToJson<String>(userId);
    json['teamId'] = nativeToJson<String>(teamId);
    json['githubUserId'] = bigIntToJson(githubUserId);
    json['referenceHash'] = nativeToJson<String>(referenceHash);
    json['accessTokenSecretVersionPath'] = nativeToJson<String>(
      accessTokenSecretVersionPath,
    );
    return json;
  }

  CreateGitHubConnectionSessionVariables({
    required this.id,
    required this.userId,
    required this.teamId,
    required this.githubUserId,
    required this.referenceHash,
    required this.accessTokenSecretVersionPath,
  });
}
