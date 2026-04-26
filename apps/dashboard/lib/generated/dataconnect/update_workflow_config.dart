part of 'default.dart';

class UpdateWorkflowConfigVariablesBuilder {
  String id;
  String teamId;
  AnyValue workflowConfig;

  final FirebaseDataConnect _dataConnect;
  UpdateWorkflowConfigVariablesBuilder(this._dataConnect, {required  this.id,required  this.teamId,required  this.workflowConfig,});
  Deserializer<UpdateWorkflowConfigData> dataDeserializer = (dynamic json)  => UpdateWorkflowConfigData.fromJson(jsonDecode(json));
  Serializer<UpdateWorkflowConfigVariables> varsSerializer = (UpdateWorkflowConfigVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateWorkflowConfigData, UpdateWorkflowConfigVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateWorkflowConfigData, UpdateWorkflowConfigVariables> ref() {
    UpdateWorkflowConfigVariables vars= UpdateWorkflowConfigVariables(id: id,teamId: teamId,workflowConfig: workflowConfig,);
    return _dataConnect.mutation("UpdateWorkflowConfig", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateWorkflowConfigWorkflowUpdate {
  final String id;
  UpdateWorkflowConfigWorkflowUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateWorkflowConfigWorkflowUpdate otherTyped = other as UpdateWorkflowConfigWorkflowUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateWorkflowConfigWorkflowUpdate({
    required this.id,
  });
}

@immutable
class UpdateWorkflowConfigData {
  final UpdateWorkflowConfigWorkflowUpdate? workflow_update;
  UpdateWorkflowConfigData.fromJson(dynamic json):
  
  workflow_update = json['workflow_update'] == null ? null : UpdateWorkflowConfigWorkflowUpdate.fromJson(json['workflow_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateWorkflowConfigData otherTyped = other as UpdateWorkflowConfigData;
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

  UpdateWorkflowConfigData({
    this.workflow_update,
  });
}

@immutable
class UpdateWorkflowConfigVariables {
  final String id;
  final String teamId;
  final AnyValue workflowConfig;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateWorkflowConfigVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  teamId = nativeFromJson<String>(json['teamId']),
  workflowConfig = AnyValue.fromJson(json['workflowConfig']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateWorkflowConfigVariables otherTyped = other as UpdateWorkflowConfigVariables;
    return id == otherTyped.id && 
    teamId == otherTyped.teamId && 
    workflowConfig == otherTyped.workflowConfig;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, teamId.hashCode, workflowConfig.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['teamId'] = nativeToJson<String>(teamId);
    json['workflowConfig'] = workflowConfig.toJson();
    return json;
  }

  UpdateWorkflowConfigVariables({
    required this.id,
    required this.teamId,
    required this.workflowConfig,
  });
}

