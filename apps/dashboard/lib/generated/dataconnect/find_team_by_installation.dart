part of 'default.dart';

class FindTeamByInstallationVariablesBuilder {
  int installationId;

  final FirebaseDataConnect _dataConnect;
  FindTeamByInstallationVariablesBuilder(this._dataConnect, {required  this.installationId,});
  Deserializer<FindTeamByInstallationData> dataDeserializer = (dynamic json)  => FindTeamByInstallationData.fromJson(jsonDecode(json));
  Serializer<FindTeamByInstallationVariables> varsSerializer = (FindTeamByInstallationVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<FindTeamByInstallationData, FindTeamByInstallationVariables>> execute() {
    return ref().execute();
  }

  QueryRef<FindTeamByInstallationData, FindTeamByInstallationVariables> ref() {
    FindTeamByInstallationVariables vars= FindTeamByInstallationVariables(installationId: installationId,);
    return _dataConnect.query("FindTeamByInstallation", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class FindTeamByInstallationTeams {
  final String id;
  final String name;
  final bool? aiEnabled;
  final String? githubApiBaseUrl;
  final String? githubBaseUrl;
  final List<int>? installationIds;
  FindTeamByInstallationTeams.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  name = nativeFromJson<String>(json['name']),
  aiEnabled = json['aiEnabled'] == null ? null : nativeFromJson<bool>(json['aiEnabled']),
  githubApiBaseUrl = json['githubApiBaseUrl'] == null ? null : nativeFromJson<String>(json['githubApiBaseUrl']),
  githubBaseUrl = json['githubBaseUrl'] == null ? null : nativeFromJson<String>(json['githubBaseUrl']),
  installationIds = json['installationIds'] == null ? null : (json['installationIds'] as List<dynamic>)
        .map((e) => nativeFromJson<int>(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final FindTeamByInstallationTeams otherTyped = other as FindTeamByInstallationTeams;
    return id == otherTyped.id && 
    name == otherTyped.name && 
    aiEnabled == otherTyped.aiEnabled && 
    githubApiBaseUrl == otherTyped.githubApiBaseUrl && 
    githubBaseUrl == otherTyped.githubBaseUrl && 
    installationIds == otherTyped.installationIds;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, name.hashCode, aiEnabled.hashCode, githubApiBaseUrl.hashCode, githubBaseUrl.hashCode, installationIds.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    if (aiEnabled != null) {
      json['aiEnabled'] = nativeToJson<bool?>(aiEnabled);
    }
    if (githubApiBaseUrl != null) {
      json['githubApiBaseUrl'] = nativeToJson<String?>(githubApiBaseUrl);
    }
    if (githubBaseUrl != null) {
      json['githubBaseUrl'] = nativeToJson<String?>(githubBaseUrl);
    }
    if (installationIds != null) {
      json['installationIds'] = installationIds?.map((e) => nativeToJson<int>(e)).toList();
    }
    return json;
  }

  FindTeamByInstallationTeams({
    required this.id,
    required this.name,
    this.aiEnabled,
    this.githubApiBaseUrl,
    this.githubBaseUrl,
    this.installationIds,
  });
}

@immutable
class FindTeamByInstallationData {
  final List<FindTeamByInstallationTeams> teams;
  FindTeamByInstallationData.fromJson(dynamic json):
  
  teams = (json['teams'] as List<dynamic>)
        .map((e) => FindTeamByInstallationTeams.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final FindTeamByInstallationData otherTyped = other as FindTeamByInstallationData;
    return teams == otherTyped.teams;
    
  }
  @override
  int get hashCode => teams.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teams'] = teams.map((e) => e.toJson()).toList();
    return json;
  }

  FindTeamByInstallationData({
    required this.teams,
  });
}

@immutable
class FindTeamByInstallationVariables {
  final int installationId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  FindTeamByInstallationVariables.fromJson(Map<String, dynamic> json):
  
  installationId = nativeFromJson<int>(json['installationId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final FindTeamByInstallationVariables otherTyped = other as FindTeamByInstallationVariables;
    return installationId == otherTyped.installationId;
    
  }
  @override
  int get hashCode => installationId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['installationId'] = nativeToJson<int>(installationId);
    return json;
  }

  FindTeamByInstallationVariables({
    required this.installationId,
  });
}

