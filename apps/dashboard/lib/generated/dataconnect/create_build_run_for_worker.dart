part of 'default.dart';

class CreateBuildRunForWorkerVariablesBuilder {
  String buildJobId;
  String id;

  final FirebaseDataConnect _dataConnect;
  CreateBuildRunForWorkerVariablesBuilder(this._dataConnect, {required  this.buildJobId,required  this.id,});
  Deserializer<CreateBuildRunForWorkerData> dataDeserializer = (dynamic json)  => CreateBuildRunForWorkerData.fromJson(jsonDecode(json));
  Serializer<CreateBuildRunForWorkerVariables> varsSerializer = (CreateBuildRunForWorkerVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateBuildRunForWorkerData, CreateBuildRunForWorkerVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateBuildRunForWorkerData, CreateBuildRunForWorkerVariables> ref() {
    CreateBuildRunForWorkerVariables vars= CreateBuildRunForWorkerVariables(buildJobId: buildJobId,id: id,);
    return _dataConnect.mutation("CreateBuildRunForWorker", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateBuildRunForWorkerBuildRunUpsert {
  final String buildJobId;
  final String id;
  CreateBuildRunForWorkerBuildRunUpsert.fromJson(dynamic json):
  
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

    final CreateBuildRunForWorkerBuildRunUpsert otherTyped = other as CreateBuildRunForWorkerBuildRunUpsert;
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

  CreateBuildRunForWorkerBuildRunUpsert({
    required this.buildJobId,
    required this.id,
  });
}

@immutable
class CreateBuildRunForWorkerBuildJobUpdate {
  final String id;
  CreateBuildRunForWorkerBuildJobUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateBuildRunForWorkerBuildJobUpdate otherTyped = other as CreateBuildRunForWorkerBuildJobUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateBuildRunForWorkerBuildJobUpdate({
    required this.id,
  });
}

@immutable
class CreateBuildRunForWorkerData {
  final CreateBuildRunForWorkerBuildRunUpsert buildRun_upsert;
  final CreateBuildRunForWorkerBuildJobUpdate? buildJob_update;
  CreateBuildRunForWorkerData.fromJson(dynamic json):
  
  buildRun_upsert = CreateBuildRunForWorkerBuildRunUpsert.fromJson(json['buildRun_upsert']),
  buildJob_update = json['buildJob_update'] == null ? null : CreateBuildRunForWorkerBuildJobUpdate.fromJson(json['buildJob_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateBuildRunForWorkerData otherTyped = other as CreateBuildRunForWorkerData;
    return buildRun_upsert == otherTyped.buildRun_upsert && 
    buildJob_update == otherTyped.buildJob_update;
    
  }
  @override
  int get hashCode => Object.hashAll([buildRun_upsert.hashCode, buildJob_update.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['buildRun_upsert'] = buildRun_upsert.toJson();
    if (buildJob_update != null) {
      json['buildJob_update'] = buildJob_update!.toJson();
    }
    return json;
  }

  CreateBuildRunForWorkerData({
    required this.buildRun_upsert,
    this.buildJob_update,
  });
}

@immutable
class CreateBuildRunForWorkerVariables {
  final String buildJobId;
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateBuildRunForWorkerVariables.fromJson(Map<String, dynamic> json):
  
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

    final CreateBuildRunForWorkerVariables otherTyped = other as CreateBuildRunForWorkerVariables;
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

  CreateBuildRunForWorkerVariables({
    required this.buildJobId,
    required this.id,
  });
}

