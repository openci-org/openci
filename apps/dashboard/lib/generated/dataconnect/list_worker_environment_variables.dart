part of 'default.dart';

class ListWorkerEnvironmentVariablesVariablesBuilder {
  String teamId;

  final FirebaseDataConnect _dataConnect;
  ListWorkerEnvironmentVariablesVariablesBuilder(this._dataConnect, {required  this.teamId,});
  Deserializer<ListWorkerEnvironmentVariablesData> dataDeserializer = (dynamic json)  => ListWorkerEnvironmentVariablesData.fromJson(jsonDecode(json));
  Serializer<ListWorkerEnvironmentVariablesVariables> varsSerializer = (ListWorkerEnvironmentVariablesVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<ListWorkerEnvironmentVariablesData, ListWorkerEnvironmentVariablesVariables>> execute() {
    return ref().execute();
  }

  QueryRef<ListWorkerEnvironmentVariablesData, ListWorkerEnvironmentVariablesVariables> ref() {
    ListWorkerEnvironmentVariablesVariables vars= ListWorkerEnvironmentVariablesVariables(teamId: teamId,);
    return _dataConnect.query("ListWorkerEnvironmentVariables", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class ListWorkerEnvironmentVariablesEnvironmentVariables {
  final String id;
  final String key;
  final String value;
  final String teamId;
  late final Optional<bool>autoIncrement;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ListWorkerEnvironmentVariablesEnvironmentVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  key = nativeFromJson<String>(json['key']),
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

    final ListWorkerEnvironmentVariablesEnvironmentVariables otherTyped = other as ListWorkerEnvironmentVariablesEnvironmentVariables;
    return id == otherTyped.id && 
    key == otherTyped.key && 
    value == otherTyped.value && 
    teamId == otherTyped.teamId && 
    autoIncrement == otherTyped.autoIncrement;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, key.hashCode, value.hashCode, teamId.hashCode, autoIncrement.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['key'] = nativeToJson<String>(key);
    json['value'] = nativeToJson<String>(value);
    json['teamId'] = nativeToJson<String>(teamId);
    if(autoIncrement.state == OptionalState.set) {
      json['autoIncrement'] = autoIncrement.toJson();
    }
    return json;
  }

  ListWorkerEnvironmentVariablesEnvironmentVariables({
    required this.id,
    required this.key,
    required this.value,
    required this.teamId,
    required this.autoIncrement,
  });
}

@immutable
class ListWorkerEnvironmentVariablesData {
  final List<ListWorkerEnvironmentVariablesEnvironmentVariables> environmentVariables;
  ListWorkerEnvironmentVariablesData.fromJson(dynamic json):
  
  environmentVariables = (json['environmentVariables'] as List<dynamic>)
        .map((e) => ListWorkerEnvironmentVariablesEnvironmentVariables.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListWorkerEnvironmentVariablesData otherTyped = other as ListWorkerEnvironmentVariablesData;
    return environmentVariables == otherTyped.environmentVariables;
    
  }
  @override
  int get hashCode => environmentVariables.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['environmentVariables'] = environmentVariables.map((e) => e.toJson()).toList();
    return json;
  }

  ListWorkerEnvironmentVariablesData({
    required this.environmentVariables,
  });
}

@immutable
class ListWorkerEnvironmentVariablesVariables {
  final String teamId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ListWorkerEnvironmentVariablesVariables.fromJson(Map<String, dynamic> json):
  
  teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListWorkerEnvironmentVariablesVariables otherTyped = other as ListWorkerEnvironmentVariablesVariables;
    return teamId == otherTyped.teamId;
    
  }
  @override
  int get hashCode => teamId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  ListWorkerEnvironmentVariablesVariables({
    required this.teamId,
  });
}

