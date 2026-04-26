part of 'default.dart';

class ListLatestBuildLogsVariablesBuilder {
  String buildJobId;
  String runId;
  int limit;

  final FirebaseDataConnect _dataConnect;
  ListLatestBuildLogsVariablesBuilder(this._dataConnect, {required  this.buildJobId,required  this.runId,required  this.limit,});
  Deserializer<ListLatestBuildLogsData> dataDeserializer = (dynamic json)  => ListLatestBuildLogsData.fromJson(jsonDecode(json));
  Serializer<ListLatestBuildLogsVariables> varsSerializer = (ListLatestBuildLogsVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<ListLatestBuildLogsData, ListLatestBuildLogsVariables>> execute() {
    return ref().execute();
  }

  QueryRef<ListLatestBuildLogsData, ListLatestBuildLogsVariables> ref() {
    ListLatestBuildLogsVariables vars= ListLatestBuildLogsVariables(buildJobId: buildJobId,runId: runId,limit: limit,);
    return _dataConnect.query("ListLatestBuildLogs", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class ListLatestBuildLogsBuildLogs {
  final String id;
  final String message;
  final Timestamp timestamp;
  ListLatestBuildLogsBuildLogs.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  message = nativeFromJson<String>(json['message']),
  timestamp = Timestamp.fromJson(json['timestamp']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListLatestBuildLogsBuildLogs otherTyped = other as ListLatestBuildLogsBuildLogs;
    return id == otherTyped.id && 
    message == otherTyped.message && 
    timestamp == otherTyped.timestamp;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, message.hashCode, timestamp.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['message'] = nativeToJson<String>(message);
    json['timestamp'] = timestamp.toJson();
    return json;
  }

  ListLatestBuildLogsBuildLogs({
    required this.id,
    required this.message,
    required this.timestamp,
  });
}

@immutable
class ListLatestBuildLogsData {
  final List<ListLatestBuildLogsBuildLogs> buildLogs;
  ListLatestBuildLogsData.fromJson(dynamic json):
  
  buildLogs = (json['buildLogs'] as List<dynamic>)
        .map((e) => ListLatestBuildLogsBuildLogs.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListLatestBuildLogsData otherTyped = other as ListLatestBuildLogsData;
    return buildLogs == otherTyped.buildLogs;
    
  }
  @override
  int get hashCode => buildLogs.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['buildLogs'] = buildLogs.map((e) => e.toJson()).toList();
    return json;
  }

  ListLatestBuildLogsData({
    required this.buildLogs,
  });
}

@immutable
class ListLatestBuildLogsVariables {
  final String buildJobId;
  final String runId;
  final int limit;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ListLatestBuildLogsVariables.fromJson(Map<String, dynamic> json):
  
  buildJobId = nativeFromJson<String>(json['buildJobId']),
  runId = nativeFromJson<String>(json['runId']),
  limit = nativeFromJson<int>(json['limit']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListLatestBuildLogsVariables otherTyped = other as ListLatestBuildLogsVariables;
    return buildJobId == otherTyped.buildJobId && 
    runId == otherTyped.runId && 
    limit == otherTyped.limit;
    
  }
  @override
  int get hashCode => Object.hashAll([buildJobId.hashCode, runId.hashCode, limit.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['buildJobId'] = nativeToJson<String>(buildJobId);
    json['runId'] = nativeToJson<String>(runId);
    json['limit'] = nativeToJson<int>(limit);
    return json;
  }

  ListLatestBuildLogsVariables({
    required this.buildJobId,
    required this.runId,
    required this.limit,
  });
}

