part of 'github.dart';

class ConfirmGitHubConnectionVariablesBuilder {
  String teamId;
  String userId;
  String referenceHash;
  String githubApiBaseUrl;
  BigInt githubAppId;
  BigInt installationId;
  BigInt accountId;
  String accountType;
  String accountLogin;

  final FirebaseDataConnect _dataConnect;
  ConfirmGitHubConnectionVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
    required this.userId,
    required this.referenceHash,
    required this.githubApiBaseUrl,
    required this.githubAppId,
    required this.installationId,
    required this.accountId,
    required this.accountType,
    required this.accountLogin,
  });
  Deserializer<ConfirmGitHubConnectionData> dataDeserializer = (dynamic json) =>
      ConfirmGitHubConnectionData.fromJson(jsonDecode(json));
  Serializer<ConfirmGitHubConnectionVariables> varsSerializer =
      (ConfirmGitHubConnectionVariables vars) => jsonEncode(vars.toJson());
  Future<
    OperationResult<
      ConfirmGitHubConnectionData,
      ConfirmGitHubConnectionVariables
    >
  >
  execute() {
    return ref().execute();
  }

  MutationRef<ConfirmGitHubConnectionData, ConfirmGitHubConnectionVariables>
  ref() {
    ConfirmGitHubConnectionVariables vars = ConfirmGitHubConnectionVariables(
      teamId: teamId,
      userId: userId,
      referenceHash: referenceHash,
      githubApiBaseUrl: githubApiBaseUrl,
      githubAppId: githubAppId,
      installationId: installationId,
      accountId: accountId,
      accountType: accountType,
      accountLogin: accountLogin,
    );
    return _dataConnect.mutation(
      "ConfirmGitHubConnection",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class ConfirmGitHubConnectionTeamUpdate {
  final String id;
  ConfirmGitHubConnectionTeamUpdate.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ConfirmGitHubConnectionTeamUpdate otherTyped =
        other as ConfirmGitHubConnectionTeamUpdate;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  ConfirmGitHubConnectionTeamUpdate({
    required this.id,
  });
}

@immutable
class ConfirmGitHubConnectionQuery {
  final ConfirmGitHubConnectionQuerySession? session;
  ConfirmGitHubConnectionQuery.fromJson(dynamic json)
    : session = json['session'] == null
          ? null
          : ConfirmGitHubConnectionQuerySession.fromJson(json['session']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ConfirmGitHubConnectionQuery otherTyped =
        other as ConfirmGitHubConnectionQuery;
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

  ConfirmGitHubConnectionQuery({
    this.session,
  });
}

@immutable
class ConfirmGitHubConnectionQuerySession {
  final BigInt githubUserId;
  final String? accessTokenSecretVersionPath;
  ConfirmGitHubConnectionQuerySession.fromJson(dynamic json)
    : githubUserId = bigIntFromJson(json['githubUserId']),
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

    final ConfirmGitHubConnectionQuerySession otherTyped =
        other as ConfirmGitHubConnectionQuerySession;
    return githubUserId == otherTyped.githubUserId &&
        accessTokenSecretVersionPath == otherTyped.accessTokenSecretVersionPath;
  }

  @override
  int get hashCode => Object.hashAll([
    githubUserId.hashCode,
    accessTokenSecretVersionPath.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['githubUserId'] = bigIntToJson(githubUserId);
    if (accessTokenSecretVersionPath != null) {
      json['accessTokenSecretVersionPath'] = nativeToJson<String?>(
        accessTokenSecretVersionPath,
      );
    }
    return json;
  }

  ConfirmGitHubConnectionQuerySession({
    required this.githubUserId,
    this.accessTokenSecretVersionPath,
  });
}

@immutable
class ConfirmGitHubConnectionConnection {
  final String id;
  ConfirmGitHubConnectionConnection.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ConfirmGitHubConnectionConnection otherTyped =
        other as ConfirmGitHubConnectionConnection;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  ConfirmGitHubConnectionConnection({
    required this.id,
  });
}

@immutable
class ConfirmGitHubConnectionData {
  final ConfirmGitHubConnectionTeamUpdate? team_update;
  final ConfirmGitHubConnectionQuery? query;
  final int gitHubConnectionSession_updateMany;
  final ConfirmGitHubConnectionConnection connection;
  ConfirmGitHubConnectionData.fromJson(dynamic json)
    : team_update = json['team_update'] == null
          ? null
          : ConfirmGitHubConnectionTeamUpdate.fromJson(json['team_update']),
      query = json['query'] == null
          ? null
          : ConfirmGitHubConnectionQuery.fromJson(json['query']),
      gitHubConnectionSession_updateMany = nativeFromJson<int>(
        json['gitHubConnectionSession_updateMany'],
      ),
      connection = ConfirmGitHubConnectionConnection.fromJson(
        json['connection'],
      );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ConfirmGitHubConnectionData otherTyped =
        other as ConfirmGitHubConnectionData;
    return team_update == otherTyped.team_update &&
        query == otherTyped.query &&
        gitHubConnectionSession_updateMany ==
            otherTyped.gitHubConnectionSession_updateMany &&
        connection == otherTyped.connection;
  }

  @override
  int get hashCode => Object.hashAll([
    team_update.hashCode,
    query.hashCode,
    gitHubConnectionSession_updateMany.hashCode,
    connection.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (team_update != null) {
      json['team_update'] = team_update!.toJson();
    }
    if (query != null) {
      json['query'] = query!.toJson();
    }
    json['gitHubConnectionSession_updateMany'] = nativeToJson<int>(
      gitHubConnectionSession_updateMany,
    );
    json['connection'] = connection.toJson();
    return json;
  }

  ConfirmGitHubConnectionData({
    this.team_update,
    this.query,
    required this.gitHubConnectionSession_updateMany,
    required this.connection,
  });
}

@immutable
class ConfirmGitHubConnectionVariables {
  final String teamId;
  final String userId;
  final String referenceHash;
  final String githubApiBaseUrl;
  final BigInt githubAppId;
  final BigInt installationId;
  final BigInt accountId;
  final String accountType;
  final String accountLogin;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  ConfirmGitHubConnectionVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']),
      userId = nativeFromJson<String>(json['userId']),
      referenceHash = nativeFromJson<String>(json['referenceHash']),
      githubApiBaseUrl = nativeFromJson<String>(json['githubApiBaseUrl']),
      githubAppId = bigIntFromJson(json['githubAppId']),
      installationId = bigIntFromJson(json['installationId']),
      accountId = bigIntFromJson(json['accountId']),
      accountType = nativeFromJson<String>(json['accountType']),
      accountLogin = nativeFromJson<String>(json['accountLogin']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ConfirmGitHubConnectionVariables otherTyped =
        other as ConfirmGitHubConnectionVariables;
    return teamId == otherTyped.teamId &&
        userId == otherTyped.userId &&
        referenceHash == otherTyped.referenceHash &&
        githubApiBaseUrl == otherTyped.githubApiBaseUrl &&
        githubAppId == otherTyped.githubAppId &&
        installationId == otherTyped.installationId &&
        accountId == otherTyped.accountId &&
        accountType == otherTyped.accountType &&
        accountLogin == otherTyped.accountLogin;
  }

  @override
  int get hashCode => Object.hashAll([
    teamId.hashCode,
    userId.hashCode,
    referenceHash.hashCode,
    githubApiBaseUrl.hashCode,
    githubAppId.hashCode,
    installationId.hashCode,
    accountId.hashCode,
    accountType.hashCode,
    accountLogin.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['userId'] = nativeToJson<String>(userId);
    json['referenceHash'] = nativeToJson<String>(referenceHash);
    json['githubApiBaseUrl'] = nativeToJson<String>(githubApiBaseUrl);
    json['githubAppId'] = bigIntToJson(githubAppId);
    json['installationId'] = bigIntToJson(installationId);
    json['accountId'] = bigIntToJson(accountId);
    json['accountType'] = nativeToJson<String>(accountType);
    json['accountLogin'] = nativeToJson<String>(accountLogin);
    return json;
  }

  ConfirmGitHubConnectionVariables({
    required this.teamId,
    required this.userId,
    required this.referenceHash,
    required this.githubApiBaseUrl,
    required this.githubAppId,
    required this.installationId,
    required this.accountId,
    required this.accountType,
    required this.accountLogin,
  });
}
