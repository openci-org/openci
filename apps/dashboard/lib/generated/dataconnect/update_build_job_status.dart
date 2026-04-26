part of 'default.dart';

class UpdateBuildJobStatusVariablesBuilder {
  String id;
  String status;

  final FirebaseDataConnect _dataConnect;
  UpdateBuildJobStatusVariablesBuilder(this._dataConnect, {required  this.id,required  this.status,});
  Deserializer<UpdateBuildJobStatusData> dataDeserializer = (dynamic json)  => UpdateBuildJobStatusData.fromJson(jsonDecode(json));
  Serializer<UpdateBuildJobStatusVariables> varsSerializer = (UpdateBuildJobStatusVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateBuildJobStatusData, UpdateBuildJobStatusVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateBuildJobStatusData, UpdateBuildJobStatusVariables> ref() {
    UpdateBuildJobStatusVariables vars= UpdateBuildJobStatusVariables(id: id,status: status,);
    return _dataConnect.mutation("UpdateBuildJobStatus", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateBuildJobStatusBuildJobUpdate {
  final String id;
  UpdateBuildJobStatusBuildJobUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateBuildJobStatusBuildJobUpdate otherTyped = other as UpdateBuildJobStatusBuildJobUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateBuildJobStatusBuildJobUpdate({
    required this.id,
  });
}

@immutable
class UpdateBuildJobStatusData {
  final UpdateBuildJobStatusBuildJobUpdate? buildJob_update;
  UpdateBuildJobStatusData.fromJson(dynamic json):
  
  buildJob_update = json['buildJob_update'] == null ? null : UpdateBuildJobStatusBuildJobUpdate.fromJson(json['buildJob_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateBuildJobStatusData otherTyped = other as UpdateBuildJobStatusData;
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

  UpdateBuildJobStatusData({
    this.buildJob_update,
  });
}

@immutable
class UpdateBuildJobStatusVariables {
  final String id;
  final String status;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateBuildJobStatusVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  status = nativeFromJson<String>(json['status']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateBuildJobStatusVariables otherTyped = other as UpdateBuildJobStatusVariables;
    return id == otherTyped.id && 
    status == otherTyped.status;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, status.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['status'] = nativeToJson<String>(status);
    return json;
  }

  UpdateBuildJobStatusVariables({
    required this.id,
    required this.status,
  });
}

