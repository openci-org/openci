part of 'generated.dart';

class CreateUserWithDefaultTeamVariablesBuilder {
  Optional<String> _teamName = Optional.optional(nativeFromJson, nativeToJson);
  String uid;

  final FirebaseDataConnect _dataConnect;
  CreateUserWithDefaultTeamVariablesBuilder teamName(String t) {
   _teamName.value = t;
   return this;
  }

  CreateUserWithDefaultTeamVariablesBuilder(this._dataConnect, {required  this.uid,});
  Deserializer<CreateUserWithDefaultTeamData> dataDeserializer = (dynamic json)  => CreateUserWithDefaultTeamData.fromJson(jsonDecode(json));
  Serializer<CreateUserWithDefaultTeamVariables> varsSerializer = (CreateUserWithDefaultTeamVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateUserWithDefaultTeamData, CreateUserWithDefaultTeamVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateUserWithDefaultTeamData, CreateUserWithDefaultTeamVariables> ref() {
    CreateUserWithDefaultTeamVariables vars= CreateUserWithDefaultTeamVariables(teamName: _teamName,uid: uid,);
    return _dataConnect.mutation("CreateUserWithDefaultTeam", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateUserWithDefaultTeamTeamInsert {
  final String id;
  CreateUserWithDefaultTeamTeamInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateUserWithDefaultTeamTeamInsert otherTyped = other as CreateUserWithDefaultTeamTeamInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateUserWithDefaultTeamTeamInsert({
    required this.id,
  });
}

@immutable
class CreateUserWithDefaultTeamUserInsert {
  final String id;
  CreateUserWithDefaultTeamUserInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateUserWithDefaultTeamUserInsert otherTyped = other as CreateUserWithDefaultTeamUserInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateUserWithDefaultTeamUserInsert({
    required this.id,
  });
}

@immutable
class CreateUserWithDefaultTeamData {
  final CreateUserWithDefaultTeamTeamInsert team_insert;
  final CreateUserWithDefaultTeamUserInsert user_insert;
  CreateUserWithDefaultTeamData.fromJson(dynamic json):
  
  team_insert = CreateUserWithDefaultTeamTeamInsert.fromJson(json['team_insert']),
  user_insert = CreateUserWithDefaultTeamUserInsert.fromJson(json['user_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateUserWithDefaultTeamData otherTyped = other as CreateUserWithDefaultTeamData;
    return team_insert == otherTyped.team_insert && 
    user_insert == otherTyped.user_insert;
    
  }
  @override
  int get hashCode => Object.hashAll([team_insert.hashCode, user_insert.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['team_insert'] = team_insert.toJson();
    json['user_insert'] = user_insert.toJson();
    return json;
  }

  CreateUserWithDefaultTeamData({
    required this.team_insert,
    required this.user_insert,
  });
}

@immutable
class CreateUserWithDefaultTeamVariables {
  late final Optional<String>teamName;
  final String uid;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateUserWithDefaultTeamVariables.fromJson(Map<String, dynamic> json):
  
  uid = nativeFromJson<String>(json['uid']) {
  
  
    teamName = Optional.optional(nativeFromJson, nativeToJson);
    teamName.value = json['teamName'] == null ? null : nativeFromJson<String>(json['teamName']);
  
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateUserWithDefaultTeamVariables otherTyped = other as CreateUserWithDefaultTeamVariables;
    return teamName == otherTyped.teamName && 
    uid == otherTyped.uid;
    
  }
  @override
  int get hashCode => Object.hashAll([teamName.hashCode, uid.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if(teamName.state == OptionalState.set) {
      json['teamName'] = teamName.toJson();
    }
    json['uid'] = nativeToJson<String>(uid);
    return json;
  }

  CreateUserWithDefaultTeamVariables({
    required this.teamName,
    required this.uid,
  });
}

