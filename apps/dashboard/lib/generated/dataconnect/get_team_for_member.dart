part of 'default.dart';

class GetTeamForMemberVariablesBuilder {
  String teamId;

  final FirebaseDataConnect _dataConnect;
  GetTeamForMemberVariablesBuilder(this._dataConnect, {required  this.teamId,});
  Deserializer<GetTeamForMemberData> dataDeserializer = (dynamic json)  => GetTeamForMemberData.fromJson(jsonDecode(json));
  Serializer<GetTeamForMemberVariables> varsSerializer = (GetTeamForMemberVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetTeamForMemberData, GetTeamForMemberVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetTeamForMemberData, GetTeamForMemberVariables> ref() {
    GetTeamForMemberVariables vars= GetTeamForMemberVariables(teamId: teamId,);
    return _dataConnect.query("GetTeamForMember", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetTeamForMemberTeamMember {
  final String teamId;
  GetTeamForMemberTeamMember.fromJson(dynamic json):
  
  teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetTeamForMemberTeamMember otherTyped = other as GetTeamForMemberTeamMember;
    return teamId == otherTyped.teamId;
    
  }
  @override
  int get hashCode => teamId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  GetTeamForMemberTeamMember({
    required this.teamId,
  });
}

@immutable
class GetTeamForMemberTeam {
  final String id;
  final String name;
  final bool? aiEnabled;
  final String? githubApiBaseUrl;
  final String? githubBaseUrl;
  final List<int>? installationIds;
  GetTeamForMemberTeam.fromJson(dynamic json):
  
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

    final GetTeamForMemberTeam otherTyped = other as GetTeamForMemberTeam;
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

  GetTeamForMemberTeam({
    required this.id,
    required this.name,
    this.aiEnabled,
    this.githubApiBaseUrl,
    this.githubBaseUrl,
    this.installationIds,
  });
}

@immutable
class GetTeamForMemberData {
  final GetTeamForMemberTeamMember? teamMember;
  final GetTeamForMemberTeam? team;
  GetTeamForMemberData.fromJson(dynamic json):
  
  teamMember = json['teamMember'] == null ? null : GetTeamForMemberTeamMember.fromJson(json['teamMember']),
  team = json['team'] == null ? null : GetTeamForMemberTeam.fromJson(json['team']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetTeamForMemberData otherTyped = other as GetTeamForMemberData;
    return teamMember == otherTyped.teamMember && 
    team == otherTyped.team;
    
  }
  @override
  int get hashCode => Object.hashAll([teamMember.hashCode, team.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (teamMember != null) {
      json['teamMember'] = teamMember!.toJson();
    }
    if (team != null) {
      json['team'] = team!.toJson();
    }
    return json;
  }

  GetTeamForMemberData({
    this.teamMember,
    this.team,
  });
}

@immutable
class GetTeamForMemberVariables {
  final String teamId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetTeamForMemberVariables.fromJson(Map<String, dynamic> json):
  
  teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetTeamForMemberVariables otherTyped = other as GetTeamForMemberVariables;
    return teamId == otherTyped.teamId;
    
  }
  @override
  int get hashCode => teamId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  GetTeamForMemberVariables({
    required this.teamId,
  });
}

