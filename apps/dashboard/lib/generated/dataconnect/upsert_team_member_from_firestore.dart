part of 'default.dart';

class UpsertTeamMemberFromFirestoreVariablesBuilder {
  String teamId;
  String userId;
  String email;

  final FirebaseDataConnect _dataConnect;
  UpsertTeamMemberFromFirestoreVariablesBuilder(this._dataConnect, {required  this.teamId,required  this.userId,required  this.email,});
  Deserializer<UpsertTeamMemberFromFirestoreData> dataDeserializer = (dynamic json)  => UpsertTeamMemberFromFirestoreData.fromJson(jsonDecode(json));
  Serializer<UpsertTeamMemberFromFirestoreVariables> varsSerializer = (UpsertTeamMemberFromFirestoreVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpsertTeamMemberFromFirestoreData, UpsertTeamMemberFromFirestoreVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpsertTeamMemberFromFirestoreData, UpsertTeamMemberFromFirestoreVariables> ref() {
    UpsertTeamMemberFromFirestoreVariables vars= UpsertTeamMemberFromFirestoreVariables(teamId: teamId,userId: userId,email: email,);
    return _dataConnect.mutation("UpsertTeamMemberFromFirestore", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpsertTeamMemberFromFirestoreUserUpsert {
  final String id;
  UpsertTeamMemberFromFirestoreUserUpsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertTeamMemberFromFirestoreUserUpsert otherTyped = other as UpsertTeamMemberFromFirestoreUserUpsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpsertTeamMemberFromFirestoreUserUpsert({
    required this.id,
  });
}

@immutable
class UpsertTeamMemberFromFirestoreTeamMemberUpsert {
  final String teamId;
  final String userId;
  UpsertTeamMemberFromFirestoreTeamMemberUpsert.fromJson(dynamic json):
  
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

    final UpsertTeamMemberFromFirestoreTeamMemberUpsert otherTyped = other as UpsertTeamMemberFromFirestoreTeamMemberUpsert;
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

  UpsertTeamMemberFromFirestoreTeamMemberUpsert({
    required this.teamId,
    required this.userId,
  });
}

@immutable
class UpsertTeamMemberFromFirestoreData {
  final UpsertTeamMemberFromFirestoreUserUpsert user_upsert;
  final UpsertTeamMemberFromFirestoreTeamMemberUpsert teamMember_upsert;
  UpsertTeamMemberFromFirestoreData.fromJson(dynamic json):
  
  user_upsert = UpsertTeamMemberFromFirestoreUserUpsert.fromJson(json['user_upsert']),
  teamMember_upsert = UpsertTeamMemberFromFirestoreTeamMemberUpsert.fromJson(json['teamMember_upsert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertTeamMemberFromFirestoreData otherTyped = other as UpsertTeamMemberFromFirestoreData;
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

  UpsertTeamMemberFromFirestoreData({
    required this.user_upsert,
    required this.teamMember_upsert,
  });
}

@immutable
class UpsertTeamMemberFromFirestoreVariables {
  final String teamId;
  final String userId;
  final String email;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpsertTeamMemberFromFirestoreVariables.fromJson(Map<String, dynamic> json):
  
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

    final UpsertTeamMemberFromFirestoreVariables otherTyped = other as UpsertTeamMemberFromFirestoreVariables;
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

  UpsertTeamMemberFromFirestoreVariables({
    required this.teamId,
    required this.userId,
    required this.email,
  });
}

