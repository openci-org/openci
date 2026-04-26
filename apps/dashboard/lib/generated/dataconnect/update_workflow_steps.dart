part of 'default.dart';

class UpdateWorkflowStepsVariablesBuilder {
  String id;
  String teamId;
  AnyValue workflowSteps;

  final FirebaseDataConnect _dataConnect;
  UpdateWorkflowStepsVariablesBuilder(this._dataConnect, {required  this.id,required  this.teamId,required  this.workflowSteps,});
  Deserializer<UpdateWorkflowStepsData> dataDeserializer = (dynamic json)  => UpdateWorkflowStepsData.fromJson(jsonDecode(json));
  Serializer<UpdateWorkflowStepsVariables> varsSerializer = (UpdateWorkflowStepsVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateWorkflowStepsData, UpdateWorkflowStepsVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateWorkflowStepsData, UpdateWorkflowStepsVariables> ref() {
    UpdateWorkflowStepsVariables vars= UpdateWorkflowStepsVariables(id: id,teamId: teamId,workflowSteps: workflowSteps,);
    return _dataConnect.mutation("UpdateWorkflowSteps", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateWorkflowStepsWorkflowUpdate {
  final String id;
  UpdateWorkflowStepsWorkflowUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateWorkflowStepsWorkflowUpdate otherTyped = other as UpdateWorkflowStepsWorkflowUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateWorkflowStepsWorkflowUpdate({
    required this.id,
  });
}

@immutable
class UpdateWorkflowStepsData {
  final UpdateWorkflowStepsWorkflowUpdate? workflow_update;
  UpdateWorkflowStepsData.fromJson(dynamic json):
  
  workflow_update = json['workflow_update'] == null ? null : UpdateWorkflowStepsWorkflowUpdate.fromJson(json['workflow_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateWorkflowStepsData otherTyped = other as UpdateWorkflowStepsData;
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

  UpdateWorkflowStepsData({
    this.workflow_update,
  });
}

@immutable
class UpdateWorkflowStepsVariables {
  final String id;
  final String teamId;
  final AnyValue workflowSteps;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateWorkflowStepsVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  teamId = nativeFromJson<String>(json['teamId']),
  workflowSteps = AnyValue.fromJson(json['workflowSteps']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateWorkflowStepsVariables otherTyped = other as UpdateWorkflowStepsVariables;
    return id == otherTyped.id && 
    teamId == otherTyped.teamId && 
    workflowSteps == otherTyped.workflowSteps;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, teamId.hashCode, workflowSteps.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['teamId'] = nativeToJson<String>(teamId);
    json['workflowSteps'] = workflowSteps.toJson();
    return json;
  }

  UpdateWorkflowStepsVariables({
    required this.id,
    required this.teamId,
    required this.workflowSteps,
  });
}

