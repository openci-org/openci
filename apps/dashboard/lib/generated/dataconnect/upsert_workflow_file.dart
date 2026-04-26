part of 'default.dart';

class UpsertWorkflowFileVariablesBuilder {
  String id;
  String teamId;
  String repository;
  String branch;
  String fileName;
  String filePath;
  String content;
  Optional<bool> _enabled = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  UpsertWorkflowFileVariablesBuilder enabled(bool? t) {
   _enabled.value = t;
   return this;
  }

  UpsertWorkflowFileVariablesBuilder(this._dataConnect, {required  this.id,required  this.teamId,required  this.repository,required  this.branch,required  this.fileName,required  this.filePath,required  this.content,});
  Deserializer<UpsertWorkflowFileData> dataDeserializer = (dynamic json)  => UpsertWorkflowFileData.fromJson(jsonDecode(json));
  Serializer<UpsertWorkflowFileVariables> varsSerializer = (UpsertWorkflowFileVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpsertWorkflowFileData, UpsertWorkflowFileVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpsertWorkflowFileData, UpsertWorkflowFileVariables> ref() {
    UpsertWorkflowFileVariables vars= UpsertWorkflowFileVariables(id: id,teamId: teamId,repository: repository,branch: branch,fileName: fileName,filePath: filePath,content: content,enabled: _enabled,);
    return _dataConnect.mutation("UpsertWorkflowFile", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpsertWorkflowFileWorkflowFileUpsert {
  final String id;
  UpsertWorkflowFileWorkflowFileUpsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertWorkflowFileWorkflowFileUpsert otherTyped = other as UpsertWorkflowFileWorkflowFileUpsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpsertWorkflowFileWorkflowFileUpsert({
    required this.id,
  });
}

@immutable
class UpsertWorkflowFileData {
  final UpsertWorkflowFileWorkflowFileUpsert workflowFile_upsert;
  UpsertWorkflowFileData.fromJson(dynamic json):
  
  workflowFile_upsert = UpsertWorkflowFileWorkflowFileUpsert.fromJson(json['workflowFile_upsert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertWorkflowFileData otherTyped = other as UpsertWorkflowFileData;
    return workflowFile_upsert == otherTyped.workflowFile_upsert;
    
  }
  @override
  int get hashCode => workflowFile_upsert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['workflowFile_upsert'] = workflowFile_upsert.toJson();
    return json;
  }

  UpsertWorkflowFileData({
    required this.workflowFile_upsert,
  });
}

@immutable
class UpsertWorkflowFileVariables {
  final String id;
  final String teamId;
  final String repository;
  final String branch;
  final String fileName;
  final String filePath;
  final String content;
  late final Optional<bool>enabled;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpsertWorkflowFileVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  teamId = nativeFromJson<String>(json['teamId']),
  repository = nativeFromJson<String>(json['repository']),
  branch = nativeFromJson<String>(json['branch']),
  fileName = nativeFromJson<String>(json['fileName']),
  filePath = nativeFromJson<String>(json['filePath']),
  content = nativeFromJson<String>(json['content']) {
  
  
  
  
  
  
  
  
  
    enabled = Optional.optional(nativeFromJson, nativeToJson);
    enabled.value = json['enabled'] == null ? null : nativeFromJson<bool>(json['enabled']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertWorkflowFileVariables otherTyped = other as UpsertWorkflowFileVariables;
    return id == otherTyped.id && 
    teamId == otherTyped.teamId && 
    repository == otherTyped.repository && 
    branch == otherTyped.branch && 
    fileName == otherTyped.fileName && 
    filePath == otherTyped.filePath && 
    content == otherTyped.content && 
    enabled == otherTyped.enabled;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, teamId.hashCode, repository.hashCode, branch.hashCode, fileName.hashCode, filePath.hashCode, content.hashCode, enabled.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['teamId'] = nativeToJson<String>(teamId);
    json['repository'] = nativeToJson<String>(repository);
    json['branch'] = nativeToJson<String>(branch);
    json['fileName'] = nativeToJson<String>(fileName);
    json['filePath'] = nativeToJson<String>(filePath);
    json['content'] = nativeToJson<String>(content);
    if(enabled.state == OptionalState.set) {
      json['enabled'] = enabled.toJson();
    }
    return json;
  }

  UpsertWorkflowFileVariables({
    required this.id,
    required this.teamId,
    required this.repository,
    required this.branch,
    required this.fileName,
    required this.filePath,
    required this.content,
    required this.enabled,
  });
}

