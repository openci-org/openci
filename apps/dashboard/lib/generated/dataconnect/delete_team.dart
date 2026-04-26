part of 'default.dart';

class DeleteTeamVariablesBuilder {
  String teamId;

  final FirebaseDataConnect _dataConnect;
  DeleteTeamVariablesBuilder(this._dataConnect, {required  this.teamId,});
  Deserializer<DeleteTeamData> dataDeserializer = (dynamic json)  => DeleteTeamData.fromJson(jsonDecode(json));
  Serializer<DeleteTeamVariables> varsSerializer = (DeleteTeamVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeleteTeamData, DeleteTeamVariables>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteTeamData, DeleteTeamVariables> ref() {
    DeleteTeamVariables vars= DeleteTeamVariables(teamId: teamId,);
    return _dataConnect.mutation("DeleteTeam", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class DeleteTeamTeamDelete {
  final String id;
  DeleteTeamTeamDelete.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteTeamTeamDelete otherTyped = other as DeleteTeamTeamDelete;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteTeamTeamDelete({
    required this.id,
  });
}

@immutable
class DeleteTeamData {
  final DeleteTeamTeamDelete? team_delete;
  DeleteTeamData.fromJson(dynamic json):
  
  team_delete = json['team_delete'] == null ? null : DeleteTeamTeamDelete.fromJson(json['team_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteTeamData otherTyped = other as DeleteTeamData;
    return team_delete == otherTyped.team_delete;
    
  }
  @override
  int get hashCode => team_delete.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (team_delete != null) {
      json['team_delete'] = team_delete!.toJson();
    }
    return json;
  }

  DeleteTeamData({
    this.team_delete,
  });
}

@immutable
class DeleteTeamVariables {
  final String teamId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  DeleteTeamVariables.fromJson(Map<String, dynamic> json):
  
  teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteTeamVariables otherTyped = other as DeleteTeamVariables;
    return teamId == otherTyped.teamId;
    
  }
  @override
  int get hashCode => teamId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  DeleteTeamVariables({
    required this.teamId,
  });
}

