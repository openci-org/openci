part of 'default.dart';

class AppendBuildLogForWorkerVariablesBuilder {
  String buildJobId;
  String runId;
  String id;
  String message;
  String level;
  Timestamp timestamp;
  Optional<String> _stackTrace = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  AppendBuildLogForWorkerVariablesBuilder stackTrace(String? t) {
   _stackTrace.value = t;
   return this;
  }

  AppendBuildLogForWorkerVariablesBuilder(this._dataConnect, {required  this.buildJobId,required  this.runId,required  this.id,required  this.message,required  this.level,required  this.timestamp,});
  Deserializer<AppendBuildLogForWorkerData> dataDeserializer = (dynamic json)  => AppendBuildLogForWorkerData.fromJson(jsonDecode(json));
  Serializer<AppendBuildLogForWorkerVariables> varsSerializer = (AppendBuildLogForWorkerVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<AppendBuildLogForWorkerData, AppendBuildLogForWorkerVariables>> execute() {
    return ref().execute();
  }

  MutationRef<AppendBuildLogForWorkerData, AppendBuildLogForWorkerVariables> ref() {
    AppendBuildLogForWorkerVariables vars= AppendBuildLogForWorkerVariables(buildJobId: buildJobId,runId: runId,id: id,message: message,level: level,timestamp: timestamp,stackTrace: _stackTrace,);
    return _dataConnect.mutation("AppendBuildLogForWorker", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class AppendBuildLogForWorkerBuildLogUpsert {
  final String buildRunBuildJobId;
  final String buildRunId;
  final String id;
  AppendBuildLogForWorkerBuildLogUpsert.fromJson(dynamic json):
  
  buildRunBuildJobId = nativeFromJson<String>(json['buildRunBuildJobId']),
  buildRunId = nativeFromJson<String>(json['buildRunId']),
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final AppendBuildLogForWorkerBuildLogUpsert otherTyped = other as AppendBuildLogForWorkerBuildLogUpsert;
    return buildRunBuildJobId == otherTyped.buildRunBuildJobId && 
    buildRunId == otherTyped.buildRunId && 
    id == otherTyped.id;
    
  }
  @override
  int get hashCode => Object.hashAll([buildRunBuildJobId.hashCode, buildRunId.hashCode, id.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['buildRunBuildJobId'] = nativeToJson<String>(buildRunBuildJobId);
    json['buildRunId'] = nativeToJson<String>(buildRunId);
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  AppendBuildLogForWorkerBuildLogUpsert({
    required this.buildRunBuildJobId,
    required this.buildRunId,
    required this.id,
  });
}

@immutable
class AppendBuildLogForWorkerData {
  final AppendBuildLogForWorkerBuildLogUpsert buildLog_upsert;
  AppendBuildLogForWorkerData.fromJson(dynamic json):
  
  buildLog_upsert = AppendBuildLogForWorkerBuildLogUpsert.fromJson(json['buildLog_upsert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final AppendBuildLogForWorkerData otherTyped = other as AppendBuildLogForWorkerData;
    return buildLog_upsert == otherTyped.buildLog_upsert;
    
  }
  @override
  int get hashCode => buildLog_upsert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['buildLog_upsert'] = buildLog_upsert.toJson();
    return json;
  }

  AppendBuildLogForWorkerData({
    required this.buildLog_upsert,
  });
}

@immutable
class AppendBuildLogForWorkerVariables {
  final String buildJobId;
  final String runId;
  final String id;
  final String message;
  final String level;
  final Timestamp timestamp;
  late final Optional<String>stackTrace;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  AppendBuildLogForWorkerVariables.fromJson(Map<String, dynamic> json):
  
  buildJobId = nativeFromJson<String>(json['buildJobId']),
  runId = nativeFromJson<String>(json['runId']),
  id = nativeFromJson<String>(json['id']),
  message = nativeFromJson<String>(json['message']),
  level = nativeFromJson<String>(json['level']),
  timestamp = Timestamp.fromJson(json['timestamp']) {
  
  
  
  
  
  
  
  
    stackTrace = Optional.optional(nativeFromJson, nativeToJson);
    stackTrace.value = json['stackTrace'] == null ? null : nativeFromJson<String>(json['stackTrace']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final AppendBuildLogForWorkerVariables otherTyped = other as AppendBuildLogForWorkerVariables;
    return buildJobId == otherTyped.buildJobId && 
    runId == otherTyped.runId && 
    id == otherTyped.id && 
    message == otherTyped.message && 
    level == otherTyped.level && 
    timestamp == otherTyped.timestamp && 
    stackTrace == otherTyped.stackTrace;
    
  }
  @override
  int get hashCode => Object.hashAll([buildJobId.hashCode, runId.hashCode, id.hashCode, message.hashCode, level.hashCode, timestamp.hashCode, stackTrace.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['buildJobId'] = nativeToJson<String>(buildJobId);
    json['runId'] = nativeToJson<String>(runId);
    json['id'] = nativeToJson<String>(id);
    json['message'] = nativeToJson<String>(message);
    json['level'] = nativeToJson<String>(level);
    json['timestamp'] = timestamp.toJson();
    if(stackTrace.state == OptionalState.set) {
      json['stackTrace'] = stackTrace.toJson();
    }
    return json;
  }

  AppendBuildLogForWorkerVariables({
    required this.buildJobId,
    required this.runId,
    required this.id,
    required this.message,
    required this.level,
    required this.timestamp,
    required this.stackTrace,
  });
}

