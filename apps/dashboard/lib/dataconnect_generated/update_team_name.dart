part of 'generated.dart';

class UpdateTeamNameVariablesBuilder {
  String teamId;
  String newName;

  final FirebaseDataConnect _dataConnect;
  UpdateTeamNameVariablesBuilder(this._dataConnect, {required  this.teamId,required  this.newName,});
  Deserializer<UpdateTeamNameData> dataDeserializer = (dynamic json)  => UpdateTeamNameData.fromJson(jsonDecode(json));
  Serializer<UpdateTeamNameVariables> varsSerializer = (UpdateTeamNameVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateTeamNameData, UpdateTeamNameVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateTeamNameData, UpdateTeamNameVariables> ref() {
    UpdateTeamNameVariables vars= UpdateTeamNameVariables(teamId: teamId,newName: newName,);
    return _dataConnect.mutation("UpdateTeamName", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateTeamNameQuery {
  final UpdateTeamNameQueryTeam? team;
  UpdateTeamNameQuery.fromJson(dynamic json):
  
  team = json['team'] == null ? null : UpdateTeamNameQueryTeam.fromJson(json['team']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateTeamNameQuery otherTyped = other as UpdateTeamNameQuery;
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

  UpdateTeamNameQuery({
    this.team,
  });
}

@immutable
class UpdateTeamNameQueryTeam {
  final List<String> members;
  UpdateTeamNameQueryTeam.fromJson(dynamic json):
  
  members = (json['members'] as List<dynamic>)
        .map((e) => nativeFromJson<String>(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateTeamNameQueryTeam otherTyped = other as UpdateTeamNameQueryTeam;
    return members == otherTyped.members;
    
  }
  @override
  int get hashCode => members.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['members'] = members.map((e) => nativeToJson<String>(e)).toList();
    return json;
  }

  UpdateTeamNameQueryTeam({
    required this.members,
  });
}

@immutable
class UpdateTeamNameTeamUpdate {
  final String id;
  UpdateTeamNameTeamUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateTeamNameTeamUpdate otherTyped = other as UpdateTeamNameTeamUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateTeamNameTeamUpdate({
    required this.id,
  });
}

@immutable
class UpdateTeamNameData {
  final UpdateTeamNameQuery? query;
  final UpdateTeamNameTeamUpdate? team_update;
  UpdateTeamNameData.fromJson(dynamic json):
  
  query = json['query'] == null ? null : UpdateTeamNameQuery.fromJson(json['query']),
  team_update = json['team_update'] == null ? null : UpdateTeamNameTeamUpdate.fromJson(json['team_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateTeamNameData otherTyped = other as UpdateTeamNameData;
    return query == otherTyped.query && 
    team_update == otherTyped.team_update;
    
  }
  @override
  int get hashCode => Object.hashAll([query.hashCode, team_update.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (query != null) {
      json['query'] = query!.toJson();
    }
    if (team_update != null) {
      json['team_update'] = team_update!.toJson();
    }
    return json;
  }

  UpdateTeamNameData({
    this.query,
    this.team_update,
  });
}

@immutable
class UpdateTeamNameVariables {
  final String teamId;
  final String newName;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateTeamNameVariables.fromJson(Map<String, dynamic> json):
  
  teamId = nativeFromJson<String>(json['teamId']),
  newName = nativeFromJson<String>(json['newName']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateTeamNameVariables otherTyped = other as UpdateTeamNameVariables;
    return teamId == otherTyped.teamId && 
    newName == otherTyped.newName;
    
  }
  @override
  int get hashCode => Object.hashAll([teamId.hashCode, newName.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['newName'] = nativeToJson<String>(newName);
    return json;
  }

  UpdateTeamNameVariables({
    required this.teamId,
    required this.newName,
  });
}

