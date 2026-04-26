part of 'default.dart';

class CreateWorkflowVariablesBuilder {
  String id;
  String teamId;
  String name;
  AnyValue workflowConfig;
  AnyValue workflowSteps;
  bool isEditing;

  final FirebaseDataConnect _dataConnect;
  CreateWorkflowVariablesBuilder(this._dataConnect, {required  this.id,required  this.teamId,required  this.name,required  this.workflowConfig,required  this.workflowSteps,required  this.isEditing,});
  Deserializer<CreateWorkflowData> dataDeserializer = (dynamic json)  => CreateWorkflowData.fromJson(jsonDecode(json));
  Serializer<CreateWorkflowVariables> varsSerializer = (CreateWorkflowVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateWorkflowData, CreateWorkflowVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateWorkflowData, CreateWorkflowVariables> ref() {
    CreateWorkflowVariables vars= CreateWorkflowVariables(id: id,teamId: teamId,name: name,workflowConfig: workflowConfig,workflowSteps: workflowSteps,isEditing: isEditing,);
    return _dataConnect.mutation("CreateWorkflow", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateWorkflowWorkflowInsert {
  final String id;
  CreateWorkflowWorkflowInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateWorkflowWorkflowInsert otherTyped = other as CreateWorkflowWorkflowInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateWorkflowWorkflowInsert({
    required this.id,
  });
}

@immutable
class CreateWorkflowData {
  final CreateWorkflowWorkflowInsert workflow_insert;
  CreateWorkflowData.fromJson(dynamic json):
  
  workflow_insert = CreateWorkflowWorkflowInsert.fromJson(json['workflow_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateWorkflowData otherTyped = other as CreateWorkflowData;
    return workflow_insert == otherTyped.workflow_insert;
    
  }
  @override
  int get hashCode => workflow_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['workflow_insert'] = workflow_insert.toJson();
    return json;
  }

  CreateWorkflowData({
    required this.workflow_insert,
  });
}

@immutable
class CreateWorkflowVariables {
  final String id;
  final String teamId;
  final String name;
  final AnyValue workflowConfig;
  final AnyValue workflowSteps;
  final bool isEditing;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateWorkflowVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  teamId = nativeFromJson<String>(json['teamId']),
  name = nativeFromJson<String>(json['name']),
  workflowConfig = AnyValue.fromJson(json['workflowConfig']),
  workflowSteps = AnyValue.fromJson(json['workflowSteps']),
  isEditing = nativeFromJson<bool>(json['isEditing']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateWorkflowVariables otherTyped = other as CreateWorkflowVariables;
    return id == otherTyped.id && 
    teamId == otherTyped.teamId && 
    name == otherTyped.name && 
    workflowConfig == otherTyped.workflowConfig && 
    workflowSteps == otherTyped.workflowSteps && 
    isEditing == otherTyped.isEditing;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, teamId.hashCode, name.hashCode, workflowConfig.hashCode, workflowSteps.hashCode, isEditing.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['teamId'] = nativeToJson<String>(teamId);
    json['name'] = nativeToJson<String>(name);
    json['workflowConfig'] = workflowConfig.toJson();
    json['workflowSteps'] = workflowSteps.toJson();
    json['isEditing'] = nativeToJson<bool>(isEditing);
    return json;
  }

  CreateWorkflowVariables({
    required this.id,
    required this.teamId,
    required this.name,
    required this.workflowConfig,
    required this.workflowSteps,
    required this.isEditing,
  });
}

