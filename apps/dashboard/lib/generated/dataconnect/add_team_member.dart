part of 'default.dart';

class AddTeamMemberVariablesBuilder {
  String teamId;
  String userId;
  String email;

  final FirebaseDataConnect _dataConnect;
  AddTeamMemberVariablesBuilder(this._dataConnect, {required  this.teamId,required  this.userId,required  this.email,});
  Deserializer<AddTeamMemberData> dataDeserializer = (dynamic json)  => AddTeamMemberData.fromJson(jsonDecode(json));
  Serializer<AddTeamMemberVariables> varsSerializer = (AddTeamMemberVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<AddTeamMemberData, AddTeamMemberVariables>> execute() {
    return ref().execute();
  }

  MutationRef<AddTeamMemberData, AddTeamMemberVariables> ref() {
    AddTeamMemberVariables vars= AddTeamMemberVariables(teamId: teamId,userId: userId,email: email,);
    return _dataConnect.mutation("AddTeamMember", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class AddTeamMemberUserUpsert {
  final String id;
  AddTeamMemberUserUpsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final AddTeamMemberUserUpsert otherTyped = other as AddTeamMemberUserUpsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  AddTeamMemberUserUpsert({
    required this.id,
  });
}

@immutable
class AddTeamMemberTeamMemberUpsert {
  final String teamId;
  final String userId;
  AddTeamMemberTeamMemberUpsert.fromJson(dynamic json):
  
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

    final AddTeamMemberTeamMemberUpsert otherTyped = other as AddTeamMemberTeamMemberUpsert;
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

  AddTeamMemberTeamMemberUpsert({
    required this.teamId,
    required this.userId,
  });
}

@immutable
class AddTeamMemberData {
  final AddTeamMemberUserUpsert user_upsert;
  final AddTeamMemberTeamMemberUpsert teamMember_upsert;
  AddTeamMemberData.fromJson(dynamic json):
  
  user_upsert = AddTeamMemberUserUpsert.fromJson(json['user_upsert']),
  teamMember_upsert = AddTeamMemberTeamMemberUpsert.fromJson(json['teamMember_upsert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final AddTeamMemberData otherTyped = other as AddTeamMemberData;
    return user_upsert == otherTyped.user_upsert && 
    teamMember_upsert == otherTyped.teamMember_upsert;
    
  }
  @override
  int get hashCode => Object.hashAll([user_upsert.hashCode, teamMember_upsert.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['user_upsert'] = user_upsert.toJson();
    json['teamMember_upsert'] = teamMember_upsert.toJson();
    return json;
  }

  AddTeamMemberData({
    required this.user_upsert,
    required this.teamMember_upsert,
  });
}

@immutable
class AddTeamMemberVariables {
  final String teamId;
  final String userId;
  final String email;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  AddTeamMemberVariables.fromJson(Map<String, dynamic> json):
  
  teamId = nativeFromJson<String>(json['teamId']),
  userId = nativeFromJson<String>(json['userId']),
  email = nativeFromJson<String>(json['email']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final AddTeamMemberVariables otherTyped = other as AddTeamMemberVariables;
    return teamId == otherTyped.teamId && 
    userId == otherTyped.userId && 
    email == otherTyped.email;
    
  }
  @override
  int get hashCode => Object.hashAll([teamId.hashCode, userId.hashCode, email.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    json['userId'] = nativeToJson<String>(userId);
    json['email'] = nativeToJson<String>(email);
    return json;
  }

  AddTeamMemberVariables({
    required this.teamId,
    required this.userId,
    required this.email,
  });
}

