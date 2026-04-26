part of 'default.dart';

class ListBuildJobsForTeamVariablesBuilder {
  String teamId;
  int limit;

  final FirebaseDataConnect _dataConnect;
  ListBuildJobsForTeamVariablesBuilder(this._dataConnect, {required  this.teamId,required  this.limit,});
  Deserializer<ListBuildJobsForTeamData> dataDeserializer = (dynamic json)  => ListBuildJobsForTeamData.fromJson(jsonDecode(json));
  Serializer<ListBuildJobsForTeamVariables> varsSerializer = (ListBuildJobsForTeamVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<ListBuildJobsForTeamData, ListBuildJobsForTeamVariables>> execute() {
    return ref().execute();
  }

  QueryRef<ListBuildJobsForTeamData, ListBuildJobsForTeamVariables> ref() {
    ListBuildJobsForTeamVariables vars= ListBuildJobsForTeamVariables(teamId: teamId,limit: limit,);
    return _dataConnect.query("ListBuildJobsForTeam", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class ListBuildJobsForTeamTeamMember {
  final String teamId;
  ListBuildJobsForTeamTeamMember.fromJson(dynamic json):
  
  teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListBuildJobsForTeamTeamMember otherTyped = other as ListBuildJobsForTeamTeamMember;
    return teamId == otherTyped.teamId;
    
  }
  @override
  int get hashCode => teamId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  ListBuildJobsForTeamTeamMember({
    required this.teamId,
  });
}

@immutable
class ListBuildJobsForTeamBuildJobs {
  final String id;
  final String status;
  final String owner;
  final String repo;
  final String? teamId;
  final String? workflowId;
  final String? workflowFileName;
  final String? workflowName;
  final String? jobKey;
  final String? workflowRunId;
  final List<String>? needs;
  final String? commitSha;
  final int? pullRequestNumber;
  final String? tagName;
  final String? branch;
  final int? runCount;
  final String? latestRunId;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final Timestamp? completedAt;
  final String? failureSummaryStatus;
  final String? failureSummary;
  final String? failureSummaryModel;
  final int? failureSummaryDurationMs;
  ListBuildJobsForTeamBuildJobs.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  status = nativeFromJson<String>(json['status']),
  owner = nativeFromJson<String>(json['owner']),
  repo = nativeFromJson<String>(json['repo']),
  teamId = json['teamId'] == null ? null : nativeFromJson<String>(json['teamId']),
  workflowId = json['workflowId'] == null ? null : nativeFromJson<String>(json['workflowId']),
  workflowFileName = json['workflowFileName'] == null ? null : nativeFromJson<String>(json['workflowFileName']),
  workflowName = json['workflowName'] == null ? null : nativeFromJson<String>(json['workflowName']),
  jobKey = json['jobKey'] == null ? null : nativeFromJson<String>(json['jobKey']),
  workflowRunId = json['workflowRunId'] == null ? null : nativeFromJson<String>(json['workflowRunId']),
  needs = json['needs'] == null ? null : (json['needs'] as List<dynamic>)
        .map((e) => nativeFromJson<String>(e))
        .toList(),
  commitSha = json['commitSha'] == null ? null : nativeFromJson<String>(json['commitSha']),
  pullRequestNumber = json['pullRequestNumber'] == null ? null : nativeFromJson<int>(json['pullRequestNumber']),
  tagName = json['tagName'] == null ? null : nativeFromJson<String>(json['tagName']),
  branch = json['branch'] == null ? null : nativeFromJson<String>(json['branch']),
  runCount = json['runCount'] == null ? null : nativeFromJson<int>(json['runCount']),
  latestRunId = json['latestRunId'] == null ? null : nativeFromJson<String>(json['latestRunId']),
  createdAt = Timestamp.fromJson(json['createdAt']),
  updatedAt = Timestamp.fromJson(json['updatedAt']),
  completedAt = json['completedAt'] == null ? null : Timestamp.fromJson(json['completedAt']),
  failureSummaryStatus = json['failureSummaryStatus'] == null ? null : nativeFromJson<String>(json['failureSummaryStatus']),
  failureSummary = json['failureSummary'] == null ? null : nativeFromJson<String>(json['failureSummary']),
  failureSummaryModel = json['failureSummaryModel'] == null ? null : nativeFromJson<String>(json['failureSummaryModel']),
  failureSummaryDurationMs = json['failureSummaryDurationMs'] == null ? null : nativeFromJson<int>(json['failureSummaryDurationMs']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListBuildJobsForTeamBuildJobs otherTyped = other as ListBuildJobsForTeamBuildJobs;
    return id == otherTyped.id && 
    status == otherTyped.status && 
    owner == otherTyped.owner && 
    repo == otherTyped.repo && 
    teamId == otherTyped.teamId && 
    workflowId == otherTyped.workflowId && 
    workflowFileName == otherTyped.workflowFileName && 
    workflowName == otherTyped.workflowName && 
    jobKey == otherTyped.jobKey && 
    workflowRunId == otherTyped.workflowRunId && 
    needs == otherTyped.needs && 
    commitSha == otherTyped.commitSha && 
    pullRequestNumber == otherTyped.pullRequestNumber && 
    tagName == otherTyped.tagName && 
    branch == otherTyped.branch && 
    runCount == otherTyped.runCount && 
    latestRunId == otherTyped.latestRunId && 
    createdAt == otherTyped.createdAt && 
    updatedAt == otherTyped.updatedAt && 
    completedAt == otherTyped.completedAt && 
    failureSummaryStatus == otherTyped.failureSummaryStatus && 
    failureSummary == otherTyped.failureSummary && 
    failureSummaryModel == otherTyped.failureSummaryModel && 
    failureSummaryDurationMs == otherTyped.failureSummaryDurationMs;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, status.hashCode, owner.hashCode, repo.hashCode, teamId.hashCode, workflowId.hashCode, workflowFileName.hashCode, workflowName.hashCode, jobKey.hashCode, workflowRunId.hashCode, needs.hashCode, commitSha.hashCode, pullRequestNumber.hashCode, tagName.hashCode, branch.hashCode, runCount.hashCode, latestRunId.hashCode, createdAt.hashCode, updatedAt.hashCode, completedAt.hashCode, failureSummaryStatus.hashCode, failureSummary.hashCode, failureSummaryModel.hashCode, failureSummaryDurationMs.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['status'] = nativeToJson<String>(status);
    json['owner'] = nativeToJson<String>(owner);
    json['repo'] = nativeToJson<String>(repo);
    if (teamId != null) {
      json['teamId'] = nativeToJson<String?>(teamId);
    }
    if (workflowId != null) {
      json['workflowId'] = nativeToJson<String?>(workflowId);
    }
    if (workflowFileName != null) {
      json['workflowFileName'] = nativeToJson<String?>(workflowFileName);
    }
    if (workflowName != null) {
      json['workflowName'] = nativeToJson<String?>(workflowName);
    }
    if (jobKey != null) {
      json['jobKey'] = nativeToJson<String?>(jobKey);
    }
    if (workflowRunId != null) {
      json['workflowRunId'] = nativeToJson<String?>(workflowRunId);
    }
    if (needs != null) {
      json['needs'] = needs?.map((e) => nativeToJson<String>(e)).toList();
    }
    if (commitSha != null) {
      json['commitSha'] = nativeToJson<String?>(commitSha);
    }
    if (pullRequestNumber != null) {
      json['pullRequestNumber'] = nativeToJson<int?>(pullRequestNumber);
    }
    if (tagName != null) {
      json['tagName'] = nativeToJson<String?>(tagName);
    }
    if (branch != null) {
      json['branch'] = nativeToJson<String?>(branch);
    }
    if (runCount != null) {
      json['runCount'] = nativeToJson<int?>(runCount);
    }
    if (latestRunId != null) {
      json['latestRunId'] = nativeToJson<String?>(latestRunId);
    }
    json['createdAt'] = createdAt.toJson();
    json['updatedAt'] = updatedAt.toJson();
    if (completedAt != null) {
      json['completedAt'] = completedAt!.toJson();
    }
    if (failureSummaryStatus != null) {
      json['failureSummaryStatus'] = nativeToJson<String?>(failureSummaryStatus);
    }
    if (failureSummary != null) {
      json['failureSummary'] = nativeToJson<String?>(failureSummary);
    }
    if (failureSummaryModel != null) {
      json['failureSummaryModel'] = nativeToJson<String?>(failureSummaryModel);
    }
    if (failureSummaryDurationMs != null) {
      json['failureSummaryDurationMs'] = nativeToJson<int?>(failureSummaryDurationMs);
    }
    return json;
  }

  ListBuildJobsForTeamBuildJobs({
    required this.id,
    required this.status,
    required this.owner,
    required this.repo,
    this.teamId,
    this.workflowId,
    this.workflowFileName,
    this.workflowName,
    this.jobKey,
    this.workflowRunId,
    this.needs,
    this.commitSha,
    this.pullRequestNumber,
    this.tagName,
    this.branch,
    this.runCount,
    this.latestRunId,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.failureSummaryStatus,
    this.failureSummary,
    this.failureSummaryModel,
    this.failureSummaryDurationMs,
  });
}

@immutable
class ListBuildJobsForTeamData {
  final ListBuildJobsForTeamTeamMember? teamMember;
  final List<ListBuildJobsForTeamBuildJobs> buildJobs;
  ListBuildJobsForTeamData.fromJson(dynamic json):
  
  teamMember = json['teamMember'] == null ? null : ListBuildJobsForTeamTeamMember.fromJson(json['teamMember']),
  buildJobs = (json['buildJobs'] as List<dynamic>)
        .map((e) => ListBuildJobsForTeamBuildJobs.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListBuildJobsForTeamData otherTyped = other as ListBuildJobsForTeamData;
    return teamMember == otherTyped.teamMember && 
    buildJobs == otherTyped.buildJobs;
    
  }
  @override
  int get hashCode => Object.hashAll([teamMember.hashCode, buildJobs.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (teamMember != null) {
      json['teamMember'] = teamMember!.toJson();
    }
    json['buildJobs'] = buildJobs.map((e) => e.toJson()).toList();
    return json;
  }

  ListBuildJobsForTeamData({
    this.teamMember,
    required this.buildJobs,
  });
}

@immutable
class ListBuildJobsForTeamVariables {
  final String teamId;
  final int limit;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ListBuildJobsForTeamVariables.fromJson(Map<String, dynamic> json):
  
  teamId = nativeFromJson<String>(json['teamId']),
  limit = nativeFromJson<int>(json['limit']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListBuildJobsForTeamVariables otherTyped = other as ListBuildJobsForTeamVariables;
    return teamId == otherTyped.teamId && 
    limit == otherTyped.limit;
    
  }
  @override
  int get hashCode => Object.hashAll([teamId.hashCode, limit.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['limit'] = nativeToJson<int>(limit);
    return json;
  }

  ListBuildJobsForTeamVariables({
    required this.teamId,
    required this.limit,
  });
}

