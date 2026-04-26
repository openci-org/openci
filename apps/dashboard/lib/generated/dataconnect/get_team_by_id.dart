part of 'default.dart';

class GetTeamByIdVariablesBuilder {
  String teamId;

  final FirebaseDataConnect _dataConnect;
  GetTeamByIdVariablesBuilder(this._dataConnect, {required  this.teamId,});
  Deserializer<GetTeamByIdData> dataDeserializer = (dynamic json)  => GetTeamByIdData.fromJson(jsonDecode(json));
  Serializer<GetTeamByIdVariables> varsSerializer = (GetTeamByIdVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetTeamByIdData, GetTeamByIdVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetTeamByIdData, GetTeamByIdVariables> ref() {
    GetTeamByIdVariables vars= GetTeamByIdVariables(teamId: teamId,);
    return _dataConnect.query("GetTeamById", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetTeamByIdTeam {
  final String id;
  final String name;
  final bool? aiEnabled;
  final String? githubApiBaseUrl;
  final String? githubBaseUrl;
  final List<int>? installationIds;
  GetTeamByIdTeam.fromJson(dynamic json):
  
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

    final GetTeamByIdTeam otherTyped = other as GetTeamByIdTeam;
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

  GetTeamByIdTeam({
    required this.id,
    required this.name,
    this.aiEnabled,
    this.githubApiBaseUrl,
    this.githubBaseUrl,
    this.installationIds,
  });
}

@immutable
class GetTeamByIdData {
  final GetTeamByIdTeam? team;
  GetTeamByIdData.fromJson(dynamic json):
  
  team = json['team'] == null ? null : GetTeamByIdTeam.fromJson(json['team']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetTeamByIdData otherTyped = other as GetTeamByIdData;
    return team == otherTyped.team;
    
  }
  @override
  int get hashCode => team.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (team != null) {
      json['team'] = team!.toJson();
    }
    return json;
  }

  GetTeamByIdData({
    this.team,
  });
}

@immutable
class GetTeamByIdVariables {
  final String teamId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetTeamByIdVariables.fromJson(Map<String, dynamic> json):
  
  teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetTeamByIdVariables otherTyped = other as GetTeamByIdVariables;
    return teamId == otherTyped.teamId;
    
  }
  @override
  int get hashCode => teamId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  GetTeamByIdVariables({
    required this.teamId,
  });
}

