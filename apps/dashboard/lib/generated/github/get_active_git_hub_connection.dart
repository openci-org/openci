part of 'github.dart';

class GetActiveGitHubConnectionVariablesBuilder {
  String githubApiBaseUrl;
  BigInt githubAppId;
  BigInt installationId;

  final FirebaseDataConnect _dataConnect;
  GetActiveGitHubConnectionVariablesBuilder(
    this._dataConnect, {
    required this.githubApiBaseUrl,
    required this.githubAppId,
    required this.installationId,
  });
  Deserializer<GetActiveGitHubConnectionData> dataDeserializer =
      (dynamic json) =>
          GetActiveGitHubConnectionData.fromJson(jsonDecode(json));
  Serializer<GetActiveGitHubConnectionVariables> varsSerializer =
      (GetActiveGitHubConnectionVariables vars) => jsonEncode(vars.toJson());
  Future<
    QueryResult<
      GetActiveGitHubConnectionData,
      GetActiveGitHubConnectionVariables
    >
  >
  execute() {
    return ref().execute();
  }

  QueryRef<GetActiveGitHubConnectionData, GetActiveGitHubConnectionVariables>
  ref() {
    GetActiveGitHubConnectionVariables vars =
        GetActiveGitHubConnectionVariables(
          githubApiBaseUrl: githubApiBaseUrl,
          githubAppId: githubAppId,
          installationId: installationId,
        );
    return _dataConnect.query(
      "GetActiveGitHubConnection",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetActiveGitHubConnectionConnection {
  final String id;
  final String teamId;
  final String githubApiBaseUrl;
  final BigInt githubAppId;
  final BigInt installationId;
  final BigInt accountId;
  final String accountType;
  final String accountLogin;
  final String status;
  final BigInt verifiedAt;
  GetActiveGitHubConnectionConnection.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']),
      teamId = nativeFromJson<String>(json['teamId']),
      githubApiBaseUrl = nativeFromJson<String>(json['githubApiBaseUrl']),
      githubAppId = bigIntFromJson(json['githubAppId']),
      installationId = bigIntFromJson(json['installationId']),
      accountId = bigIntFromJson(json['accountId']),
      accountType = nativeFromJson<String>(json['accountType']),
      accountLogin = nativeFromJson<String>(json['accountLogin']),
      status = nativeFromJson<String>(json['status']),
      verifiedAt = bigIntFromJson(json['verifiedAt']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetActiveGitHubConnectionConnection otherTyped =
        other as GetActiveGitHubConnectionConnection;
    return id == otherTyped.id &&
        teamId == otherTyped.teamId &&
        githubApiBaseUrl == otherTyped.githubApiBaseUrl &&
        githubAppId == otherTyped.githubAppId &&
        installationId == otherTyped.installationId &&
        accountId == otherTyped.accountId &&
        accountType == otherTyped.accountType &&
        accountLogin == otherTyped.accountLogin &&
        status == otherTyped.status &&
        verifiedAt == otherTyped.verifiedAt;
  }

  @override
  int get hashCode => Object.hashAll([
    id.hashCode,
    teamId.hashCode,
    githubApiBaseUrl.hashCode,
    githubAppId.hashCode,
    installationId.hashCode,
    accountId.hashCode,
    accountType.hashCode,
    accountLogin.hashCode,
    status.hashCode,
    verifiedAt.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['teamId'] = nativeToJson<String>(teamId);
    json['githubApiBaseUrl'] = nativeToJson<String>(githubApiBaseUrl);
    json['githubAppId'] = bigIntToJson(githubAppId);
    json['installationId'] = bigIntToJson(installationId);
    json['accountId'] = bigIntToJson(accountId);
    json['accountType'] = nativeToJson<String>(accountType);
    json['accountLogin'] = nativeToJson<String>(accountLogin);
    json['status'] = nativeToJson<String>(status);
    json['verifiedAt'] = bigIntToJson(verifiedAt);
    return json;
  }

  GetActiveGitHubConnectionConnection({
    required this.id,
    required this.teamId,
    required this.githubApiBaseUrl,
    required this.githubAppId,
    required this.installationId,
    required this.accountId,
    required this.accountType,
    required this.accountLogin,
    required this.status,
    required this.verifiedAt,
  });
}

@immutable
class GetActiveGitHubConnectionData {
  final GetActiveGitHubConnectionConnection? connection;
  GetActiveGitHubConnectionData.fromJson(dynamic json)
    : connection = json['connection'] == null
          ? null
          : GetActiveGitHubConnectionConnection.fromJson(json['connection']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetActiveGitHubConnectionData otherTyped =
        other as GetActiveGitHubConnectionData;
    return connection == otherTyped.connection;
  }

  @override
  int get hashCode => connection.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (connection != null) {
      json['connection'] = connection!.toJson();
    }
    return json;
  }

  GetActiveGitHubConnectionData({
    this.connection,
  });
}

@immutable
class GetActiveGitHubConnectionVariables {
  final String githubApiBaseUrl;
  final BigInt githubAppId;
  final BigInt installationId;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetActiveGitHubConnectionVariables.fromJson(Map<String, dynamic> json)
    : githubApiBaseUrl = nativeFromJson<String>(json['githubApiBaseUrl']),
      githubAppId = bigIntFromJson(json['githubAppId']),
      installationId = bigIntFromJson(json['installationId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetActiveGitHubConnectionVariables otherTyped =
        other as GetActiveGitHubConnectionVariables;
    return githubApiBaseUrl == otherTyped.githubApiBaseUrl &&
        githubAppId == otherTyped.githubAppId &&
        installationId == otherTyped.installationId;
  }

  @override
  int get hashCode => Object.hashAll([
    githubApiBaseUrl.hashCode,
    githubAppId.hashCode,
    installationId.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['githubApiBaseUrl'] = nativeToJson<String>(githubApiBaseUrl);
    json['githubAppId'] = bigIntToJson(githubAppId);
    json['installationId'] = bigIntToJson(installationId);
    return json;
  }

  GetActiveGitHubConnectionVariables({
    required this.githubApiBaseUrl,
    required this.githubAppId,
    required this.installationId,
  });
}
