part of 'default.dart';

class UpdateTeamGitHubSettingsVariablesBuilder {
  String teamId;
  Optional<String> _githubBaseUrl = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _githubApiBaseUrl = Optional.optional(nativeFromJson, nativeToJson);
  Optional<List<int>> _installationIds = Optional.optional(listDeserializer(nativeFromJson), listSerializer(nativeToJson));

  final FirebaseDataConnect _dataConnect;  UpdateTeamGitHubSettingsVariablesBuilder githubBaseUrl(String? t) {
   _githubBaseUrl.value = t;
   return this;
  }
  UpdateTeamGitHubSettingsVariablesBuilder githubApiBaseUrl(String? t) {
   _githubApiBaseUrl.value = t;
   return this;
  }
  UpdateTeamGitHubSettingsVariablesBuilder installationIds(List<int>? t) {
   _installationIds.value = t;
   return this;
  }

  UpdateTeamGitHubSettingsVariablesBuilder(this._dataConnect, {required  this.teamId,});
  Deserializer<UpdateTeamGitHubSettingsData> dataDeserializer = (dynamic json)  => UpdateTeamGitHubSettingsData.fromJson(jsonDecode(json));
  Serializer<UpdateTeamGitHubSettingsVariables> varsSerializer = (UpdateTeamGitHubSettingsVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateTeamGitHubSettingsData, UpdateTeamGitHubSettingsVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateTeamGitHubSettingsData, UpdateTeamGitHubSettingsVariables> ref() {
    UpdateTeamGitHubSettingsVariables vars= UpdateTeamGitHubSettingsVariables(teamId: teamId,githubBaseUrl: _githubBaseUrl,githubApiBaseUrl: _githubApiBaseUrl,installationIds: _installationIds,);
    return _dataConnect.mutation("UpdateTeamGitHubSettings", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateTeamGitHubSettingsTeamUpdate {
  final String id;
  UpdateTeamGitHubSettingsTeamUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateTeamGitHubSettingsTeamUpdate otherTyped = other as UpdateTeamGitHubSettingsTeamUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateTeamGitHubSettingsTeamUpdate({
    required this.id,
  });
}

@immutable
class UpdateTeamGitHubSettingsData {
  final UpdateTeamGitHubSettingsTeamUpdate? team_update;
  UpdateTeamGitHubSettingsData.fromJson(dynamic json):
  
  team_update = json['team_update'] == null ? null : UpdateTeamGitHubSettingsTeamUpdate.fromJson(json['team_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateTeamGitHubSettingsData otherTyped = other as UpdateTeamGitHubSettingsData;
    return team_update == otherTyped.team_update;
    
  }
  @override
  int get hashCode => team_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (team_update != null) {
      json['team_update'] = team_update!.toJson();
    }
    return json;
  }

  UpdateTeamGitHubSettingsData({
    this.team_update,
  });
}

@immutable
class UpdateTeamGitHubSettingsVariables {
  final String teamId;
  late final Optional<String>githubBaseUrl;
  late final Optional<String>githubApiBaseUrl;
  late final Optional<List<int>>installationIds;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateTeamGitHubSettingsVariables.fromJson(Map<String, dynamic> json):
  
  teamId = nativeFromJson<String>(json['teamId']) {
  
  
  
    githubBaseUrl = Optional.optional(nativeFromJson, nativeToJson);
    githubBaseUrl.value = json['githubBaseUrl'] == null ? null : nativeFromJson<String>(json['githubBaseUrl']);
  
  
    githubApiBaseUrl = Optional.optional(nativeFromJson, nativeToJson);
    githubApiBaseUrl.value = json['githubApiBaseUrl'] == null ? null : nativeFromJson<String>(json['githubApiBaseUrl']);
  
  
    installationIds = Optional.optional(listDeserializer(nativeFromJson), listSerializer(nativeToJson));
    installationIds.value = json['installationIds'] == null ? null : (json['installationIds'] as List<dynamic>)
        .map((e) => nativeFromJson<int>(e))
        .toList();
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateTeamGitHubSettingsVariables otherTyped = other as UpdateTeamGitHubSettingsVariables;
    return teamId == otherTyped.teamId && 
    githubBaseUrl == otherTyped.githubBaseUrl && 
    githubApiBaseUrl == otherTyped.githubApiBaseUrl && 
    installationIds == otherTyped.installationIds;
    
  }
  @override
  int get hashCode => Object.hashAll([teamId.hashCode, githubBaseUrl.hashCode, githubApiBaseUrl.hashCode, installationIds.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    if(githubBaseUrl.state == OptionalState.set) {
      json['githubBaseUrl'] = githubBaseUrl.toJson();
    }
    if(githubApiBaseUrl.state == OptionalState.set) {
      json['githubApiBaseUrl'] = githubApiBaseUrl.toJson();
    }
    if(installationIds.state == OptionalState.set) {
      json['installationIds'] = installationIds.toJson();
    }
    return json;
  }

  UpdateTeamGitHubSettingsVariables({
    required this.teamId,
    required this.githubBaseUrl,
    required this.githubApiBaseUrl,
    required this.installationIds,
  });
}

