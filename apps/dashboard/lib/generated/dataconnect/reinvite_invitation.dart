part of 'default.dart';

class ReinviteInvitationVariablesBuilder {
  String id;
  String teamId;
  String token;
  Timestamp expiresAt;

  final FirebaseDataConnect _dataConnect;
  ReinviteInvitationVariablesBuilder(this._dataConnect, {required  this.id,required  this.teamId,required  this.token,required  this.expiresAt,});
  Deserializer<ReinviteInvitationData> dataDeserializer = (dynamic json)  => ReinviteInvitationData.fromJson(jsonDecode(json));
  Serializer<ReinviteInvitationVariables> varsSerializer = (ReinviteInvitationVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<ReinviteInvitationData, ReinviteInvitationVariables>> execute() {
    return ref().execute();
  }

  MutationRef<ReinviteInvitationData, ReinviteInvitationVariables> ref() {
    ReinviteInvitationVariables vars= ReinviteInvitationVariables(id: id,teamId: teamId,token: token,expiresAt: expiresAt,);
    return _dataConnect.mutation("ReinviteInvitation", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class ReinviteInvitationInvitationUpdate {
  final String id;
  ReinviteInvitationInvitationUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ReinviteInvitationInvitationUpdate otherTyped = other as ReinviteInvitationInvitationUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  ReinviteInvitationInvitationUpdate({
    required this.id,
  });
}

@immutable
class ReinviteInvitationData {
  final ReinviteInvitationInvitationUpdate? invitation_update;
  ReinviteInvitationData.fromJson(dynamic json):
  
  invitation_update = json['invitation_update'] == null ? null : ReinviteInvitationInvitationUpdate.fromJson(json['invitation_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ReinviteInvitationData otherTyped = other as ReinviteInvitationData;
    return invitation_update == otherTyped.invitation_update;
    
  }
  @override
  int get hashCode => invitation_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (invitation_update != null) {
      json['invitation_update'] = invitation_update!.toJson();
    }
    return json;
  }

  ReinviteInvitationData({
    this.invitation_update,
  });
}

@immutable
class ReinviteInvitationVariables {
  final String id;
  final String teamId;
  final String token;
  final Timestamp expiresAt;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ReinviteInvitationVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  teamId = nativeFromJson<String>(json['teamId']),
  token = nativeFromJson<String>(json['token']),
  expiresAt = Timestamp.fromJson(json['expiresAt']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ReinviteInvitationVariables otherTyped = other as ReinviteInvitationVariables;
    return id == otherTyped.id && 
    teamId == otherTyped.teamId && 
    token == otherTyped.token && 
    expiresAt == otherTyped.expiresAt;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, teamId.hashCode, token.hashCode, expiresAt.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['teamId'] = nativeToJson<String>(teamId);
    json['token'] = nativeToJson<String>(token);
    json['expiresAt'] = expiresAt.toJson();
    return json;
  }

  ReinviteInvitationVariables({
    required this.id,
    required this.teamId,
    required this.token,
    required this.expiresAt,
  });
}

