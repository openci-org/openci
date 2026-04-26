part of 'default.dart';

class UpdateWorkflowNameVariablesBuilder {
  String id;
  String teamId;
  String name;

  final FirebaseDataConnect _dataConnect;
  UpdateWorkflowNameVariablesBuilder(this._dataConnect, {required  this.id,required  this.teamId,required  this.name,});
  Deserializer<UpdateWorkflowNameData> dataDeserializer = (dynamic json)  => UpdateWorkflowNameData.fromJson(jsonDecode(json));
  Serializer<UpdateWorkflowNameVariables> varsSerializer = (UpdateWorkflowNameVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateWorkflowNameData, UpdateWorkflowNameVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateWorkflowNameData, UpdateWorkflowNameVariables> ref() {
    UpdateWorkflowNameVariables vars= UpdateWorkflowNameVariables(id: id,teamId: teamId,name: name,);
    return _dataConnect.mutation("UpdateWorkflowName", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateWorkflowNameWorkflowUpdate {
  final String id;
  UpdateWorkflowNameWorkflowUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateWorkflowNameWorkflowUpdate otherTyped = other as UpdateWorkflowNameWorkflowUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateWorkflowNameWorkflowUpdate({
    required this.id,
  });
}

@immutable
class UpdateWorkflowNameData {
  final UpdateWorkflowNameWorkflowUpdate? workflow_update;
  UpdateWorkflowNameData.fromJson(dynamic json):
  
  workflow_update = json['workflow_update'] == null ? null : UpdateWorkflowNameWorkflowUpdate.fromJson(json['workflow_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateWorkflowNameData otherTyped = other as UpdateWorkflowNameData;
    return workflow_update == otherTyped.workflow_update;
    
  }
  @override
  int get hashCode => workflow_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (workflow_update != null) {
      json['workflow_update'] = workflow_update!.toJson();
    }
    return json;
  }

  UpdateWorkflowNameData({
    this.workflow_update,
  });
}

@immutable
class UpdateWorkflowNameVariables {
  final String id;
  final String teamId;
  final String name;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateWorkflowNameVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
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

    final UpdateWorkflowNameVariables otherTyped = other as UpdateWorkflowNameVariables;
    return id == otherTyped.id && 
    teamId == otherTyped.teamId && 
    name == otherTyped.name;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, teamId.hashCode, name.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['teamId'] = nativeToJson<String>(teamId);
    json['name'] = nativeToJson<String>(name);
    return json;
  }

  UpdateWorkflowNameVariables({
    required this.id,
    required this.teamId,
    required this.name,
  });
}

