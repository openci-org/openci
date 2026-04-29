part of 'default.dart';

class FindSecretByNameForTeamVariablesBuilder {
  String teamId;
  String name;

  final FirebaseDataConnect _dataConnect;
  FindSecretByNameForTeamVariablesBuilder(this._dataConnect, {required  this.teamId,required  this.name,});
  Deserializer<FindSecretByNameForTeamData> dataDeserializer = (dynamic json)  => FindSecretByNameForTeamData.fromJson(jsonDecode(json));
  Serializer<FindSecretByNameForTeamVariables> varsSerializer = (FindSecretByNameForTeamVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<FindSecretByNameForTeamData, FindSecretByNameForTeamVariables>> execute() {
    return ref().execute();
  }

  QueryRef<FindSecretByNameForTeamData, FindSecretByNameForTeamVariables> ref() {
    FindSecretByNameForTeamVariables vars= FindSecretByNameForTeamVariables(teamId: teamId,name: name,);
    return _dataConnect.query("FindSecretByNameForTeam", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class FindSecretByNameForTeamSecrets {
  final String id;
  final String name;
  final String teamId;
  FindSecretByNameForTeamSecrets.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  name = nativeFromJson<String>(json['name']),
  teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final FindSecretByNameForTeamSecrets otherTyped = other as FindSecretByNameForTeamSecrets;
    return id == otherTyped.id && 
    name == otherTyped.name && 
    teamId == otherTyped.teamId;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, name.hashCode, teamId.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  FindSecretByNameForTeamSecrets({
    required this.id,
    required this.name,
    required this.teamId,
  });
}

@immutable
class FindSecretByNameForTeamData {
  final List<FindSecretByNameForTeamSecrets> secrets;
  FindSecretByNameForTeamData.fromJson(dynamic json):
  
  secrets = (json['secrets'] as List<dynamic>)
        .map((e) => FindSecretByNameForTeamSecrets.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final FindSecretByNameForTeamData otherTyped = other as FindSecretByNameForTeamData;
    return secrets == otherTyped.secrets;
    
  }
  @override
  int get hashCode => secrets.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['secrets'] = secrets.map((e) => e.toJson()).toList();
    return json;
  }

  FindSecretByNameForTeamData({
    required this.secrets,
  });
}

@immutable
class FindSecretByNameForTeamVariables {
  final String teamId;
  final String name;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  FindSecretByNameForTeamVariables.fromJson(Map<String, dynamic> json):
  
  teamId = nativeFromJson<String>(json['teamId']),
  name = nativeFromJson<String>(json['name']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final FindSecretByNameForTeamVariables otherTyped = other as FindSecretByNameForTeamVariables;
    return teamId == otherTyped.teamId && 
    name == otherTyped.name;
    
  }
  @override
  int get hashCode => Object.hashAll([teamId.hashCode, name.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['name'] = nativeToJson<String>(name);
    return json;
  }

  FindSecretByNameForTeamVariables({
    required this.teamId,
    required this.name,
  });
}

