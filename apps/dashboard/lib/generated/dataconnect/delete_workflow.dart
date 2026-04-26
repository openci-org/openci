part of 'default.dart';

class DeleteWorkflowVariablesBuilder {
  String id;
  String teamId;

  final FirebaseDataConnect _dataConnect;
  DeleteWorkflowVariablesBuilder(this._dataConnect, {required  this.id,required  this.teamId,});
  Deserializer<DeleteWorkflowData> dataDeserializer = (dynamic json)  => DeleteWorkflowData.fromJson(jsonDecode(json));
  Serializer<DeleteWorkflowVariables> varsSerializer = (DeleteWorkflowVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeleteWorkflowData, DeleteWorkflowVariables>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteWorkflowData, DeleteWorkflowVariables> ref() {
    DeleteWorkflowVariables vars= DeleteWorkflowVariables(id: id,teamId: teamId,);
    return _dataConnect.mutation("DeleteWorkflow", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class DeleteWorkflowWorkflowDelete {
  final String id;
  DeleteWorkflowWorkflowDelete.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteWorkflowWorkflowDelete otherTyped = other as DeleteWorkflowWorkflowDelete;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteWorkflowWorkflowDelete({
    required this.id,
  });
}

@immutable
class DeleteWorkflowData {
  final DeleteWorkflowWorkflowDelete? workflow_delete;
  DeleteWorkflowData.fromJson(dynamic json):
  
  workflow_delete = json['workflow_delete'] == null ? null : DeleteWorkflowWorkflowDelete.fromJson(json['workflow_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteWorkflowData otherTyped = other as DeleteWorkflowData;
    return workflow_delete == otherTyped.workflow_delete;
    
  }
  @override
  int get hashCode => workflow_delete.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (workflow_delete != null) {
      json['workflow_delete'] = workflow_delete!.toJson();
    }
    return json;
  }

  DeleteWorkflowData({
    this.workflow_delete,
  });
}

@immutable
class DeleteWorkflowVariables {
  final String id;
  final String teamId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  DeleteWorkflowVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteWorkflowVariables otherTyped = other as DeleteWorkflowVariables;
    return id == otherTyped.id && 
    teamId == otherTyped.teamId;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, teamId.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  DeleteWorkflowVariables({
    required this.id,
    required this.teamId,
  });
}

