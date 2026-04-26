part of 'default.dart';

class UpdateTeamNameVariablesBuilder {
  String teamId;
  String name;

  final FirebaseDataConnect _dataConnect;
  UpdateTeamNameVariablesBuilder(this._dataConnect, {required  this.teamId,required  this.name,});
  Deserializer<UpdateTeamNameData> dataDeserializer = (dynamic json)  => UpdateTeamNameData.fromJson(jsonDecode(json));
  Serializer<UpdateTeamNameVariables> varsSerializer = (UpdateTeamNameVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateTeamNameData, UpdateTeamNameVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateTeamNameData, UpdateTeamNameVariables> ref() {
    UpdateTeamNameVariables vars= UpdateTeamNameVariables(teamId: teamId,name: name,);
    return _dataConnect.mutation("UpdateTeamName", dataDeserializer, varsSerializer, vars);
  }
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
  final UpdateTeamNameTeamUpdate? team_update;
  UpdateTeamNameData.fromJson(dynamic json):
  
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

  UpdateTeamNameData({
    this.team_update,
  });
}

@immutable
class UpdateTeamNameVariables {
  final String teamId;
  final String name;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateTeamNameVariables.fromJson(Map<String, dynamic> json):
  
  teamId = nativeFromJson<String>(json['teamId']),
  name = nativeFromJson<String>(json['name']);
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
    name == otherTyped.name;
    
  }
  @override
  int get hashCode => Object.hashAll([teamId.hashCode, name.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['name'] = nativeToJson<String>(name);
    return json;
  }

  UpdateTeamNameVariables({
    required this.teamId,
    required this.name,
  });
}

