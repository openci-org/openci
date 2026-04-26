part of 'default.dart';

class UpsertEnvironmentVariableFromFirestoreVariablesBuilder {
  String id;
  String envKey;
  String value;
  String teamId;
  Optional<bool> _autoIncrement = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  UpsertEnvironmentVariableFromFirestoreVariablesBuilder autoIncrement(bool? t) {
   _autoIncrement.value = t;
   return this;
  }

  UpsertEnvironmentVariableFromFirestoreVariablesBuilder(this._dataConnect, {required  this.id,required  this.envKey,required  this.value,required  this.teamId,});
  Deserializer<UpsertEnvironmentVariableFromFirestoreData> dataDeserializer = (dynamic json)  => UpsertEnvironmentVariableFromFirestoreData.fromJson(jsonDecode(json));
  Serializer<UpsertEnvironmentVariableFromFirestoreVariables> varsSerializer = (UpsertEnvironmentVariableFromFirestoreVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpsertEnvironmentVariableFromFirestoreData, UpsertEnvironmentVariableFromFirestoreVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpsertEnvironmentVariableFromFirestoreData, UpsertEnvironmentVariableFromFirestoreVariables> ref() {
    UpsertEnvironmentVariableFromFirestoreVariables vars= UpsertEnvironmentVariableFromFirestoreVariables(id: id,envKey: envKey,value: value,teamId: teamId,autoIncrement: _autoIncrement,);
    return _dataConnect.mutation("UpsertEnvironmentVariableFromFirestore", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpsertEnvironmentVariableFromFirestoreEnvironmentVariableUpsert {
  final String id;
  UpsertEnvironmentVariableFromFirestoreEnvironmentVariableUpsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertEnvironmentVariableFromFirestoreEnvironmentVariableUpsert otherTyped = other as UpsertEnvironmentVariableFromFirestoreEnvironmentVariableUpsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpsertEnvironmentVariableFromFirestoreEnvironmentVariableUpsert({
    required this.id,
  });
}

@immutable
class UpsertEnvironmentVariableFromFirestoreData {
  final UpsertEnvironmentVariableFromFirestoreEnvironmentVariableUpsert environmentVariable_upsert;
  UpsertEnvironmentVariableFromFirestoreData.fromJson(dynamic json):
  
  environmentVariable_upsert = UpsertEnvironmentVariableFromFirestoreEnvironmentVariableUpsert.fromJson(json['environmentVariable_upsert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertEnvironmentVariableFromFirestoreData otherTyped = other as UpsertEnvironmentVariableFromFirestoreData;
    return environmentVariable_upsert == otherTyped.environmentVariable_upsert;
    
  }
  @override
  int get hashCode => environmentVariable_upsert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['environmentVariable_upsert'] = environmentVariable_upsert.toJson();
    return json;
  }

  UpsertEnvironmentVariableFromFirestoreData({
    required this.environmentVariable_upsert,
  });
}

@immutable
class UpsertEnvironmentVariableFromFirestoreVariables {
  final String id;
  final String envKey;
  final String value;
  final String teamId;
  late final Optional<bool>autoIncrement;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpsertEnvironmentVariableFromFirestoreVariables.fromJson(Map<String, dynamic> json):
  
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

    final UpsertEnvironmentVariableFromFirestoreVariables otherTyped = other as UpsertEnvironmentVariableFromFirestoreVariables;
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

  UpsertEnvironmentVariableFromFirestoreVariables({
    required this.id,
    required this.envKey,
    required this.value,
    required this.teamId,
    required this.autoIncrement,
  });
}

