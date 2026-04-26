part of 'default.dart';

class ListWorkerSecretsVariablesBuilder {
  String teamId;

  final FirebaseDataConnect _dataConnect;
  ListWorkerSecretsVariablesBuilder(this._dataConnect, {required  this.teamId,});
  Deserializer<ListWorkerSecretsData> dataDeserializer = (dynamic json)  => ListWorkerSecretsData.fromJson(jsonDecode(json));
  Serializer<ListWorkerSecretsVariables> varsSerializer = (ListWorkerSecretsVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<ListWorkerSecretsData, ListWorkerSecretsVariables>> execute() {
    return ref().execute();
  }

  QueryRef<ListWorkerSecretsData, ListWorkerSecretsVariables> ref() {
    ListWorkerSecretsVariables vars= ListWorkerSecretsVariables(teamId: teamId,);
    return _dataConnect.query("ListWorkerSecrets", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class ListWorkerSecretsSecrets {
  final String id;
  final String name;
  final String teamId;
  final String? pathToSecret;
  ListWorkerSecretsSecrets.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  name = nativeFromJson<String>(json['name']),
  teamId = nativeFromJson<String>(json['teamId']),
  pathToSecret = json['pathToSecret'] == null ? null : nativeFromJson<String>(json['pathToSecret']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListWorkerSecretsSecrets otherTyped = other as ListWorkerSecretsSecrets;
    return id == otherTyped.id && 
    name == otherTyped.name && 
    teamId == otherTyped.teamId && 
    pathToSecret == otherTyped.pathToSecret;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, name.hashCode, teamId.hashCode, pathToSecret.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    json['teamId'] = nativeToJson<String>(teamId);
    if (pathToSecret != null) {
      json['pathToSecret'] = nativeToJson<String?>(pathToSecret);
    }
    return json;
  }

  ListWorkerSecretsSecrets({
    required this.id,
    required this.name,
    required this.teamId,
    this.pathToSecret,
  });
}

@immutable
class ListWorkerSecretsData {
  final List<ListWorkerSecretsSecrets> secrets;
  ListWorkerSecretsData.fromJson(dynamic json):
  
  secrets = (json['secrets'] as List<dynamic>)
        .map((e) => ListWorkerSecretsSecrets.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListWorkerSecretsData otherTyped = other as ListWorkerSecretsData;
    return secrets == otherTyped.secrets;
    
  }
  @override
  int get hashCode => secrets.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['secrets'] = secrets.map((e) => e.toJson()).toList();
    return json;
  }

  ListWorkerSecretsData({
    required this.secrets,
  });
}

@immutable
class ListWorkerSecretsVariables {
  final String teamId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ListWorkerSecretsVariables.fromJson(Map<String, dynamic> json):
  
  teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListWorkerSecretsVariables otherTyped = other as ListWorkerSecretsVariables;
    return teamId == otherTyped.teamId;
    
  }
  @override
  int get hashCode => teamId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  ListWorkerSecretsVariables({
    required this.teamId,
  });
}

