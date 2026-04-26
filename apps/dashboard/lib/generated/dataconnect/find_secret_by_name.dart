part of 'default.dart';

class FindSecretByNameVariablesBuilder {
  String teamId;
  String name;

  final FirebaseDataConnect _dataConnect;
  FindSecretByNameVariablesBuilder(this._dataConnect, {required  this.teamId,required  this.name,});
  Deserializer<FindSecretByNameData> dataDeserializer = (dynamic json)  => FindSecretByNameData.fromJson(jsonDecode(json));
  Serializer<FindSecretByNameVariables> varsSerializer = (FindSecretByNameVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<FindSecretByNameData, FindSecretByNameVariables>> execute() {
    return ref().execute();
  }

  QueryRef<FindSecretByNameData, FindSecretByNameVariables> ref() {
    FindSecretByNameVariables vars= FindSecretByNameVariables(teamId: teamId,name: name,);
    return _dataConnect.query("FindSecretByName", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class FindSecretByNameTeamMember {
  final String teamId;
  FindSecretByNameTeamMember.fromJson(dynamic json):
  
  teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final FindSecretByNameTeamMember otherTyped = other as FindSecretByNameTeamMember;
    return teamId == otherTyped.teamId;
    
  }
  @override
  int get hashCode => teamId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  FindSecretByNameTeamMember({
    required this.teamId,
  });
}

@immutable
class FindSecretByNameSecrets {
  final String id;
  final String name;
  final String teamId;
  final String? pathToSecret;
  FindSecretByNameSecrets.fromJson(dynamic json):
  
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

    final FindSecretByNameSecrets otherTyped = other as FindSecretByNameSecrets;
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

  FindSecretByNameSecrets({
    required this.id,
    required this.name,
    required this.teamId,
    this.pathToSecret,
  });
}

@immutable
class FindSecretByNameData {
  final FindSecretByNameTeamMember? teamMember;
  final List<FindSecretByNameSecrets> secrets;
  FindSecretByNameData.fromJson(dynamic json):
  
  teamMember = json['teamMember'] == null ? null : FindSecretByNameTeamMember.fromJson(json['teamMember']),
  secrets = (json['secrets'] as List<dynamic>)
        .map((e) => FindSecretByNameSecrets.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final FindSecretByNameData otherTyped = other as FindSecretByNameData;
    return teamMember == otherTyped.teamMember && 
    secrets == otherTyped.secrets;
    
  }
  @override
  int get hashCode => Object.hashAll([teamMember.hashCode, secrets.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (teamMember != null) {
      json['teamMember'] = teamMember!.toJson();
    }
    json['secrets'] = secrets.map((e) => e.toJson()).toList();
    return json;
  }

  FindSecretByNameData({
    this.teamMember,
    required this.secrets,
  });
}

@immutable
class FindSecretByNameVariables {
  final String teamId;
  final String name;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  FindSecretByNameVariables.fromJson(Map<String, dynamic> json):
  
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

    final FindSecretByNameVariables otherTyped = other as FindSecretByNameVariables;
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

  FindSecretByNameVariables({
    required this.teamId,
    required this.name,
  });
}

