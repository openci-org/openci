part of 'github.dart';

class ConsumeGitHubConnectionRequestVariablesBuilder {
  String stateHash;

  final FirebaseDataConnect _dataConnect;
  ConsumeGitHubConnectionRequestVariablesBuilder(
    this._dataConnect, {
    required this.stateHash,
  });
  Deserializer<ConsumeGitHubConnectionRequestData> dataDeserializer =
      (dynamic json) =>
          ConsumeGitHubConnectionRequestData.fromJson(jsonDecode(json));
  Serializer<ConsumeGitHubConnectionRequestVariables> varsSerializer =
      (ConsumeGitHubConnectionRequestVariables vars) =>
          jsonEncode(vars.toJson());
  Future<
    OperationResult<
      ConsumeGitHubConnectionRequestData,
      ConsumeGitHubConnectionRequestVariables
    >
  >
  execute() {
    return ref().execute();
  }

  MutationRef<
    ConsumeGitHubConnectionRequestData,
    ConsumeGitHubConnectionRequestVariables
  >
  ref() {
    ConsumeGitHubConnectionRequestVariables vars =
        ConsumeGitHubConnectionRequestVariables(
          stateHash: stateHash,
        );
    return _dataConnect.mutation(
      "ConsumeGitHubConnectionRequest",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class ConsumeGitHubConnectionRequestQuery {
  final ConsumeGitHubConnectionRequestQueryRequest? request;
  ConsumeGitHubConnectionRequestQuery.fromJson(dynamic json)
    : request = json['request'] == null
          ? null
          : ConsumeGitHubConnectionRequestQueryRequest.fromJson(
              json['request'],
            );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ConsumeGitHubConnectionRequestQuery otherTyped =
        other as ConsumeGitHubConnectionRequestQuery;
    return request == otherTyped.request;
  }

  @override
  int get hashCode => request.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (request != null) {
      json['request'] = request!.toJson();
    }
    return json;
  }

  ConsumeGitHubConnectionRequestQuery({
    this.request,
  });
}

@immutable
class ConsumeGitHubConnectionRequestQueryRequest {
  final String id;
  final String userId;
  final String teamId;
  final String codeVerifierSecretVersionPath;
  ConsumeGitHubConnectionRequestQueryRequest.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']),
      userId = nativeFromJson<String>(json['userId']),
      teamId = nativeFromJson<String>(json['teamId']),
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

    final ConsumeGitHubConnectionRequestQueryRequest otherTyped =
        other as ConsumeGitHubConnectionRequestQueryRequest;
    return id == otherTyped.id &&
        userId == otherTyped.userId &&
        teamId == otherTyped.teamId &&
        codeVerifierSecretVersionPath ==
            otherTyped.codeVerifierSecretVersionPath;
  }

  @override
  int get hashCode => Object.hashAll([
    id.hashCode,
    userId.hashCode,
    teamId.hashCode,
    codeVerifierSecretVersionPath.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['userId'] = nativeToJson<String>(userId);
    json['teamId'] = nativeToJson<String>(teamId);
    json['codeVerifierSecretVersionPath'] = nativeToJson<String>(
      codeVerifierSecretVersionPath,
    );
    return json;
  }

  ConsumeGitHubConnectionRequestQueryRequest({
    required this.id,
    required this.userId,
    required this.teamId,
    required this.codeVerifierSecretVersionPath,
  });
}

@immutable
class ConsumeGitHubConnectionRequestData {
  final ConsumeGitHubConnectionRequestQuery? query;
  final int gitHubConnectionRequest_deleteMany;
  ConsumeGitHubConnectionRequestData.fromJson(dynamic json)
    : query = json['query'] == null
          ? null
          : ConsumeGitHubConnectionRequestQuery.fromJson(json['query']),
      gitHubConnectionRequest_deleteMany = nativeFromJson<int>(
        json['gitHubConnectionRequest_deleteMany'],
      );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ConsumeGitHubConnectionRequestData otherTyped =
        other as ConsumeGitHubConnectionRequestData;
    return query == otherTyped.query &&
        gitHubConnectionRequest_deleteMany ==
            otherTyped.gitHubConnectionRequest_deleteMany;
  }

  @override
  int get hashCode => Object.hashAll([
    query.hashCode,
    gitHubConnectionRequest_deleteMany.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (query != null) {
      json['query'] = query!.toJson();
    }
    json['gitHubConnectionRequest_deleteMany'] = nativeToJson<int>(
      gitHubConnectionRequest_deleteMany,
    );
    return json;
  }

  ConsumeGitHubConnectionRequestData({
    this.query,
    required this.gitHubConnectionRequest_deleteMany,
  });
}

@immutable
class ConsumeGitHubConnectionRequestVariables {
  final String stateHash;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  ConsumeGitHubConnectionRequestVariables.fromJson(Map<String, dynamic> json)
    : stateHash = nativeFromJson<String>(json['stateHash']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ConsumeGitHubConnectionRequestVariables otherTyped =
        other as ConsumeGitHubConnectionRequestVariables;
    return stateHash == otherTyped.stateHash;
  }

  @override
  int get hashCode => stateHash.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['stateHash'] = nativeToJson<String>(stateHash);
    return json;
  }

  ConsumeGitHubConnectionRequestVariables({
    required this.stateHash,
  });
}
