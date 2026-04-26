part of 'default.dart';

class UpdateWorkflowSecretKeysVariablesBuilder {
  String id;
  AnyValue workflowSteps;

  final FirebaseDataConnect _dataConnect;
  UpdateWorkflowSecretKeysVariablesBuilder(this._dataConnect, {required  this.id,required  this.workflowSteps,});
  Deserializer<UpdateWorkflowSecretKeysData> dataDeserializer = (dynamic json)  => UpdateWorkflowSecretKeysData.fromJson(jsonDecode(json));
  Serializer<UpdateWorkflowSecretKeysVariables> varsSerializer = (UpdateWorkflowSecretKeysVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateWorkflowSecretKeysData, UpdateWorkflowSecretKeysVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateWorkflowSecretKeysData, UpdateWorkflowSecretKeysVariables> ref() {
    UpdateWorkflowSecretKeysVariables vars= UpdateWorkflowSecretKeysVariables(id: id,workflowSteps: workflowSteps,);
    return _dataConnect.mutation("UpdateWorkflowSecretKeys", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateWorkflowSecretKeysWorkflowUpdate {
  final String id;
  UpdateWorkflowSecretKeysWorkflowUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateWorkflowSecretKeysWorkflowUpdate otherTyped = other as UpdateWorkflowSecretKeysWorkflowUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateWorkflowSecretKeysWorkflowUpdate({
    required this.id,
  });
}

@immutable
class UpdateWorkflowSecretKeysData {
  final UpdateWorkflowSecretKeysWorkflowUpdate? workflow_update;
  UpdateWorkflowSecretKeysData.fromJson(dynamic json):
  
  workflow_update = json['workflow_update'] == null ? null : UpdateWorkflowSecretKeysWorkflowUpdate.fromJson(json['workflow_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateWorkflowSecretKeysData otherTyped = other as UpdateWorkflowSecretKeysData;
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

  UpdateWorkflowSecretKeysData({
    this.workflow_update,
  });
}

@immutable
class UpdateWorkflowSecretKeysVariables {
  final String id;
  final AnyValue workflowSteps;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateWorkflowSecretKeysVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  workflowSteps = AnyValue.fromJson(json['workflowSteps']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateWorkflowSecretKeysVariables otherTyped = other as UpdateWorkflowSecretKeysVariables;
    return id == otherTyped.id && 
    workflowSteps == otherTyped.workflowSteps;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, workflowSteps.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['workflowSteps'] = workflowSteps.toJson();
    return json;
  }

  UpdateWorkflowSecretKeysVariables({
    required this.id,
    required this.workflowSteps,
  });
}

