part of 'default.dart';

class FindExistingPendingInvitationVariablesBuilder {
  String email;
  String teamId;

  final FirebaseDataConnect _dataConnect;
  FindExistingPendingInvitationVariablesBuilder(this._dataConnect, {required  this.email,required  this.teamId,});
  Deserializer<FindExistingPendingInvitationData> dataDeserializer = (dynamic json)  => FindExistingPendingInvitationData.fromJson(jsonDecode(json));
  Serializer<FindExistingPendingInvitationVariables> varsSerializer = (FindExistingPendingInvitationVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<FindExistingPendingInvitationData, FindExistingPendingInvitationVariables>> execute() {
    return ref().execute();
  }

  QueryRef<FindExistingPendingInvitationData, FindExistingPendingInvitationVariables> ref() {
    FindExistingPendingInvitationVariables vars= FindExistingPendingInvitationVariables(email: email,teamId: teamId,);
    return _dataConnect.query("FindExistingPendingInvitation", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class FindExistingPendingInvitationInvitations {
  final String id;
  final String token;
  final Timestamp expiresAt;
  FindExistingPendingInvitationInvitations.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
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

    final FindExistingPendingInvitationInvitations otherTyped = other as FindExistingPendingInvitationInvitations;
    return id == otherTyped.id && 
    token == otherTyped.token && 
    expiresAt == otherTyped.expiresAt;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, token.hashCode, expiresAt.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['token'] = nativeToJson<String>(token);
    json['expiresAt'] = expiresAt.toJson();
    return json;
  }

  FindExistingPendingInvitationInvitations({
    required this.id,
    required this.token,
    required this.expiresAt,
  });
}

@immutable
class FindExistingPendingInvitationData {
  final List<FindExistingPendingInvitationInvitations> invitations;
  FindExistingPendingInvitationData.fromJson(dynamic json):
  
  invitations = (json['invitations'] as List<dynamic>)
        .map((e) => FindExistingPendingInvitationInvitations.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final FindExistingPendingInvitationData otherTyped = other as FindExistingPendingInvitationData;
    return invitations == otherTyped.invitations;
    
  }
  @override
  int get hashCode => invitations.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['invitations'] = invitations.map((e) => e.toJson()).toList();
    return json;
  }

  FindExistingPendingInvitationData({
    required this.invitations,
  });
}

@immutable
class FindExistingPendingInvitationVariables {
  final String email;
  final String teamId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  FindExistingPendingInvitationVariables.fromJson(Map<String, dynamic> json):
  
  email = nativeFromJson<String>(json['email']),
  teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final FindExistingPendingInvitationVariables otherTyped = other as FindExistingPendingInvitationVariables;
    return email == otherTyped.email && 
    teamId == otherTyped.teamId;
    
  }
  @override
  int get hashCode => Object.hashAll([email.hashCode, teamId.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['email'] = nativeToJson<String>(email);
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  FindExistingPendingInvitationVariables({
    required this.email,
    required this.teamId,
  });
}

