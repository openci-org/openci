part of 'default.dart';

class GetWorkflowFileVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  GetWorkflowFileVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<GetWorkflowFileData> dataDeserializer = (dynamic json)  => GetWorkflowFileData.fromJson(jsonDecode(json));
  Serializer<GetWorkflowFileVariables> varsSerializer = (GetWorkflowFileVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetWorkflowFileData, GetWorkflowFileVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetWorkflowFileData, GetWorkflowFileVariables> ref() {
    GetWorkflowFileVariables vars= GetWorkflowFileVariables(id: id,);
    return _dataConnect.query("GetWorkflowFile", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetWorkflowFileWorkflowFile {
  final String id;
  final String teamId;
  final String repository;
  final String branch;
  final String fileName;
  final bool? enabled;
  GetWorkflowFileWorkflowFile.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  teamId = nativeFromJson<String>(json['teamId']),
  repository = nativeFromJson<String>(json['repository']),
  branch = nativeFromJson<String>(json['branch']),
  fileName = nativeFromJson<String>(json['fileName']),
  enabled = json['enabled'] == null ? null : nativeFromJson<bool>(json['enabled']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetWorkflowFileWorkflowFile otherTyped = other as GetWorkflowFileWorkflowFile;
    return id == otherTyped.id && 
    teamId == otherTyped.teamId && 
    repository == otherTyped.repository && 
    branch == otherTyped.branch && 
    fileName == otherTyped.fileName && 
    enabled == otherTyped.enabled;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, teamId.hashCode, repository.hashCode, branch.hashCode, fileName.hashCode, enabled.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['teamId'] = nativeToJson<String>(teamId);
    json['repository'] = nativeToJson<String>(repository);
    json['branch'] = nativeToJson<String>(branch);
    json['fileName'] = nativeToJson<String>(fileName);
    if (enabled != null) {
      json['enabled'] = nativeToJson<bool?>(enabled);
    }
    return json;
  }

  GetWorkflowFileWorkflowFile({
    required this.id,
    required this.teamId,
    required this.repository,
    required this.branch,
    required this.fileName,
    this.enabled,
  });
}

@immutable
class GetWorkflowFileData {
  final GetWorkflowFileWorkflowFile? workflowFile;
  GetWorkflowFileData.fromJson(dynamic json):
  
  workflowFile = json['workflowFile'] == null ? null : GetWorkflowFileWorkflowFile.fromJson(json['workflowFile']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetWorkflowFileData otherTyped = other as GetWorkflowFileData;
    return workflowFile == otherTyped.workflowFile;
    
  }
  @override
  int get hashCode => workflowFile.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (workflowFile != null) {
      json['workflowFile'] = workflowFile!.toJson();
    }
    return json;
  }

  GetWorkflowFileData({
    this.workflowFile,
  });
}

@immutable
class GetWorkflowFileVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetWorkflowFileVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetWorkflowFileVariables otherTyped = other as GetWorkflowFileVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetWorkflowFileVariables({
    required this.id,
  });
}

