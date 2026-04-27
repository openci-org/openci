part of 'default.dart';

class ListMyTeamsVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListMyTeamsVariablesBuilder(this._dataConnect, );
  Deserializer<ListMyTeamsData> dataDeserializer = (dynamic json)  => ListMyTeamsData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListMyTeamsData, void>> execute() {
    return ref().execute();
  }

  QueryRef<ListMyTeamsData, void> ref() {
    
    return _dataConnect.query("ListMyTeams", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListMyTeamsTeamMembers {
  final ListMyTeamsTeamMembersTeam team;
  ListMyTeamsTeamMembers.fromJson(dynamic json):
  
  team = ListMyTeamsTeamMembersTeam.fromJson(json['team']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListMyTeamsTeamMembers otherTyped = other as ListMyTeamsTeamMembers;
    return team == otherTyped.team;
    
  }
  @override
  int get hashCode => team.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['team'] = team.toJson();
    return json;
  }

  ListMyTeamsTeamMembers({
    required this.team,
  });
}

@immutable
class ListMyTeamsTeamMembersTeam {
  final String id;
  final String name;
  final List<String>? members;
  final List<int>? installationIds;
  final bool? aiEnabled;
  final String? githubApiBaseUrl;
  final String? githubBaseUrl;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  ListMyTeamsTeamMembersTeam.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  name = nativeFromJson<String>(json['name']),
  members = json['members'] == null ? null : (json['members'] as List<dynamic>)
        .map((e) => nativeFromJson<String>(e))
        .toList(),
  installationIds = json['installationIds'] == null ? null : (json['installationIds'] as List<dynamic>)
        .map((e) => nativeFromJson<int>(e))
        .toList(),
  aiEnabled = json['aiEnabled'] == null ? null : nativeFromJson<bool>(json['aiEnabled']),
  githubApiBaseUrl = json['githubApiBaseUrl'] == null ? null : nativeFromJson<String>(json['githubApiBaseUrl']),
  githubBaseUrl = json['githubBaseUrl'] == null ? null : nativeFromJson<String>(json['githubBaseUrl']),
  createdAt = Timestamp.fromJson(json['createdAt']),
  updatedAt = Timestamp.fromJson(json['updatedAt']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListMyTeamsTeamMembersTeam otherTyped = other as ListMyTeamsTeamMembersTeam;
    return id == otherTyped.id && 
    name == otherTyped.name && 
    members == otherTyped.members && 
    installationIds == otherTyped.installationIds && 
    aiEnabled == otherTyped.aiEnabled && 
    githubApiBaseUrl == otherTyped.githubApiBaseUrl && 
    githubBaseUrl == otherTyped.githubBaseUrl && 
    createdAt == otherTyped.createdAt && 
    updatedAt == otherTyped.updatedAt;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, name.hashCode, members.hashCode, installationIds.hashCode, aiEnabled.hashCode, githubApiBaseUrl.hashCode, githubBaseUrl.hashCode, createdAt.hashCode, updatedAt.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    if (members != null) {
      json['members'] = members?.map((e) => nativeToJson<String>(e)).toList();
    }
    if (installationIds != null) {
      json['installationIds'] = installationIds?.map((e) => nativeToJson<int>(e)).toList();
    }
    if (aiEnabled != null) {
      json['aiEnabled'] = nativeToJson<bool?>(aiEnabled);
    }
    if (githubApiBaseUrl != null) {
      json['githubApiBaseUrl'] = nativeToJson<String?>(githubApiBaseUrl);
    }
    if (githubBaseUrl != null) {
      json['githubBaseUrl'] = nativeToJson<String?>(githubBaseUrl);
    }
    json['createdAt'] = createdAt.toJson();
    json['updatedAt'] = updatedAt.toJson();
    return json;
  }

  ListMyTeamsTeamMembersTeam({
    required this.id,
    required this.name,
    this.members,
    this.installationIds,
    this.aiEnabled,
    this.githubApiBaseUrl,
    this.githubBaseUrl,
    required this.createdAt,
    required this.updatedAt,
  });
}

@immutable
class ListMyTeamsData {
  final List<ListMyTeamsTeamMembers> teamMembers;
  ListMyTeamsData.fromJson(dynamic json):
  
  teamMembers = (json['teamMembers'] as List<dynamic>)
        .map((e) => ListMyTeamsTeamMembers.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListMyTeamsData otherTyped = other as ListMyTeamsData;
    return teamMembers == otherTyped.teamMembers;
    
  }
  @override
  int get hashCode => teamMembers.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamMembers'] = teamMembers.map((e) => e.toJson()).toList();
    return json;
  }

  ListMyTeamsData({
    required this.teamMembers,
  });
}

