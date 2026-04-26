part of 'default.dart';

class UpdateTeamAiEnabledVariablesBuilder {
  String teamId;
  bool aiEnabled;

  final FirebaseDataConnect _dataConnect;
  UpdateTeamAiEnabledVariablesBuilder(this._dataConnect, {required  this.teamId,required  this.aiEnabled,});
  Deserializer<UpdateTeamAiEnabledData> dataDeserializer = (dynamic json)  => UpdateTeamAiEnabledData.fromJson(jsonDecode(json));
  Serializer<UpdateTeamAiEnabledVariables> varsSerializer = (UpdateTeamAiEnabledVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateTeamAiEnabledData, UpdateTeamAiEnabledVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateTeamAiEnabledData, UpdateTeamAiEnabledVariables> ref() {
    UpdateTeamAiEnabledVariables vars= UpdateTeamAiEnabledVariables(teamId: teamId,aiEnabled: aiEnabled,);
    return _dataConnect.mutation("UpdateTeamAiEnabled", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateTeamAiEnabledTeamUpdate {
  final String id;
  UpdateTeamAiEnabledTeamUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateTeamAiEnabledTeamUpdate otherTyped = other as UpdateTeamAiEnabledTeamUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateTeamAiEnabledTeamUpdate({
    required this.id,
  });
}

@immutable
class UpdateTeamAiEnabledData {
  final UpdateTeamAiEnabledTeamUpdate? team_update;
  UpdateTeamAiEnabledData.fromJson(dynamic json):
  
  team_update = json['team_update'] == null ? null : UpdateTeamAiEnabledTeamUpdate.fromJson(json['team_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateTeamAiEnabledData otherTyped = other as UpdateTeamAiEnabledData;
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

  UpdateTeamAiEnabledData({
    this.team_update,
  });
}

@immutable
class UpdateTeamAiEnabledVariables {
  final String teamId;
  final bool aiEnabled;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateTeamAiEnabledVariables.fromJson(Map<String, dynamic> json):
  
  teamId = nativeFromJson<String>(json['teamId']),
  aiEnabled = nativeFromJson<bool>(json['aiEnabled']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateTeamAiEnabledVariables otherTyped = other as UpdateTeamAiEnabledVariables;
    return teamId == otherTyped.teamId && 
    aiEnabled == otherTyped.aiEnabled;
    
  }
  @override
  int get hashCode => Object.hashAll([teamId.hashCode, aiEnabled.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['aiEnabled'] = nativeToJson<bool>(aiEnabled);
    return json;
  }

  UpdateTeamAiEnabledVariables({
    required this.teamId,
    required this.aiEnabled,
  });
}

