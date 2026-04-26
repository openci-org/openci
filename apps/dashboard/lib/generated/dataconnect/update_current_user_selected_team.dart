part of 'default.dart';

class UpdateCurrentUserSelectedTeamVariablesBuilder {
  String teamId;

  final FirebaseDataConnect _dataConnect;
  UpdateCurrentUserSelectedTeamVariablesBuilder(this._dataConnect, {required  this.teamId,});
  Deserializer<UpdateCurrentUserSelectedTeamData> dataDeserializer = (dynamic json)  => UpdateCurrentUserSelectedTeamData.fromJson(jsonDecode(json));
  Serializer<UpdateCurrentUserSelectedTeamVariables> varsSerializer = (UpdateCurrentUserSelectedTeamVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateCurrentUserSelectedTeamData, UpdateCurrentUserSelectedTeamVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateCurrentUserSelectedTeamData, UpdateCurrentUserSelectedTeamVariables> ref() {
    UpdateCurrentUserSelectedTeamVariables vars= UpdateCurrentUserSelectedTeamVariables(teamId: teamId,);
    return _dataConnect.mutation("UpdateCurrentUserSelectedTeam", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateCurrentUserSelectedTeamUserUpdate {
  final String id;
  UpdateCurrentUserSelectedTeamUserUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateCurrentUserSelectedTeamUserUpdate otherTyped = other as UpdateCurrentUserSelectedTeamUserUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateCurrentUserSelectedTeamUserUpdate({
    required this.id,
  });
}

@immutable
class UpdateCurrentUserSelectedTeamData {
  final UpdateCurrentUserSelectedTeamUserUpdate? user_update;
  UpdateCurrentUserSelectedTeamData.fromJson(dynamic json):
  
  user_update = json['user_update'] == null ? null : UpdateCurrentUserSelectedTeamUserUpdate.fromJson(json['user_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateCurrentUserSelectedTeamData otherTyped = other as UpdateCurrentUserSelectedTeamData;
    return user_update == otherTyped.user_update;
    
  }
  @override
  int get hashCode => user_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (user_update != null) {
      json['user_update'] = user_update!.toJson();
    }
    return json;
  }

  UpdateCurrentUserSelectedTeamData({
    this.user_update,
  });
}

@immutable
class UpdateCurrentUserSelectedTeamVariables {
  final String teamId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateCurrentUserSelectedTeamVariables.fromJson(Map<String, dynamic> json):
  
  teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateCurrentUserSelectedTeamVariables otherTyped = other as UpdateCurrentUserSelectedTeamVariables;
    return teamId == otherTyped.teamId;
    
  }
  @override
  int get hashCode => teamId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  UpdateCurrentUserSelectedTeamVariables({
    required this.teamId,
  });
}

