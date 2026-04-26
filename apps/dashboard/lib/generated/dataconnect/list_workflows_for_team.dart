part of 'default.dart';

class ListWorkflowsForTeamVariablesBuilder {
  String teamId;

  final FirebaseDataConnect _dataConnect;
  ListWorkflowsForTeamVariablesBuilder(this._dataConnect, {required  this.teamId,});
  Deserializer<ListWorkflowsForTeamData> dataDeserializer = (dynamic json)  => ListWorkflowsForTeamData.fromJson(jsonDecode(json));
  Serializer<ListWorkflowsForTeamVariables> varsSerializer = (ListWorkflowsForTeamVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<ListWorkflowsForTeamData, ListWorkflowsForTeamVariables>> execute() {
    return ref().execute();
  }

  QueryRef<ListWorkflowsForTeamData, ListWorkflowsForTeamVariables> ref() {
    ListWorkflowsForTeamVariables vars= ListWorkflowsForTeamVariables(teamId: teamId,);
    return _dataConnect.query("ListWorkflowsForTeam", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class ListWorkflowsForTeamTeamMember {
  final String teamId;
  ListWorkflowsForTeamTeamMember.fromJson(dynamic json):
  
  teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListWorkflowsForTeamTeamMember otherTyped = other as ListWorkflowsForTeamTeamMember;
    return teamId == otherTyped.teamId;
    
  }
  @override
  int get hashCode => teamId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  ListWorkflowsForTeamTeamMember({
    required this.teamId,
  });
}

@immutable
class ListWorkflowsForTeamWorkflows {
  final String id;
  final String teamId;
  final String? name;
  final AnyValue? workflowConfig;
  final AnyValue? workflowSteps;
  final bool? isEditing;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  ListWorkflowsForTeamWorkflows.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  teamId = nativeFromJson<String>(json['teamId']),
  name = json['name'] == null ? null : nativeFromJson<String>(json['name']),
  workflowConfig = json['workflowConfig'] == null ? null : AnyValue.fromJson(json['workflowConfig']),
  workflowSteps = json['workflowSteps'] == null ? null : AnyValue.fromJson(json['workflowSteps']),
  isEditing = json['isEditing'] == null ? null : nativeFromJson<bool>(json['isEditing']),
  createdAt = Timestamp.fromJson(json['createdAt']),
  updatedAt = Timestamp.fromJson(json['updatedAt']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListWorkflowsForTeamWorkflows otherTyped = other as ListWorkflowsForTeamWorkflows;
    return id == otherTyped.id && 
    teamId == otherTyped.teamId && 
    name == otherTyped.name && 
    workflowConfig == otherTyped.workflowConfig && 
    workflowSteps == otherTyped.workflowSteps && 
    isEditing == otherTyped.isEditing && 
    createdAt == otherTyped.createdAt && 
    updatedAt == otherTyped.updatedAt;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, teamId.hashCode, name.hashCode, workflowConfig.hashCode, workflowSteps.hashCode, isEditing.hashCode, createdAt.hashCode, updatedAt.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['teamId'] = nativeToJson<String>(teamId);
    if (name != null) {
      json['name'] = nativeToJson<String?>(name);
    }
    if (workflowConfig != null) {
      json['workflowConfig'] = workflowConfig!.toJson();
    }
    if (workflowSteps != null) {
      json['workflowSteps'] = workflowSteps!.toJson();
    }
    if (isEditing != null) {
      json['isEditing'] = nativeToJson<bool?>(isEditing);
    }
    json['createdAt'] = createdAt.toJson();
    json['updatedAt'] = updatedAt.toJson();
    return json;
  }

  ListWorkflowsForTeamWorkflows({
    required this.id,
    required this.teamId,
    this.name,
    this.workflowConfig,
    this.workflowSteps,
    this.isEditing,
    required this.createdAt,
    required this.updatedAt,
  });
}

@immutable
class ListWorkflowsForTeamData {
  final ListWorkflowsForTeamTeamMember? teamMember;
  final List<ListWorkflowsForTeamWorkflows> workflows;
  ListWorkflowsForTeamData.fromJson(dynamic json):
  
  teamMember = json['teamMember'] == null ? null : ListWorkflowsForTeamTeamMember.fromJson(json['teamMember']),
  workflows = (json['workflows'] as List<dynamic>)
        .map((e) => ListWorkflowsForTeamWorkflows.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListWorkflowsForTeamData otherTyped = other as ListWorkflowsForTeamData;
    return teamMember == otherTyped.teamMember && 
    workflows == otherTyped.workflows;
    
  }
  @override
  int get hashCode => Object.hashAll([teamMember.hashCode, workflows.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (teamMember != null) {
      json['teamMember'] = teamMember!.toJson();
    }
    json['workflows'] = workflows.map((e) => e.toJson()).toList();
    return json;
  }

  ListWorkflowsForTeamData({
    this.teamMember,
    required this.workflows,
  });
}

@immutable
class ListWorkflowsForTeamVariables {
  final String teamId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ListWorkflowsForTeamVariables.fromJson(Map<String, dynamic> json):
  
  teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListWorkflowsForTeamVariables otherTyped = other as ListWorkflowsForTeamVariables;
    return teamId == otherTyped.teamId;
    
  }
  @override
  int get hashCode => teamId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  ListWorkflowsForTeamVariables({
    required this.teamId,
  });
}

