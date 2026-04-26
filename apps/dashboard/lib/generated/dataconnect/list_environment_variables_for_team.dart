part of 'default.dart';

class ListEnvironmentVariablesForTeamVariablesBuilder {
  String teamId;

  final FirebaseDataConnect _dataConnect;
  ListEnvironmentVariablesForTeamVariablesBuilder(this._dataConnect, {required  this.teamId,});
  Deserializer<ListEnvironmentVariablesForTeamData> dataDeserializer = (dynamic json)  => ListEnvironmentVariablesForTeamData.fromJson(jsonDecode(json));
  Serializer<ListEnvironmentVariablesForTeamVariables> varsSerializer = (ListEnvironmentVariablesForTeamVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<ListEnvironmentVariablesForTeamData, ListEnvironmentVariablesForTeamVariables>> execute() {
    return ref().execute();
  }

  QueryRef<ListEnvironmentVariablesForTeamData, ListEnvironmentVariablesForTeamVariables> ref() {
    ListEnvironmentVariablesForTeamVariables vars= ListEnvironmentVariablesForTeamVariables(teamId: teamId,);
    return _dataConnect.query("ListEnvironmentVariablesForTeam", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class ListEnvironmentVariablesForTeamEnvironmentVariables {
  final String id;
  final String key;
  final String value;
  final String teamId;
  late final Optional<bool>autoIncrement;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ListEnvironmentVariablesForTeamEnvironmentVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  key = nativeFromJson<String>(json['key']),
  value = nativeFromJson<String>(json['value']),
  teamId = nativeFromJson<String>(json['teamId']),
  createdAt = Timestamp.fromJson(json['createdAt']),
  updatedAt = Timestamp.fromJson(json['updatedAt']) {
  
  
  
  
  
  
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

    final ListEnvironmentVariablesForTeamEnvironmentVariables otherTyped = other as ListEnvironmentVariablesForTeamEnvironmentVariables;
    return id == otherTyped.id && 
    key == otherTyped.key && 
    value == otherTyped.value && 
    teamId == otherTyped.teamId && 
    autoIncrement == otherTyped.autoIncrement && 
    createdAt == otherTyped.createdAt && 
    updatedAt == otherTyped.updatedAt;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, key.hashCode, value.hashCode, teamId.hashCode, autoIncrement.hashCode, createdAt.hashCode, updatedAt.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['key'] = nativeToJson<String>(key);
    json['value'] = nativeToJson<String>(value);
    json['teamId'] = nativeToJson<String>(teamId);
    if(autoIncrement.state == OptionalState.set) {
      json['autoIncrement'] = autoIncrement.toJson();
    }
    json['createdAt'] = createdAt.toJson();
    json['updatedAt'] = updatedAt.toJson();
    return json;
  }

  ListEnvironmentVariablesForTeamEnvironmentVariables({
    required this.id,
    required this.key,
    required this.value,
    required this.teamId,
    required this.autoIncrement,
    required this.createdAt,
    required this.updatedAt,
  });
}

@immutable
class ListEnvironmentVariablesForTeamData {
  final List<ListEnvironmentVariablesForTeamEnvironmentVariables> environmentVariables;
  ListEnvironmentVariablesForTeamData.fromJson(dynamic json):
  
  environmentVariables = (json['environmentVariables'] as List<dynamic>)
        .map((e) => ListEnvironmentVariablesForTeamEnvironmentVariables.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListEnvironmentVariablesForTeamData otherTyped = other as ListEnvironmentVariablesForTeamData;
    return environmentVariables == otherTyped.environmentVariables;
    
  }
  @override
  int get hashCode => environmentVariables.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['environmentVariables'] = environmentVariables.map((e) => e.toJson()).toList();
    return json;
  }

  ListEnvironmentVariablesForTeamData({
    required this.environmentVariables,
  });
}

@immutable
class ListEnvironmentVariablesForTeamVariables {
  final String teamId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ListEnvironmentVariablesForTeamVariables.fromJson(Map<String, dynamic> json):
  
  teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListEnvironmentVariablesForTeamVariables otherTyped = other as ListEnvironmentVariablesForTeamVariables;
    return teamId == otherTyped.teamId;
    
  }
  @override
  int get hashCode => teamId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  ListEnvironmentVariablesForTeamVariables({
    required this.teamId,
  });
}

