part of 'default.dart';

class ListSecretsForTeamVariablesBuilder {
  String teamId;

  final FirebaseDataConnect _dataConnect;
  ListSecretsForTeamVariablesBuilder(this._dataConnect, {required  this.teamId,});
  Deserializer<ListSecretsForTeamData> dataDeserializer = (dynamic json)  => ListSecretsForTeamData.fromJson(jsonDecode(json));
  Serializer<ListSecretsForTeamVariables> varsSerializer = (ListSecretsForTeamVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<ListSecretsForTeamData, ListSecretsForTeamVariables>> execute() {
    return ref().execute();
  }

  QueryRef<ListSecretsForTeamData, ListSecretsForTeamVariables> ref() {
    ListSecretsForTeamVariables vars= ListSecretsForTeamVariables(teamId: teamId,);
    return _dataConnect.query("ListSecretsForTeam", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class ListSecretsForTeamTeamMember {
  final String teamId;
  ListSecretsForTeamTeamMember.fromJson(dynamic json):
  
  teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListSecretsForTeamTeamMember otherTyped = other as ListSecretsForTeamTeamMember;
    return teamId == otherTyped.teamId;
    
  }
  @override
  int get hashCode => teamId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  ListSecretsForTeamTeamMember({
    required this.teamId,
  });
}

@immutable
class ListSecretsForTeamSecrets {
  final String id;
  final String name;
  final String teamId;
  final String? pathToSecret;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  ListSecretsForTeamSecrets.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  name = nativeFromJson<String>(json['name']),
  teamId = nativeFromJson<String>(json['teamId']),
  pathToSecret = json['pathToSecret'] == null ? null : nativeFromJson<String>(json['pathToSecret']),
  createdAt = Timestamp.fromJson(json['createdAt']),
  updatedAt = Timestamp.fromJson(json['updatedAt']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListSecretsForTeamSecrets otherTyped = other as ListSecretsForTeamSecrets;
    return id == otherTyped.id && 
    name == otherTyped.name && 
    teamId == otherTyped.teamId && 
    pathToSecret == otherTyped.pathToSecret && 
    createdAt == otherTyped.createdAt && 
    updatedAt == otherTyped.updatedAt;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, name.hashCode, teamId.hashCode, pathToSecret.hashCode, createdAt.hashCode, updatedAt.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    json['teamId'] = nativeToJson<String>(teamId);
    if (pathToSecret != null) {
      json['pathToSecret'] = nativeToJson<String?>(pathToSecret);
    }
    json['createdAt'] = createdAt.toJson();
    json['updatedAt'] = updatedAt.toJson();
    return json;
  }

  ListSecretsForTeamSecrets({
    required this.id,
    required this.name,
    required this.teamId,
    this.pathToSecret,
    required this.createdAt,
    required this.updatedAt,
  });
}

@immutable
class ListSecretsForTeamData {
  final ListSecretsForTeamTeamMember? teamMember;
  final List<ListSecretsForTeamSecrets> secrets;
  ListSecretsForTeamData.fromJson(dynamic json):
  
  teamMember = json['teamMember'] == null ? null : ListSecretsForTeamTeamMember.fromJson(json['teamMember']),
  secrets = (json['secrets'] as List<dynamic>)
        .map((e) => ListSecretsForTeamSecrets.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListSecretsForTeamData otherTyped = other as ListSecretsForTeamData;
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

  ListSecretsForTeamData({
    this.teamMember,
    required this.secrets,
  });
}

@immutable
class ListSecretsForTeamVariables {
  final String teamId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ListSecretsForTeamVariables.fromJson(Map<String, dynamic> json):
  
  teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListSecretsForTeamVariables otherTyped = other as ListSecretsForTeamVariables;
    return teamId == otherTyped.teamId;
    
  }
  @override
  int get hashCode => teamId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  ListSecretsForTeamVariables({
    required this.teamId,
  });
}

