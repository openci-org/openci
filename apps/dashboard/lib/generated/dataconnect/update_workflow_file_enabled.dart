part of 'default.dart';

class UpdateWorkflowFileEnabledVariablesBuilder {
  String id;
  String teamId;
  bool enabled;

  final FirebaseDataConnect _dataConnect;
  UpdateWorkflowFileEnabledVariablesBuilder(this._dataConnect, {required  this.id,required  this.teamId,required  this.enabled,});
  Deserializer<UpdateWorkflowFileEnabledData> dataDeserializer = (dynamic json)  => UpdateWorkflowFileEnabledData.fromJson(jsonDecode(json));
  Serializer<UpdateWorkflowFileEnabledVariables> varsSerializer = (UpdateWorkflowFileEnabledVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateWorkflowFileEnabledData, UpdateWorkflowFileEnabledVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateWorkflowFileEnabledData, UpdateWorkflowFileEnabledVariables> ref() {
    UpdateWorkflowFileEnabledVariables vars= UpdateWorkflowFileEnabledVariables(id: id,teamId: teamId,enabled: enabled,);
    return _dataConnect.mutation("UpdateWorkflowFileEnabled", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateWorkflowFileEnabledWorkflowFileUpdate {
  final String id;
  UpdateWorkflowFileEnabledWorkflowFileUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateWorkflowFileEnabledWorkflowFileUpdate otherTyped = other as UpdateWorkflowFileEnabledWorkflowFileUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateWorkflowFileEnabledWorkflowFileUpdate({
    required this.id,
  });
}

@immutable
class UpdateWorkflowFileEnabledData {
  final UpdateWorkflowFileEnabledWorkflowFileUpdate? workflowFile_update;
  UpdateWorkflowFileEnabledData.fromJson(dynamic json):
  
  workflowFile_update = json['workflowFile_update'] == null ? null : UpdateWorkflowFileEnabledWorkflowFileUpdate.fromJson(json['workflowFile_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateWorkflowFileEnabledData otherTyped = other as UpdateWorkflowFileEnabledData;
    return workflowFile_update == otherTyped.workflowFile_update;
    
  }
  @override
  int get hashCode => workflowFile_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (workflowFile_update != null) {
      json['workflowFile_update'] = workflowFile_update!.toJson();
    }
    return json;
  }

  UpdateWorkflowFileEnabledData({
    this.workflowFile_update,
  });
}

@immutable
class UpdateWorkflowFileEnabledVariables {
  final String id;
  final String teamId;
  final bool enabled;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateWorkflowFileEnabledVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  teamId = nativeFromJson<String>(json['teamId']),
  enabled = nativeFromJson<bool>(json['enabled']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateWorkflowFileEnabledVariables otherTyped = other as UpdateWorkflowFileEnabledVariables;
    return id == otherTyped.id && 
    teamId == otherTyped.teamId && 
    enabled == otherTyped.enabled;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, teamId.hashCode, enabled.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['teamId'] = nativeToJson<String>(teamId);
    json['enabled'] = nativeToJson<bool>(enabled);
    return json;
  }

  UpdateWorkflowFileEnabledVariables({
    required this.id,
    required this.teamId,
    required this.enabled,
  });
}

