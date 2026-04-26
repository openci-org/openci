part of 'default.dart';

class CreateTeamForCurrentUserVariablesBuilder {
  String id;
  String name;
  String userId;

  final FirebaseDataConnect _dataConnect;
  CreateTeamForCurrentUserVariablesBuilder(this._dataConnect, {required  this.id,required  this.name,required  this.userId,});
  Deserializer<CreateTeamForCurrentUserData> dataDeserializer = (dynamic json)  => CreateTeamForCurrentUserData.fromJson(jsonDecode(json));
  Serializer<CreateTeamForCurrentUserVariables> varsSerializer = (CreateTeamForCurrentUserVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateTeamForCurrentUserData, CreateTeamForCurrentUserVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateTeamForCurrentUserData, CreateTeamForCurrentUserVariables> ref() {
    CreateTeamForCurrentUserVariables vars= CreateTeamForCurrentUserVariables(id: id,name: name,userId: userId,);
    return _dataConnect.mutation("CreateTeamForCurrentUser", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateTeamForCurrentUserUserUpsert {
  final String id;
  CreateTeamForCurrentUserUserUpsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateTeamForCurrentUserUserUpsert otherTyped = other as CreateTeamForCurrentUserUserUpsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateTeamForCurrentUserUserUpsert({
    required this.id,
  });
}

@immutable
class CreateTeamForCurrentUserTeamInsert {
  final String id;
  CreateTeamForCurrentUserTeamInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateTeamForCurrentUserTeamInsert otherTyped = other as CreateTeamForCurrentUserTeamInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateTeamForCurrentUserTeamInsert({
    required this.id,
  });
}

@immutable
class CreateTeamForCurrentUserTeamMemberUpsert {
  final String teamId;
  final String userId;
  CreateTeamForCurrentUserTeamMemberUpsert.fromJson(dynamic json):
  
  teamId = nativeFromJson<String>(json['teamId']),
  userId = nativeFromJson<String>(json['userId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateTeamForCurrentUserTeamMemberUpsert otherTyped = other as CreateTeamForCurrentUserTeamMemberUpsert;
    return teamId == otherTyped.teamId && 
    userId == otherTyped.userId;
    
  }
  @override
  int get hashCode => Object.hashAll([teamId.hashCode, userId.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['userId'] = nativeToJson<String>(userId);
    return json;
  }

  CreateTeamForCurrentUserTeamMemberUpsert({
    required this.teamId,
    required this.userId,
  });
}

@immutable
class CreateTeamForCurrentUserData {
  final CreateTeamForCurrentUserUserUpsert user_upsert;
  final CreateTeamForCurrentUserTeamInsert team_insert;
  final CreateTeamForCurrentUserTeamMemberUpsert teamMember_upsert;
  CreateTeamForCurrentUserData.fromJson(dynamic json):
  
  user_upsert = CreateTeamForCurrentUserUserUpsert.fromJson(json['user_upsert']),
  team_insert = CreateTeamForCurrentUserTeamInsert.fromJson(json['team_insert']),
  teamMember_upsert = CreateTeamForCurrentUserTeamMemberUpsert.fromJson(json['teamMember_upsert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateTeamForCurrentUserData otherTyped = other as CreateTeamForCurrentUserData;
    return user_upsert == otherTyped.user_upsert && 
    team_insert == otherTyped.team_insert && 
    teamMember_upsert == otherTyped.teamMember_upsert;
    
  }
  @override
  int get hashCode => Object.hashAll([user_upsert.hashCode, team_insert.hashCode, teamMember_upsert.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['user_upsert'] = user_upsert.toJson();
    json['team_insert'] = team_insert.toJson();
    json['teamMember_upsert'] = teamMember_upsert.toJson();
    return json;
  }

  CreateTeamForCurrentUserData({
    required this.user_upsert,
    required this.team_insert,
    required this.teamMember_upsert,
  });
}

@immutable
class CreateTeamForCurrentUserVariables {
  final String id;
  final String name;
  final String userId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateTeamForCurrentUserVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  name = nativeFromJson<String>(json['name']),
  userId = nativeFromJson<String>(json['userId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateTeamForCurrentUserVariables otherTyped = other as CreateTeamForCurrentUserVariables;
    return id == otherTyped.id && 
    name == otherTyped.name && 
    userId == otherTyped.userId;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, name.hashCode, userId.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    json['userId'] = nativeToJson<String>(userId);
    return json;
  }

  CreateTeamForCurrentUserVariables({
    required this.id,
    required this.name,
    required this.userId,
  });
}

