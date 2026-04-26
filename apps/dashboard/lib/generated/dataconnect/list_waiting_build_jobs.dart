part of 'default.dart';

class ListWaitingBuildJobsVariablesBuilder {
  String workflowRunId;

  final FirebaseDataConnect _dataConnect;
  ListWaitingBuildJobsVariablesBuilder(this._dataConnect, {required  this.workflowRunId,});
  Deserializer<ListWaitingBuildJobsData> dataDeserializer = (dynamic json)  => ListWaitingBuildJobsData.fromJson(jsonDecode(json));
  Serializer<ListWaitingBuildJobsVariables> varsSerializer = (ListWaitingBuildJobsVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<ListWaitingBuildJobsData, ListWaitingBuildJobsVariables>> execute() {
    return ref().execute();
  }

  QueryRef<ListWaitingBuildJobsData, ListWaitingBuildJobsVariables> ref() {
    ListWaitingBuildJobsVariables vars= ListWaitingBuildJobsVariables(workflowRunId: workflowRunId,);
    return _dataConnect.query("ListWaitingBuildJobs", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class ListWaitingBuildJobsBuildJobs {
  final String id;
  final String? jobKey;
  final List<String>? needs;
  final AnyValue? resolvedNeeds;
  ListWaitingBuildJobsBuildJobs.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  jobKey = json['jobKey'] == null ? null : nativeFromJson<String>(json['jobKey']),
  needs = json['needs'] == null ? null : (json['needs'] as List<dynamic>)
        .map((e) => nativeFromJson<String>(e))
        .toList(),
  resolvedNeeds = json['resolvedNeeds'] == null ? null : AnyValue.fromJson(json['resolvedNeeds']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListWaitingBuildJobsBuildJobs otherTyped = other as ListWaitingBuildJobsBuildJobs;
    return id == otherTyped.id && 
    jobKey == otherTyped.jobKey && 
    needs == otherTyped.needs && 
    resolvedNeeds == otherTyped.resolvedNeeds;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, jobKey.hashCode, needs.hashCode, resolvedNeeds.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    if (jobKey != null) {
      json['jobKey'] = nativeToJson<String?>(jobKey);
    }
    if (needs != null) {
      json['needs'] = needs?.map((e) => nativeToJson<String>(e)).toList();
    }
    if (resolvedNeeds != null) {
      json['resolvedNeeds'] = resolvedNeeds!.toJson();
    }
    return json;
  }

  ListWaitingBuildJobsBuildJobs({
    required this.id,
    this.jobKey,
    this.needs,
    this.resolvedNeeds,
  });
}

@immutable
class ListWaitingBuildJobsData {
  final List<ListWaitingBuildJobsBuildJobs> buildJobs;
  ListWaitingBuildJobsData.fromJson(dynamic json):
  
  buildJobs = (json['buildJobs'] as List<dynamic>)
        .map((e) => ListWaitingBuildJobsBuildJobs.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListWaitingBuildJobsData otherTyped = other as ListWaitingBuildJobsData;
    return buildJobs == otherTyped.buildJobs;
    
  }
  @override
  int get hashCode => buildJobs.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['buildJobs'] = buildJobs.map((e) => e.toJson()).toList();
    return json;
  }

  ListWaitingBuildJobsData({
    required this.buildJobs,
  });
}

@immutable
class ListWaitingBuildJobsVariables {
  final String workflowRunId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ListWaitingBuildJobsVariables.fromJson(Map<String, dynamic> json):
  
  workflowRunId = nativeFromJson<String>(json['workflowRunId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListWaitingBuildJobsVariables otherTyped = other as ListWaitingBuildJobsVariables;
    return workflowRunId == otherTyped.workflowRunId;
    
  }
  @override
  int get hashCode => workflowRunId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['workflowRunId'] = nativeToJson<String>(workflowRunId);
    return json;
  }

  ListWaitingBuildJobsVariables({
    required this.workflowRunId,
  });
}

