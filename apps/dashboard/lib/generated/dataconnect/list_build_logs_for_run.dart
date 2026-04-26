part of 'default.dart';

class ListBuildLogsForRunVariablesBuilder {
  String buildJobId;
  String runId;
  String teamId;

  final FirebaseDataConnect _dataConnect;
  ListBuildLogsForRunVariablesBuilder(this._dataConnect, {required  this.buildJobId,required  this.runId,required  this.teamId,});
  Deserializer<ListBuildLogsForRunData> dataDeserializer = (dynamic json)  => ListBuildLogsForRunData.fromJson(jsonDecode(json));
  Serializer<ListBuildLogsForRunVariables> varsSerializer = (ListBuildLogsForRunVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<ListBuildLogsForRunData, ListBuildLogsForRunVariables>> execute() {
    return ref().execute();
  }

  QueryRef<ListBuildLogsForRunData, ListBuildLogsForRunVariables> ref() {
    ListBuildLogsForRunVariables vars= ListBuildLogsForRunVariables(buildJobId: buildJobId,runId: runId,teamId: teamId,);
    return _dataConnect.query("ListBuildLogsForRun", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class ListBuildLogsForRunTeamMember {
  final String teamId;
  ListBuildLogsForRunTeamMember.fromJson(dynamic json):
  
  teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListBuildLogsForRunTeamMember otherTyped = other as ListBuildLogsForRunTeamMember;
    return teamId == otherTyped.teamId;
    
  }
  @override
  int get hashCode => teamId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  ListBuildLogsForRunTeamMember({
    required this.teamId,
  });
}

@immutable
class ListBuildLogsForRunBuildLogs {
  final String id;
  final String message;
  final String? level;
  final Timestamp timestamp;
  ListBuildLogsForRunBuildLogs.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  message = nativeFromJson<String>(json['message']),
  level = json['level'] == null ? null : nativeFromJson<String>(json['level']),
  timestamp = Timestamp.fromJson(json['timestamp']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListBuildLogsForRunBuildLogs otherTyped = other as ListBuildLogsForRunBuildLogs;
    return id == otherTyped.id && 
    message == otherTyped.message && 
    level == otherTyped.level && 
    timestamp == otherTyped.timestamp;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, message.hashCode, level.hashCode, timestamp.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['message'] = nativeToJson<String>(message);
    if (level != null) {
      json['level'] = nativeToJson<String?>(level);
    }
    json['timestamp'] = timestamp.toJson();
    return json;
  }

  ListBuildLogsForRunBuildLogs({
    required this.id,
    required this.message,
    this.level,
    required this.timestamp,
  });
}

@immutable
class ListBuildLogsForRunData {
  final ListBuildLogsForRunTeamMember? teamMember;
  final List<ListBuildLogsForRunBuildLogs> buildLogs;
  ListBuildLogsForRunData.fromJson(dynamic json):
  
  teamMember = json['teamMember'] == null ? null : ListBuildLogsForRunTeamMember.fromJson(json['teamMember']),
  buildLogs = (json['buildLogs'] as List<dynamic>)
        .map((e) => ListBuildLogsForRunBuildLogs.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListBuildLogsForRunData otherTyped = other as ListBuildLogsForRunData;
    return teamMember == otherTyped.teamMember && 
    buildLogs == otherTyped.buildLogs;
    
  }
  @override
  int get hashCode => Object.hashAll([teamMember.hashCode, buildLogs.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (teamMember != null) {
      json['teamMember'] = teamMember!.toJson();
    }
    json['buildLogs'] = buildLogs.map((e) => e.toJson()).toList();
    return json;
  }

  ListBuildLogsForRunData({
    this.teamMember,
    required this.buildLogs,
  });
}

@immutable
class ListBuildLogsForRunVariables {
  final String buildJobId;
  final String runId;
  final String teamId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ListBuildLogsForRunVariables.fromJson(Map<String, dynamic> json):
  
  buildJobId = nativeFromJson<String>(json['buildJobId']),
  runId = nativeFromJson<String>(json['runId']),
  teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListBuildLogsForRunVariables otherTyped = other as ListBuildLogsForRunVariables;
    return buildJobId == otherTyped.buildJobId && 
    runId == otherTyped.runId && 
    teamId == otherTyped.teamId;
    
  }
  @override
  int get hashCode => Object.hashAll([buildJobId.hashCode, runId.hashCode, teamId.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['buildJobId'] = nativeToJson<String>(buildJobId);
    json['runId'] = nativeToJson<String>(runId);
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  ListBuildLogsForRunVariables({
    required this.buildJobId,
    required this.runId,
    required this.teamId,
  });
}

