part of 'default.dart';

class CreateInvitationVariablesBuilder {
  String email;
  String teamId;
  String teamNameSnapshot;
  String token;
  Timestamp expiresAt;

  final FirebaseDataConnect _dataConnect;
  CreateInvitationVariablesBuilder(this._dataConnect, {required  this.email,required  this.teamId,required  this.teamNameSnapshot,required  this.token,required  this.expiresAt,});
  Deserializer<CreateInvitationData> dataDeserializer = (dynamic json)  => CreateInvitationData.fromJson(jsonDecode(json));
  Serializer<CreateInvitationVariables> varsSerializer = (CreateInvitationVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateInvitationData, CreateInvitationVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateInvitationData, CreateInvitationVariables> ref() {
    CreateInvitationVariables vars= CreateInvitationVariables(email: email,teamId: teamId,teamNameSnapshot: teamNameSnapshot,token: token,expiresAt: expiresAt,);
    return _dataConnect.mutation("CreateInvitation", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateInvitationInvitationInsert {
  final String id;
  CreateInvitationInvitationInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateInvitationInvitationInsert otherTyped = other as CreateInvitationInvitationInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateInvitationInvitationInsert({
    required this.id,
  });
}

@immutable
class CreateInvitationData {
  final CreateInvitationInvitationInsert invitation_insert;
  CreateInvitationData.fromJson(dynamic json):
  
  invitation_insert = CreateInvitationInvitationInsert.fromJson(json['invitation_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateInvitationData otherTyped = other as CreateInvitationData;
    return invitation_insert == otherTyped.invitation_insert;
    
  }
  @override
  int get hashCode => invitation_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['invitation_insert'] = invitation_insert.toJson();
    return json;
  }

  CreateInvitationData({
    required this.invitation_insert,
  });
}

@immutable
class CreateInvitationVariables {
  final String email;
  final String teamId;
  final String teamNameSnapshot;
  final String token;
  final Timestamp expiresAt;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateInvitationVariables.fromJson(Map<String, dynamic> json):
  
  email = nativeFromJson<String>(json['email']),
  teamId = nativeFromJson<String>(json['teamId']),
  teamNameSnapshot = nativeFromJson<String>(json['teamNameSnapshot']),
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

    final CreateInvitationVariables otherTyped = other as CreateInvitationVariables;
    return email == otherTyped.email && 
    teamId == otherTyped.teamId && 
    teamNameSnapshot == otherTyped.teamNameSnapshot && 
    token == otherTyped.token && 
    expiresAt == otherTyped.expiresAt;
    
  }
  @override
  int get hashCode => Object.hashAll([email.hashCode, teamId.hashCode, teamNameSnapshot.hashCode, token.hashCode, expiresAt.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['email'] = nativeToJson<String>(email);
    json['teamId'] = nativeToJson<String>(teamId);
    json['teamNameSnapshot'] = nativeToJson<String>(teamNameSnapshot);
    json['token'] = nativeToJson<String>(token);
    json['expiresAt'] = expiresAt.toJson();
    return json;
  }

  CreateInvitationVariables({
    required this.email,
    required this.teamId,
    required this.teamNameSnapshot,
    required this.token,
    required this.expiresAt,
  });
}

