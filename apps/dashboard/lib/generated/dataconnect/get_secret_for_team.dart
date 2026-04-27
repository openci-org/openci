part of 'default.dart';

class GetSecretForTeamVariablesBuilder {
  String id;
  String teamId;

  final FirebaseDataConnect _dataConnect;
  GetSecretForTeamVariablesBuilder(this._dataConnect, {required  this.id,required  this.teamId,});
  Deserializer<GetSecretForTeamData> dataDeserializer = (dynamic json)  => GetSecretForTeamData.fromJson(jsonDecode(json));
  Serializer<GetSecretForTeamVariables> varsSerializer = (GetSecretForTeamVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetSecretForTeamData, GetSecretForTeamVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetSecretForTeamData, GetSecretForTeamVariables> ref() {
    GetSecretForTeamVariables vars= GetSecretForTeamVariables(id: id,teamId: teamId,);
    return _dataConnect.query("GetSecretForTeam", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetSecretForTeamTeamMember {
  final String teamId;
  GetSecretForTeamTeamMember.fromJson(dynamic json):
  
  teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetSecretForTeamTeamMember otherTyped = other as GetSecretForTeamTeamMember;
    return teamId == otherTyped.teamId;
    
  }
  @override
  int get hashCode => teamId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  GetSecretForTeamTeamMember({
    required this.teamId,
  });
}

@immutable
class GetSecretForTeamSecret {
  final String id;
  final String name;
  final String teamId;
  GetSecretForTeamSecret.fromJson(dynamic json):
  
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

    final GetSecretForTeamSecret otherTyped = other as GetSecretForTeamSecret;
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

  GetSecretForTeamSecret({
    required this.id,
    required this.name,
    required this.teamId,
  });
}

@immutable
class GetSecretForTeamData {
  final GetSecretForTeamTeamMember? teamMember;
  final GetSecretForTeamSecret? secret;
  GetSecretForTeamData.fromJson(dynamic json):
  
  teamMember = json['teamMember'] == null ? null : GetSecretForTeamTeamMember.fromJson(json['teamMember']),
  secret = json['secret'] == null ? null : GetSecretForTeamSecret.fromJson(json['secret']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetSecretForTeamData otherTyped = other as GetSecretForTeamData;
    return teamMember == otherTyped.teamMember && 
    secret == otherTyped.secret;
    
  }
  @override
  int get hashCode => Object.hashAll([teamMember.hashCode, secret.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (teamMember != null) {
      json['teamMember'] = teamMember!.toJson();
    }
    if (secret != null) {
      json['secret'] = secret!.toJson();
    }
    return json;
  }

  GetSecretForTeamData({
    this.teamMember,
    this.secret,
  });
}

@immutable
class GetSecretForTeamVariables {
  final String id;
  final String teamId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetSecretForTeamVariables.fromJson(Map<String, dynamic> json):
  
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

    final GetSecretForTeamVariables otherTyped = other as GetSecretForTeamVariables;
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

  GetSecretForTeamVariables({
    required this.id,
    required this.teamId,
  });
}

