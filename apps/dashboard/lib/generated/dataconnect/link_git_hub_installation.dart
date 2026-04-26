part of 'default.dart';

class LinkGitHubInstallationVariablesBuilder {
  String teamId;
  int installationId;

  final FirebaseDataConnect _dataConnect;
  LinkGitHubInstallationVariablesBuilder(this._dataConnect, {required  this.teamId,required  this.installationId,});
  Deserializer<LinkGitHubInstallationData> dataDeserializer = (dynamic json)  => LinkGitHubInstallationData.fromJson(jsonDecode(json));
  Serializer<LinkGitHubInstallationVariables> varsSerializer = (LinkGitHubInstallationVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<LinkGitHubInstallationData, LinkGitHubInstallationVariables>> execute() {
    return ref().execute();
  }

  MutationRef<LinkGitHubInstallationData, LinkGitHubInstallationVariables> ref() {
    LinkGitHubInstallationVariables vars= LinkGitHubInstallationVariables(teamId: teamId,installationId: installationId,);
    return _dataConnect.mutation("LinkGitHubInstallation", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class LinkGitHubInstallationTeamUpdate {
  final String id;
  LinkGitHubInstallationTeamUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final LinkGitHubInstallationTeamUpdate otherTyped = other as LinkGitHubInstallationTeamUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  LinkGitHubInstallationTeamUpdate({
    required this.id,
  });
}

@immutable
class LinkGitHubInstallationData {
  final LinkGitHubInstallationTeamUpdate? team_update;
  LinkGitHubInstallationData.fromJson(dynamic json):
  
  team_update = json['team_update'] == null ? null : LinkGitHubInstallationTeamUpdate.fromJson(json['team_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final LinkGitHubInstallationData otherTyped = other as LinkGitHubInstallationData;
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

  LinkGitHubInstallationData({
    this.team_update,
  });
}

@immutable
class LinkGitHubInstallationVariables {
  final String teamId;
  final int installationId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  LinkGitHubInstallationVariables.fromJson(Map<String, dynamic> json):
  
  teamId = nativeFromJson<String>(json['teamId']),
  installationId = nativeFromJson<int>(json['installationId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final LinkGitHubInstallationVariables otherTyped = other as LinkGitHubInstallationVariables;
    return teamId == otherTyped.teamId && 
    installationId == otherTyped.installationId;
    
  }
  @override
  int get hashCode => Object.hashAll([teamId.hashCode, installationId.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['installationId'] = nativeToJson<int>(installationId);
    return json;
  }

  LinkGitHubInstallationVariables({
    required this.teamId,
    required this.installationId,
  });
}

