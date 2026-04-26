part of 'default.dart';

class UpsertBuildLogFromFirestoreVariablesBuilder {
  String buildJobId;
  String runId;
  String id;
  String message;
  Timestamp timestamp;

  final FirebaseDataConnect _dataConnect;
  UpsertBuildLogFromFirestoreVariablesBuilder(this._dataConnect, {required  this.buildJobId,required  this.runId,required  this.id,required  this.message,required  this.timestamp,});
  Deserializer<UpsertBuildLogFromFirestoreData> dataDeserializer = (dynamic json)  => UpsertBuildLogFromFirestoreData.fromJson(jsonDecode(json));
  Serializer<UpsertBuildLogFromFirestoreVariables> varsSerializer = (UpsertBuildLogFromFirestoreVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpsertBuildLogFromFirestoreData, UpsertBuildLogFromFirestoreVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpsertBuildLogFromFirestoreData, UpsertBuildLogFromFirestoreVariables> ref() {
    UpsertBuildLogFromFirestoreVariables vars= UpsertBuildLogFromFirestoreVariables(buildJobId: buildJobId,runId: runId,id: id,message: message,timestamp: timestamp,);
    return _dataConnect.mutation("UpsertBuildLogFromFirestore", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpsertBuildLogFromFirestoreBuildLogUpsert {
  final String buildRunBuildJobId;
  final String buildRunId;
  final String id;
  UpsertBuildLogFromFirestoreBuildLogUpsert.fromJson(dynamic json):
  
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

    final UpsertBuildLogFromFirestoreBuildLogUpsert otherTyped = other as UpsertBuildLogFromFirestoreBuildLogUpsert;
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

  UpsertBuildLogFromFirestoreBuildLogUpsert({
    required this.buildRunBuildJobId,
    required this.buildRunId,
    required this.id,
  });
}

@immutable
class UpsertBuildLogFromFirestoreData {
  final UpsertBuildLogFromFirestoreBuildLogUpsert buildLog_upsert;
  UpsertBuildLogFromFirestoreData.fromJson(dynamic json):
  
  buildLog_upsert = UpsertBuildLogFromFirestoreBuildLogUpsert.fromJson(json['buildLog_upsert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertBuildLogFromFirestoreData otherTyped = other as UpsertBuildLogFromFirestoreData;
    return buildLog_upsert == otherTyped.buildLog_upsert;
    
  }
  @override
  int get hashCode => buildLog_upsert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['buildLog_upsert'] = buildLog_upsert.toJson();
    return json;
  }

  UpsertBuildLogFromFirestoreData({
    required this.buildLog_upsert,
  });
}

@immutable
class UpsertBuildLogFromFirestoreVariables {
  final String buildJobId;
  final String runId;
  final String id;
  final String message;
  final Timestamp timestamp;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpsertBuildLogFromFirestoreVariables.fromJson(Map<String, dynamic> json):
  
  buildJobId = nativeFromJson<String>(json['buildJobId']),
  runId = nativeFromJson<String>(json['runId']),
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

    final UpsertBuildLogFromFirestoreVariables otherTyped = other as UpsertBuildLogFromFirestoreVariables;
    return buildJobId == otherTyped.buildJobId && 
    runId == otherTyped.runId && 
    id == otherTyped.id && 
    message == otherTyped.message && 
    timestamp == otherTyped.timestamp;
    
  }
  @override
  int get hashCode => Object.hashAll([buildJobId.hashCode, runId.hashCode, id.hashCode, message.hashCode, timestamp.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['buildJobId'] = nativeToJson<String>(buildJobId);
    json['runId'] = nativeToJson<String>(runId);
    json['id'] = nativeToJson<String>(id);
    json['message'] = nativeToJson<String>(message);
    json['timestamp'] = timestamp.toJson();
    return json;
  }

  UpsertBuildLogFromFirestoreVariables({
    required this.buildJobId,
    required this.runId,
    required this.id,
    required this.message,
    required this.timestamp,
  });
}

