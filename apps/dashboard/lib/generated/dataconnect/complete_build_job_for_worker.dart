part of 'default.dart';

class CompleteBuildJobForWorkerVariablesBuilder {
  String id;
  String status;
  Timestamp completedAt;

  final FirebaseDataConnect _dataConnect;
  CompleteBuildJobForWorkerVariablesBuilder(this._dataConnect, {required  this.id,required  this.status,required  this.completedAt,});
  Deserializer<CompleteBuildJobForWorkerData> dataDeserializer = (dynamic json)  => CompleteBuildJobForWorkerData.fromJson(jsonDecode(json));
  Serializer<CompleteBuildJobForWorkerVariables> varsSerializer = (CompleteBuildJobForWorkerVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CompleteBuildJobForWorkerData, CompleteBuildJobForWorkerVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CompleteBuildJobForWorkerData, CompleteBuildJobForWorkerVariables> ref() {
    CompleteBuildJobForWorkerVariables vars= CompleteBuildJobForWorkerVariables(id: id,status: status,completedAt: completedAt,);
    return _dataConnect.mutation("CompleteBuildJobForWorker", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CompleteBuildJobForWorkerBuildJobUpdate {
  final String id;
  CompleteBuildJobForWorkerBuildJobUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CompleteBuildJobForWorkerBuildJobUpdate otherTyped = other as CompleteBuildJobForWorkerBuildJobUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CompleteBuildJobForWorkerBuildJobUpdate({
    required this.id,
  });
}

@immutable
class CompleteBuildJobForWorkerData {
  final CompleteBuildJobForWorkerBuildJobUpdate? buildJob_update;
  CompleteBuildJobForWorkerData.fromJson(dynamic json):
  
  buildJob_update = json['buildJob_update'] == null ? null : CompleteBuildJobForWorkerBuildJobUpdate.fromJson(json['buildJob_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CompleteBuildJobForWorkerData otherTyped = other as CompleteBuildJobForWorkerData;
    return buildJob_update == otherTyped.buildJob_update;
    
  }
  @override
  int get hashCode => buildJob_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (buildJob_update != null) {
      json['buildJob_update'] = buildJob_update!.toJson();
    }
    return json;
  }

  CompleteBuildJobForWorkerData({
    this.buildJob_update,
  });
}

@immutable
class CompleteBuildJobForWorkerVariables {
  final String id;
  final String status;
  final Timestamp completedAt;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CompleteBuildJobForWorkerVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  status = nativeFromJson<String>(json['status']),
  completedAt = Timestamp.fromJson(json['completedAt']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CompleteBuildJobForWorkerVariables otherTyped = other as CompleteBuildJobForWorkerVariables;
    return id == otherTyped.id && 
    status == otherTyped.status && 
    completedAt == otherTyped.completedAt;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, status.hashCode, completedAt.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['status'] = nativeToJson<String>(status);
    json['completedAt'] = completedAt.toJson();
    return json;
  }

  CompleteBuildJobForWorkerVariables({
    required this.id,
    required this.status,
    required this.completedAt,
  });
}

