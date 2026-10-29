part of 'github.dart';

class GetGitHubConnectionsVariablesBuilder {
  String teamId;

  final FirebaseDataConnect _dataConnect;
  GetGitHubConnectionsVariablesBuilder(
    this._dataConnect, {
    required this.teamId,
  });
  Deserializer<GetGitHubConnectionsData> dataDeserializer = (dynamic json) =>
      GetGitHubConnectionsData.fromJson(jsonDecode(json));
  Serializer<GetGitHubConnectionsVariables> varsSerializer =
      (GetGitHubConnectionsVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetGitHubConnectionsData, GetGitHubConnectionsVariables>>
  execute() {
    return ref().execute();
  }

  QueryRef<GetGitHubConnectionsData, GetGitHubConnectionsVariables> ref() {
    GetGitHubConnectionsVariables vars = GetGitHubConnectionsVariables(
      teamId: teamId,
    );
    return _dataConnect.query(
      "GetGitHubConnections",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetGitHubConnectionsConnections {
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
  GetGitHubConnectionsConnections.fromJson(dynamic json)
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

    final GetGitHubConnectionsConnections otherTyped =
        other as GetGitHubConnectionsConnections;
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

  GetGitHubConnectionsConnections({
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
class GetGitHubConnectionsData {
  final List<GetGitHubConnectionsConnections> connections;
  GetGitHubConnectionsData.fromJson(dynamic json)
    : connections = (json['connections'] as List<dynamic>)
          .map((e) => GetGitHubConnectionsConnections.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetGitHubConnectionsData otherTyped =
        other as GetGitHubConnectionsData;
    return connections == otherTyped.connections;
  }

  @override
  int get hashCode => connections.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['connections'] = connections.map((e) => e.toJson()).toList();
    return json;
  }

  GetGitHubConnectionsData({
    required this.connections,
  });
}

@immutable
class GetGitHubConnectionsVariables {
  final String teamId;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetGitHubConnectionsVariables.fromJson(Map<String, dynamic> json)
    : teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetGitHubConnectionsVariables otherTyped =
        other as GetGitHubConnectionsVariables;
    return teamId == otherTyped.teamId;
  }

  @override
  int get hashCode => teamId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  GetGitHubConnectionsVariables({
    required this.teamId,
  });
}
