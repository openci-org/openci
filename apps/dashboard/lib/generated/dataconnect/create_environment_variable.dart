part of 'default.dart';

class CreateEnvironmentVariableVariablesBuilder {
  String id;
  String envKey;
  String value;
  String teamId;
  Optional<bool> _autoIncrement = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  CreateEnvironmentVariableVariablesBuilder autoIncrement(bool? t) {
   _autoIncrement.value = t;
   return this;
  }

  CreateEnvironmentVariableVariablesBuilder(this._dataConnect, {required  this.id,required  this.envKey,required  this.value,required  this.teamId,});
  Deserializer<CreateEnvironmentVariableData> dataDeserializer = (dynamic json)  => CreateEnvironmentVariableData.fromJson(jsonDecode(json));
  Serializer<CreateEnvironmentVariableVariables> varsSerializer = (CreateEnvironmentVariableVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateEnvironmentVariableData, CreateEnvironmentVariableVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateEnvironmentVariableData, CreateEnvironmentVariableVariables> ref() {
    CreateEnvironmentVariableVariables vars= CreateEnvironmentVariableVariables(id: id,envKey: envKey,value: value,teamId: teamId,autoIncrement: _autoIncrement,);
    return _dataConnect.mutation("CreateEnvironmentVariable", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateEnvironmentVariableEnvironmentVariableInsert {
  final String id;
  CreateEnvironmentVariableEnvironmentVariableInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateEnvironmentVariableEnvironmentVariableInsert otherTyped = other as CreateEnvironmentVariableEnvironmentVariableInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateEnvironmentVariableEnvironmentVariableInsert({
    required this.id,
  });
}

@immutable
class CreateEnvironmentVariableData {
  final CreateEnvironmentVariableEnvironmentVariableInsert environmentVariable_insert;
  CreateEnvironmentVariableData.fromJson(dynamic json):
  
  environmentVariable_insert = CreateEnvironmentVariableEnvironmentVariableInsert.fromJson(json['environmentVariable_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateEnvironmentVariableData otherTyped = other as CreateEnvironmentVariableData;
    return environmentVariable_insert == otherTyped.environmentVariable_insert;
    
  }
  @override
  int get hashCode => environmentVariable_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['environmentVariable_insert'] = environmentVariable_insert.toJson();
    return json;
  }

  CreateEnvironmentVariableData({
    required this.environmentVariable_insert,
  });
}

@immutable
class CreateEnvironmentVariableVariables {
  final String id;
  final String envKey;
  final String value;
  final String teamId;
  late final Optional<bool>autoIncrement;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateEnvironmentVariableVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  envKey = nativeFromJson<String>(json['envKey']),
  value = nativeFromJson<String>(json['value']),
  teamId = nativeFromJson<String>(json['teamId']) {
  
  
  
  
  
  
    autoIncrement = Optional.optional(nativeFromJson, nativeToJson);
    autoIncrement.value = json['autoIncrement'] == null ? null : nativeFromJson<bool>(json['autoIncrement']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateEnvironmentVariableVariables otherTyped = other as CreateEnvironmentVariableVariables;
    return id == otherTyped.id && 
    envKey == otherTyped.envKey && 
    value == otherTyped.value && 
    teamId == otherTyped.teamId && 
    autoIncrement == otherTyped.autoIncrement;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, envKey.hashCode, value.hashCode, teamId.hashCode, autoIncrement.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['envKey'] = nativeToJson<String>(envKey);
    json['value'] = nativeToJson<String>(value);
    json['teamId'] = nativeToJson<String>(teamId);
    if(autoIncrement.state == OptionalState.set) {
      json['autoIncrement'] = autoIncrement.toJson();
    }
    return json;
  }

  CreateEnvironmentVariableVariables({
    required this.id,
    required this.envKey,
    required this.value,
    required this.teamId,
    required this.autoIncrement,
  });
}

