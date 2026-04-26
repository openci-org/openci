part of 'default.dart';

class UpdateBuildRunStatusForWorkerVariablesBuilder {
  String buildJobId;
  String runId;
  String status;
  Optional<String> _conclusion = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  UpdateBuildRunStatusForWorkerVariablesBuilder conclusion(String? t) {
   _conclusion.value = t;
   return this;
  }

  UpdateBuildRunStatusForWorkerVariablesBuilder(this._dataConnect, {required  this.buildJobId,required  this.runId,required  this.status,});
  Deserializer<UpdateBuildRunStatusForWorkerData> dataDeserializer = (dynamic json)  => UpdateBuildRunStatusForWorkerData.fromJson(jsonDecode(json));
  Serializer<UpdateBuildRunStatusForWorkerVariables> varsSerializer = (UpdateBuildRunStatusForWorkerVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateBuildRunStatusForWorkerData, UpdateBuildRunStatusForWorkerVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateBuildRunStatusForWorkerData, UpdateBuildRunStatusForWorkerVariables> ref() {
    UpdateBuildRunStatusForWorkerVariables vars= UpdateBuildRunStatusForWorkerVariables(buildJobId: buildJobId,runId: runId,status: status,conclusion: _conclusion,);
    return _dataConnect.mutation("UpdateBuildRunStatusForWorker", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateBuildRunStatusForWorkerBuildRunUpdate {
  final String buildJobId;
  final String id;
  UpdateBuildRunStatusForWorkerBuildRunUpdate.fromJson(dynamic json):
  
  buildJobId = nativeFromJson<String>(json['buildJobId']),
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateBuildRunStatusForWorkerBuildRunUpdate otherTyped = other as UpdateBuildRunStatusForWorkerBuildRunUpdate;
    return buildJobId == otherTyped.buildJobId && 
    id == otherTyped.id;
    
  }
  @override
  int get hashCode => Object.hashAll([buildJobId.hashCode, id.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['buildJobId'] = nativeToJson<String>(buildJobId);
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateBuildRunStatusForWorkerBuildRunUpdate({
    required this.buildJobId,
    required this.id,
  });
}

@immutable
class UpdateBuildRunStatusForWorkerData {
  final UpdateBuildRunStatusForWorkerBuildRunUpdate? buildRun_update;
  UpdateBuildRunStatusForWorkerData.fromJson(dynamic json):
  
  buildRun_update = json['buildRun_update'] == null ? null : UpdateBuildRunStatusForWorkerBuildRunUpdate.fromJson(json['buildRun_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateBuildRunStatusForWorkerData otherTyped = other as UpdateBuildRunStatusForWorkerData;
    return buildRun_update == otherTyped.buildRun_update;
    
  }
  @override
  int get hashCode => buildRun_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (buildRun_update != null) {
      json['buildRun_update'] = buildRun_update!.toJson();
    }
    return json;
  }

  UpdateBuildRunStatusForWorkerData({
    this.buildRun_update,
  });
}

@immutable
class UpdateBuildRunStatusForWorkerVariables {
  final String buildJobId;
  final String runId;
  final String status;
  late final Optional<String>conclusion;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateBuildRunStatusForWorkerVariables.fromJson(Map<String, dynamic> json):
  
  buildJobId = nativeFromJson<String>(json['buildJobId']),
  runId = nativeFromJson<String>(json['runId']),
  status = nativeFromJson<String>(json['status']) {
  
  
  
  
  
    conclusion = Optional.optional(nativeFromJson, nativeToJson);
    conclusion.value = json['conclusion'] == null ? null : nativeFromJson<String>(json['conclusion']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateBuildRunStatusForWorkerVariables otherTyped = other as UpdateBuildRunStatusForWorkerVariables;
    return buildJobId == otherTyped.buildJobId && 
    runId == otherTyped.runId && 
    status == otherTyped.status && 
    conclusion == otherTyped.conclusion;
    
  }
  @override
  int get hashCode => Object.hashAll([buildJobId.hashCode, runId.hashCode, status.hashCode, conclusion.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['buildJobId'] = nativeToJson<String>(buildJobId);
    json['runId'] = nativeToJson<String>(runId);
    json['status'] = nativeToJson<String>(status);
    if(conclusion.state == OptionalState.set) {
      json['conclusion'] = conclusion.toJson();
    }
    return json;
  }

  UpdateBuildRunStatusForWorkerVariables({
    required this.buildJobId,
    required this.runId,
    required this.status,
    required this.conclusion,
  });
}

