part of 'github.dart';

class CreateGitHubConnectionRequestVariablesBuilder {
  String id;
  String userId;
  String teamId;
  String stateHash;
  String codeVerifierSecretVersionPath;

  final FirebaseDataConnect _dataConnect;
  CreateGitHubConnectionRequestVariablesBuilder(
    this._dataConnect, {
    required this.id,
    required this.userId,
    required this.teamId,
    required this.stateHash,
    required this.codeVerifierSecretVersionPath,
  });
  Deserializer<CreateGitHubConnectionRequestData> dataDeserializer =
      (dynamic json) =>
          CreateGitHubConnectionRequestData.fromJson(jsonDecode(json));
  Serializer<CreateGitHubConnectionRequestVariables> varsSerializer =
      (CreateGitHubConnectionRequestVariables vars) =>
          jsonEncode(vars.toJson());
  Future<
    OperationResult<
      CreateGitHubConnectionRequestData,
      CreateGitHubConnectionRequestVariables
    >
  >
  execute() {
    return ref().execute();
  }

  MutationRef<
    CreateGitHubConnectionRequestData,
    CreateGitHubConnectionRequestVariables
  >
  ref() {
    CreateGitHubConnectionRequestVariables vars =
        CreateGitHubConnectionRequestVariables(
          id: id,
          userId: userId,
          teamId: teamId,
          stateHash: stateHash,
          codeVerifierSecretVersionPath: codeVerifierSecretVersionPath,
        );
    return _dataConnect.mutation(
      "CreateGitHubConnectionRequest",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class CreateGitHubConnectionRequestGitHubConnectionRequestInsert {
  final String id;
  CreateGitHubConnectionRequestGitHubConnectionRequestInsert.fromJson(
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

    final CreateGitHubConnectionRequestGitHubConnectionRequestInsert
    otherTyped =
        other as CreateGitHubConnectionRequestGitHubConnectionRequestInsert;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateGitHubConnectionRequestGitHubConnectionRequestInsert({
    required this.id,
  });
}

@immutable
class CreateGitHubConnectionRequestData {
  final CreateGitHubConnectionRequestGitHubConnectionRequestInsert
  gitHubConnectionRequest_insert;
  CreateGitHubConnectionRequestData.fromJson(dynamic json)
    : gitHubConnectionRequest_insert =
          CreateGitHubConnectionRequestGitHubConnectionRequestInsert.fromJson(
            json['gitHubConnectionRequest_insert'],
          );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreateGitHubConnectionRequestData otherTyped =
        other as CreateGitHubConnectionRequestData;
    return gitHubConnectionRequest_insert ==
        otherTyped.gitHubConnectionRequest_insert;
  }

  @override
  int get hashCode => gitHubConnectionRequest_insert.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['gitHubConnectionRequest_insert'] = gitHubConnectionRequest_insert
        .toJson();
    return json;
  }

  CreateGitHubConnectionRequestData({
    required this.gitHubConnectionRequest_insert,
  });
}

@immutable
class CreateGitHubConnectionRequestVariables {
  final String id;
  final String userId;
  final String teamId;
  final String stateHash;
  final String codeVerifierSecretVersionPath;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  CreateGitHubConnectionRequestVariables.fromJson(Map<String, dynamic> json)
    : id = nativeFromJson<String>(json['id']),
      userId = nativeFromJson<String>(json['userId']),
      teamId = nativeFromJson<String>(json['teamId']),
      stateHash = nativeFromJson<String>(json['stateHash']),
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

    final CreateGitHubConnectionRequestVariables otherTyped =
        other as CreateGitHubConnectionRequestVariables;
    return id == otherTyped.id &&
        userId == otherTyped.userId &&
        teamId == otherTyped.teamId &&
        stateHash == otherTyped.stateHash &&
        codeVerifierSecretVersionPath ==
            otherTyped.codeVerifierSecretVersionPath;
  }

  @override
  int get hashCode => Object.hashAll([
    id.hashCode,
    userId.hashCode,
    teamId.hashCode,
    stateHash.hashCode,
    codeVerifierSecretVersionPath.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['userId'] = nativeToJson<String>(userId);
    json['teamId'] = nativeToJson<String>(teamId);
    json['stateHash'] = nativeToJson<String>(stateHash);
    json['codeVerifierSecretVersionPath'] = nativeToJson<String>(
      codeVerifierSecretVersionPath,
    );
    return json;
  }

  CreateGitHubConnectionRequestVariables({
    required this.id,
    required this.userId,
    required this.teamId,
    required this.stateHash,
    required this.codeVerifierSecretVersionPath,
  });
}
