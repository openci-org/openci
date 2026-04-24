part of 'default.dart';

class AcceptInvitationAndJoinTeamVariablesBuilder {
  String id;
  String teamId;

  final FirebaseDataConnect _dataConnect;
  AcceptInvitationAndJoinTeamVariablesBuilder(this._dataConnect, {required  this.id,required  this.teamId,});
  Deserializer<AcceptInvitationAndJoinTeamData> dataDeserializer = (dynamic json)  => AcceptInvitationAndJoinTeamData.fromJson(jsonDecode(json));
  Serializer<AcceptInvitationAndJoinTeamVariables> varsSerializer = (AcceptInvitationAndJoinTeamVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<AcceptInvitationAndJoinTeamData, AcceptInvitationAndJoinTeamVariables>> execute() {
    return ref().execute();
  }

  MutationRef<AcceptInvitationAndJoinTeamData, AcceptInvitationAndJoinTeamVariables> ref() {
    AcceptInvitationAndJoinTeamVariables vars= AcceptInvitationAndJoinTeamVariables(id: id,teamId: teamId,);
    return _dataConnect.mutation("AcceptInvitationAndJoinTeam", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class AcceptInvitationAndJoinTeamUserUpsert {
  final String id;
  AcceptInvitationAndJoinTeamUserUpsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final AcceptInvitationAndJoinTeamUserUpsert otherTyped = other as AcceptInvitationAndJoinTeamUserUpsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  AcceptInvitationAndJoinTeamUserUpsert({
    required this.id,
  });
}

@immutable
class AcceptInvitationAndJoinTeamInvitationUpdate {
  final String id;
  AcceptInvitationAndJoinTeamInvitationUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final AcceptInvitationAndJoinTeamInvitationUpdate otherTyped = other as AcceptInvitationAndJoinTeamInvitationUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  AcceptInvitationAndJoinTeamInvitationUpdate({
    required this.id,
  });
}

@immutable
class AcceptInvitationAndJoinTeamTeamMemberUpsert {
  final String teamId;
  final String userId;
  AcceptInvitationAndJoinTeamTeamMemberUpsert.fromJson(dynamic json):
  
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

    final AcceptInvitationAndJoinTeamTeamMemberUpsert otherTyped = other as AcceptInvitationAndJoinTeamTeamMemberUpsert;
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

  AcceptInvitationAndJoinTeamTeamMemberUpsert({
    required this.teamId,
    required this.userId,
  });
}

@immutable
class AcceptInvitationAndJoinTeamData {
  final AcceptInvitationAndJoinTeamUserUpsert user_upsert;
  final AcceptInvitationAndJoinTeamInvitationUpdate? invitation_update;
  final AcceptInvitationAndJoinTeamTeamMemberUpsert teamMember_upsert;
  AcceptInvitationAndJoinTeamData.fromJson(dynamic json):
  
  user_upsert = AcceptInvitationAndJoinTeamUserUpsert.fromJson(json['user_upsert']),
  invitation_update = json['invitation_update'] == null ? null : AcceptInvitationAndJoinTeamInvitationUpdate.fromJson(json['invitation_update']),
  teamMember_upsert = AcceptInvitationAndJoinTeamTeamMemberUpsert.fromJson(json['teamMember_upsert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final AcceptInvitationAndJoinTeamData otherTyped = other as AcceptInvitationAndJoinTeamData;
    return user_upsert == otherTyped.user_upsert && 
    invitation_update == otherTyped.invitation_update && 
    teamMember_upsert == otherTyped.teamMember_upsert;
    
  }
  @override
  int get hashCode => Object.hashAll([user_upsert.hashCode, invitation_update.hashCode, teamMember_upsert.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['user_upsert'] = user_upsert.toJson();
    if (invitation_update != null) {
      json['invitation_update'] = invitation_update!.toJson();
    }
    json['teamMember_upsert'] = teamMember_upsert.toJson();
    return json;
  }

  AcceptInvitationAndJoinTeamData({
    required this.user_upsert,
    this.invitation_update,
    required this.teamMember_upsert,
  });
}

@immutable
class AcceptInvitationAndJoinTeamVariables {
  final String id;
  final String teamId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  AcceptInvitationAndJoinTeamVariables.fromJson(Map<String, dynamic> json):
  
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

    final AcceptInvitationAndJoinTeamVariables otherTyped = other as AcceptInvitationAndJoinTeamVariables;
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

  AcceptInvitationAndJoinTeamVariables({
    required this.id,
    required this.teamId,
  });
}

