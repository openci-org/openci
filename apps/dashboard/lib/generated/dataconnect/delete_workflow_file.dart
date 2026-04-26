part of 'default.dart';

class DeleteWorkflowFileVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  DeleteWorkflowFileVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<DeleteWorkflowFileData> dataDeserializer = (dynamic json)  => DeleteWorkflowFileData.fromJson(jsonDecode(json));
  Serializer<DeleteWorkflowFileVariables> varsSerializer = (DeleteWorkflowFileVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeleteWorkflowFileData, DeleteWorkflowFileVariables>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteWorkflowFileData, DeleteWorkflowFileVariables> ref() {
    DeleteWorkflowFileVariables vars= DeleteWorkflowFileVariables(id: id,);
    return _dataConnect.mutation("DeleteWorkflowFile", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class DeleteWorkflowFileWorkflowFileDelete {
  final String id;
  DeleteWorkflowFileWorkflowFileDelete.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteWorkflowFileWorkflowFileDelete otherTyped = other as DeleteWorkflowFileWorkflowFileDelete;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteWorkflowFileWorkflowFileDelete({
    required this.id,
  });
}

@immutable
class DeleteWorkflowFileData {
  final DeleteWorkflowFileWorkflowFileDelete? workflowFile_delete;
  DeleteWorkflowFileData.fromJson(dynamic json):
  
  workflowFile_delete = json['workflowFile_delete'] == null ? null : DeleteWorkflowFileWorkflowFileDelete.fromJson(json['workflowFile_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteWorkflowFileData otherTyped = other as DeleteWorkflowFileData;
    return workflowFile_delete == otherTyped.workflowFile_delete;
    
  }
  @override
  int get hashCode => workflowFile_delete.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (workflowFile_delete != null) {
      json['workflowFile_delete'] = workflowFile_delete!.toJson();
    }
    return json;
  }

  DeleteWorkflowFileData({
    this.workflowFile_delete,
  });
}

@immutable
class DeleteWorkflowFileVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  DeleteWorkflowFileVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteWorkflowFileVariables otherTyped = other as DeleteWorkflowFileVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteWorkflowFileVariables({
    required this.id,
  });
}

