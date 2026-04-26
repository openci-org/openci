part of 'default.dart';

class GetWorkflowVariablesBuilder {
  String id;
  String teamId;

  final FirebaseDataConnect _dataConnect;
  GetWorkflowVariablesBuilder(this._dataConnect, {required  this.id,required  this.teamId,});
  Deserializer<GetWorkflowData> dataDeserializer = (dynamic json)  => GetWorkflowData.fromJson(jsonDecode(json));
  Serializer<GetWorkflowVariables> varsSerializer = (GetWorkflowVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetWorkflowData, GetWorkflowVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetWorkflowData, GetWorkflowVariables> ref() {
    GetWorkflowVariables vars= GetWorkflowVariables(id: id,teamId: teamId,);
    return _dataConnect.query("GetWorkflow", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetWorkflowTeamMember {
  final String teamId;
  GetWorkflowTeamMember.fromJson(dynamic json):
  
  teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetWorkflowTeamMember otherTyped = other as GetWorkflowTeamMember;
    return teamId == otherTyped.teamId;
    
  }
  @override
  int get hashCode => teamId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  GetWorkflowTeamMember({
    required this.teamId,
  });
}

@immutable
class GetWorkflowWorkflow {
  final String id;
  final String teamId;
  final String? name;
  final AnyValue? workflowConfig;
  final AnyValue? workflowSteps;
  final bool? isEditing;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  GetWorkflowWorkflow.fromJson(dynamic json):
  
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

    final GetWorkflowWorkflow otherTyped = other as GetWorkflowWorkflow;
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

  GetWorkflowWorkflow({
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
class GetWorkflowData {
  final GetWorkflowTeamMember? teamMember;
  final GetWorkflowWorkflow? workflow;
  GetWorkflowData.fromJson(dynamic json):
  
  teamMember = json['teamMember'] == null ? null : GetWorkflowTeamMember.fromJson(json['teamMember']),
  workflow = json['workflow'] == null ? null : GetWorkflowWorkflow.fromJson(json['workflow']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetWorkflowData otherTyped = other as GetWorkflowData;
    return teamMember == otherTyped.teamMember && 
    workflow == otherTyped.workflow;
    
  }
  @override
  int get hashCode => Object.hashAll([teamMember.hashCode, workflow.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (teamMember != null) {
      json['teamMember'] = teamMember!.toJson();
    }
    if (workflow != null) {
      json['workflow'] = workflow!.toJson();
    }
    return json;
  }

  GetWorkflowData({
    this.teamMember,
    this.workflow,
  });
}

@immutable
class GetWorkflowVariables {
  final String id;
  final String teamId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetWorkflowVariables.fromJson(Map<String, dynamic> json):
  
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

    final GetWorkflowVariables otherTyped = other as GetWorkflowVariables;
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

  GetWorkflowVariables({
    required this.id,
    required this.teamId,
  });
}

