part of 'default.dart';

class GetSecretPathForTeamVariablesBuilder {
  String id;
  String teamId;

  final FirebaseDataConnect _dataConnect;
  GetSecretPathForTeamVariablesBuilder(this._dataConnect, {required  this.id,required  this.teamId,});
  Deserializer<GetSecretPathForTeamData> dataDeserializer = (dynamic json)  => GetSecretPathForTeamData.fromJson(jsonDecode(json));
  Serializer<GetSecretPathForTeamVariables> varsSerializer = (GetSecretPathForTeamVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetSecretPathForTeamData, GetSecretPathForTeamVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetSecretPathForTeamData, GetSecretPathForTeamVariables> ref() {
    GetSecretPathForTeamVariables vars= GetSecretPathForTeamVariables(id: id,teamId: teamId,);
    return _dataConnect.query("GetSecretPathForTeam", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetSecretPathForTeamSecret {
  final String id;
  final String name;
  final String teamId;
  final String? pathToSecret;
  GetSecretPathForTeamSecret.fromJson(dynamic json):
  
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

    final GetSecretPathForTeamSecret otherTyped = other as GetSecretPathForTeamSecret;
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

  GetSecretPathForTeamSecret({
    required this.id,
    required this.name,
    required this.teamId,
    this.pathToSecret,
  });
}

@immutable
class GetSecretPathForTeamData {
  final GetSecretPathForTeamSecret? secret;
  GetSecretPathForTeamData.fromJson(dynamic json):
  
  secret = json['secret'] == null ? null : GetSecretPathForTeamSecret.fromJson(json['secret']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetSecretPathForTeamData otherTyped = other as GetSecretPathForTeamData;
    return secret == otherTyped.secret;
    
  }
  @override
  int get hashCode => secret.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (secret != null) {
      json['secret'] = secret!.toJson();
    }
    return json;
  }

  GetSecretPathForTeamData({
    this.secret,
  });
}

@immutable
class GetSecretPathForTeamVariables {
  final String id;
  final String teamId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetSecretPathForTeamVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetSecretPathForTeamVariables otherTyped = other as GetSecretPathForTeamVariables;
    return id == otherTyped.id && 
    teamId == otherTyped.teamId;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, teamId.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  GetSecretPathForTeamVariables({
    required this.id,
    required this.teamId,
  });
}

