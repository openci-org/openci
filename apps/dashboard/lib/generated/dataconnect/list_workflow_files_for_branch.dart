part of 'default.dart';

class ListWorkflowFilesForBranchVariablesBuilder {
  String teamId;
  String repository;
  String branch;

  final FirebaseDataConnect _dataConnect;
  ListWorkflowFilesForBranchVariablesBuilder(this._dataConnect, {required  this.teamId,required  this.repository,required  this.branch,});
  Deserializer<ListWorkflowFilesForBranchData> dataDeserializer = (dynamic json)  => ListWorkflowFilesForBranchData.fromJson(jsonDecode(json));
  Serializer<ListWorkflowFilesForBranchVariables> varsSerializer = (ListWorkflowFilesForBranchVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<ListWorkflowFilesForBranchData, ListWorkflowFilesForBranchVariables>> execute() {
    return ref().execute();
  }

  QueryRef<ListWorkflowFilesForBranchData, ListWorkflowFilesForBranchVariables> ref() {
    ListWorkflowFilesForBranchVariables vars= ListWorkflowFilesForBranchVariables(teamId: teamId,repository: repository,branch: branch,);
    return _dataConnect.query("ListWorkflowFilesForBranch", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class ListWorkflowFilesForBranchTeamMember {
  final String teamId;
  ListWorkflowFilesForBranchTeamMember.fromJson(dynamic json):
  
  teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListWorkflowFilesForBranchTeamMember otherTyped = other as ListWorkflowFilesForBranchTeamMember;
    return teamId == otherTyped.teamId;
    
  }
  @override
  int get hashCode => teamId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  ListWorkflowFilesForBranchTeamMember({
    required this.teamId,
  });
}

@immutable
class ListWorkflowFilesForBranchWorkflowFiles {
  final String id;
  final String fileName;
  final String filePath;
  final String content;
  final bool? enabled;
  ListWorkflowFilesForBranchWorkflowFiles.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  fileName = nativeFromJson<String>(json['fileName']),
  filePath = nativeFromJson<String>(json['filePath']),
  content = nativeFromJson<String>(json['content']),
  enabled = json['enabled'] == null ? null : nativeFromJson<bool>(json['enabled']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListWorkflowFilesForBranchWorkflowFiles otherTyped = other as ListWorkflowFilesForBranchWorkflowFiles;
    return id == otherTyped.id && 
    fileName == otherTyped.fileName && 
    filePath == otherTyped.filePath && 
    content == otherTyped.content && 
    enabled == otherTyped.enabled;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, fileName.hashCode, filePath.hashCode, content.hashCode, enabled.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['fileName'] = nativeToJson<String>(fileName);
    json['filePath'] = nativeToJson<String>(filePath);
    json['content'] = nativeToJson<String>(content);
    if (enabled != null) {
      json['enabled'] = nativeToJson<bool?>(enabled);
    }
    return json;
  }

  ListWorkflowFilesForBranchWorkflowFiles({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.content,
    this.enabled,
  });
}

@immutable
class ListWorkflowFilesForBranchData {
  final ListWorkflowFilesForBranchTeamMember? teamMember;
  final List<ListWorkflowFilesForBranchWorkflowFiles> workflowFiles;
  ListWorkflowFilesForBranchData.fromJson(dynamic json):
  
  teamMember = json['teamMember'] == null ? null : ListWorkflowFilesForBranchTeamMember.fromJson(json['teamMember']),
  workflowFiles = (json['workflowFiles'] as List<dynamic>)
        .map((e) => ListWorkflowFilesForBranchWorkflowFiles.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListWorkflowFilesForBranchData otherTyped = other as ListWorkflowFilesForBranchData;
    return teamMember == otherTyped.teamMember && 
    workflowFiles == otherTyped.workflowFiles;
    
  }
  @override
  int get hashCode => Object.hashAll([teamMember.hashCode, workflowFiles.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (teamMember != null) {
      json['teamMember'] = teamMember!.toJson();
    }
    json['workflowFiles'] = workflowFiles.map((e) => e.toJson()).toList();
    return json;
  }

  ListWorkflowFilesForBranchData({
    this.teamMember,
    required this.workflowFiles,
  });
}

@immutable
class ListWorkflowFilesForBranchVariables {
  final String teamId;
  final String repository;
  final String branch;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ListWorkflowFilesForBranchVariables.fromJson(Map<String, dynamic> json):
  
  teamId = nativeFromJson<String>(json['teamId']),
  repository = nativeFromJson<String>(json['repository']),
  branch = nativeFromJson<String>(json['branch']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListWorkflowFilesForBranchVariables otherTyped = other as ListWorkflowFilesForBranchVariables;
    return teamId == otherTyped.teamId && 
    repository == otherTyped.repository && 
    branch == otherTyped.branch;
    
  }
  @override
  int get hashCode => Object.hashAll([teamId.hashCode, repository.hashCode, branch.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['repository'] = nativeToJson<String>(repository);
    json['branch'] = nativeToJson<String>(branch);
    return json;
  }

  ListWorkflowFilesForBranchVariables({
    required this.teamId,
    required this.repository,
    required this.branch,
  });
}

