part of 'default.dart';

class UpdateEnvironmentVariableVariablesBuilder {
  String id;
  String teamId;
  String envKey;
  String value;

  final FirebaseDataConnect _dataConnect;
  UpdateEnvironmentVariableVariablesBuilder(this._dataConnect, {required  this.id,required  this.teamId,required  this.envKey,required  this.value,});
  Deserializer<UpdateEnvironmentVariableData> dataDeserializer = (dynamic json)  => UpdateEnvironmentVariableData.fromJson(jsonDecode(json));
  Serializer<UpdateEnvironmentVariableVariables> varsSerializer = (UpdateEnvironmentVariableVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateEnvironmentVariableData, UpdateEnvironmentVariableVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateEnvironmentVariableData, UpdateEnvironmentVariableVariables> ref() {
    UpdateEnvironmentVariableVariables vars= UpdateEnvironmentVariableVariables(id: id,teamId: teamId,envKey: envKey,value: value,);
    return _dataConnect.mutation("UpdateEnvironmentVariable", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateEnvironmentVariableEnvironmentVariableUpdate {
  final String id;
  UpdateEnvironmentVariableEnvironmentVariableUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateEnvironmentVariableEnvironmentVariableUpdate otherTyped = other as UpdateEnvironmentVariableEnvironmentVariableUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateEnvironmentVariableEnvironmentVariableUpdate({
    required this.id,
  });
}

@immutable
class UpdateEnvironmentVariableData {
  final UpdateEnvironmentVariableEnvironmentVariableUpdate? environmentVariable_update;
  UpdateEnvironmentVariableData.fromJson(dynamic json):
  
  environmentVariable_update = json['environmentVariable_update'] == null ? null : UpdateEnvironmentVariableEnvironmentVariableUpdate.fromJson(json['environmentVariable_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateEnvironmentVariableData otherTyped = other as UpdateEnvironmentVariableData;
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

  UpdateEnvironmentVariableData({
    this.environmentVariable_update,
  });
}

@immutable
class UpdateEnvironmentVariableVariables {
  final String id;
  final String teamId;
  final String envKey;
  final String value;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateEnvironmentVariableVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  teamId = nativeFromJson<String>(json['teamId']),
  envKey = nativeFromJson<String>(json['envKey']),
  value = nativeFromJson<String>(json['value']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateEnvironmentVariableVariables otherTyped = other as UpdateEnvironmentVariableVariables;
    return id == otherTyped.id && 
    teamId == otherTyped.teamId && 
    envKey == otherTyped.envKey && 
    value == otherTyped.value;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, teamId.hashCode, envKey.hashCode, value.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['teamId'] = nativeToJson<String>(teamId);
    json['envKey'] = nativeToJson<String>(envKey);
    json['value'] = nativeToJson<String>(value);
    return json;
  }

  UpdateEnvironmentVariableVariables({
    required this.id,
    required this.teamId,
    required this.envKey,
    required this.value,
  });
}

