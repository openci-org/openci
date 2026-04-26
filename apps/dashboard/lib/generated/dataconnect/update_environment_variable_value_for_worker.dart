part of 'default.dart';

class UpdateEnvironmentVariableValueForWorkerVariablesBuilder {
  String id;
  String value;

  final FirebaseDataConnect _dataConnect;
  UpdateEnvironmentVariableValueForWorkerVariablesBuilder(this._dataConnect, {required  this.id,required  this.value,});
  Deserializer<UpdateEnvironmentVariableValueForWorkerData> dataDeserializer = (dynamic json)  => UpdateEnvironmentVariableValueForWorkerData.fromJson(jsonDecode(json));
  Serializer<UpdateEnvironmentVariableValueForWorkerVariables> varsSerializer = (UpdateEnvironmentVariableValueForWorkerVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateEnvironmentVariableValueForWorkerData, UpdateEnvironmentVariableValueForWorkerVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateEnvironmentVariableValueForWorkerData, UpdateEnvironmentVariableValueForWorkerVariables> ref() {
    UpdateEnvironmentVariableValueForWorkerVariables vars= UpdateEnvironmentVariableValueForWorkerVariables(id: id,value: value,);
    return _dataConnect.mutation("UpdateEnvironmentVariableValueForWorker", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateEnvironmentVariableValueForWorkerEnvironmentVariableUpdate {
  final String id;
  UpdateEnvironmentVariableValueForWorkerEnvironmentVariableUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateEnvironmentVariableValueForWorkerEnvironmentVariableUpdate otherTyped = other as UpdateEnvironmentVariableValueForWorkerEnvironmentVariableUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateEnvironmentVariableValueForWorkerEnvironmentVariableUpdate({
    required this.id,
  });
}

@immutable
class UpdateEnvironmentVariableValueForWorkerData {
  final UpdateEnvironmentVariableValueForWorkerEnvironmentVariableUpdate? environmentVariable_update;
  UpdateEnvironmentVariableValueForWorkerData.fromJson(dynamic json):
  
  environmentVariable_update = json['environmentVariable_update'] == null ? null : UpdateEnvironmentVariableValueForWorkerEnvironmentVariableUpdate.fromJson(json['environmentVariable_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateEnvironmentVariableValueForWorkerData otherTyped = other as UpdateEnvironmentVariableValueForWorkerData;
    return environmentVariable_update == otherTyped.environmentVariable_update;
    
  }
  @override
  int get hashCode => environmentVariable_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (environmentVariable_update != null) {
      json['environmentVariable_update'] = environmentVariable_update!.toJson();
    }
    return json;
  }

  UpdateEnvironmentVariableValueForWorkerData({
    this.environmentVariable_update,
  });
}

@immutable
class UpdateEnvironmentVariableValueForWorkerVariables {
  final String id;
  final String value;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateEnvironmentVariableValueForWorkerVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  value = nativeFromJson<String>(json['value']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateEnvironmentVariableValueForWorkerVariables otherTyped = other as UpdateEnvironmentVariableValueForWorkerVariables;
    return id == otherTyped.id && 
    value == otherTyped.value;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, value.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['value'] = nativeToJson<String>(value);
    return json;
  }

  UpdateEnvironmentVariableValueForWorkerVariables({
    required this.id,
    required this.value,
  });
}

