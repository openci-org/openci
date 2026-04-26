part of 'default.dart';

class GetSecretsByNamesForTeamVariablesBuilder {
  String teamId;
  List<String> names;

  final FirebaseDataConnect _dataConnect;
  GetSecretsByNamesForTeamVariablesBuilder(this._dataConnect, {required  this.teamId,required  this.names,});
  Deserializer<GetSecretsByNamesForTeamData> dataDeserializer = (dynamic json)  => GetSecretsByNamesForTeamData.fromJson(jsonDecode(json));
  Serializer<GetSecretsByNamesForTeamVariables> varsSerializer = (GetSecretsByNamesForTeamVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetSecretsByNamesForTeamData, GetSecretsByNamesForTeamVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetSecretsByNamesForTeamData, GetSecretsByNamesForTeamVariables> ref() {
    GetSecretsByNamesForTeamVariables vars= GetSecretsByNamesForTeamVariables(teamId: teamId,names: names,);
    return _dataConnect.query("GetSecretsByNamesForTeam", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetSecretsByNamesForTeamTeamMember {
  final String teamId;
  GetSecretsByNamesForTeamTeamMember.fromJson(dynamic json):
  
  teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetSecretsByNamesForTeamTeamMember otherTyped = other as GetSecretsByNamesForTeamTeamMember;
    return teamId == otherTyped.teamId;
    
  }
  @override
  int get hashCode => teamId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  GetSecretsByNamesForTeamTeamMember({
    required this.teamId,
  });
}

@immutable
class GetSecretsByNamesForTeamSecrets {
  final String id;
  final String name;
  final String teamId;
  final String? pathToSecret;
  GetSecretsByNamesForTeamSecrets.fromJson(dynamic json):
  
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

    final GetSecretsByNamesForTeamSecrets otherTyped = other as GetSecretsByNamesForTeamSecrets;
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

  GetSecretsByNamesForTeamSecrets({
    required this.id,
    required this.name,
    required this.teamId,
    this.pathToSecret,
  });
}

@immutable
class GetSecretsByNamesForTeamData {
  final GetSecretsByNamesForTeamTeamMember? teamMember;
  final List<GetSecretsByNamesForTeamSecrets> secrets;
  GetSecretsByNamesForTeamData.fromJson(dynamic json):
  
  teamMember = json['teamMember'] == null ? null : GetSecretsByNamesForTeamTeamMember.fromJson(json['teamMember']),
  secrets = (json['secrets'] as List<dynamic>)
        .map((e) => GetSecretsByNamesForTeamSecrets.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetSecretsByNamesForTeamData otherTyped = other as GetSecretsByNamesForTeamData;
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

  GetSecretsByNamesForTeamData({
    this.teamMember,
    required this.secrets,
  });
}

@immutable
class GetSecretsByNamesForTeamVariables {
  final String teamId;
  final List<String> names;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetSecretsByNamesForTeamVariables.fromJson(Map<String, dynamic> json):
  
  teamId = nativeFromJson<String>(json['teamId']),
  names = (json['names'] as List<dynamic>)
        .map((e) => nativeFromJson<String>(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetSecretsByNamesForTeamVariables otherTyped = other as GetSecretsByNamesForTeamVariables;
    return teamId == otherTyped.teamId && 
    names == otherTyped.names;
    
  }
  @override
  int get hashCode => Object.hashAll([teamId.hashCode, names.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['names'] = names.map((e) => nativeToJson<String>(e)).toList();
    return json;
  }

  GetSecretsByNamesForTeamVariables({
    required this.teamId,
    required this.names,
  });
}

