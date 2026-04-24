part of 'default.dart';

class GetInvitationByTokenVariablesBuilder {
  String token;

  final FirebaseDataConnect _dataConnect;
  GetInvitationByTokenVariablesBuilder(this._dataConnect, {required  this.token,});
  Deserializer<GetInvitationByTokenData> dataDeserializer = (dynamic json)  => GetInvitationByTokenData.fromJson(jsonDecode(json));
  Serializer<GetInvitationByTokenVariables> varsSerializer = (GetInvitationByTokenVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetInvitationByTokenData, GetInvitationByTokenVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetInvitationByTokenData, GetInvitationByTokenVariables> ref() {
    GetInvitationByTokenVariables vars= GetInvitationByTokenVariables(token: token,);
    return _dataConnect.query("GetInvitationByToken", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetInvitationByTokenInvitations {
  final String id;
  final String email;
  final EnumValue<InvitationStatus> status;
  final Timestamp expiresAt;
  final Timestamp createdAt;
  final String teamNameSnapshot;
  final GetInvitationByTokenInvitationsTeam team;
  final GetInvitationByTokenInvitationsInvitedBy? invitedBy;
  GetInvitationByTokenInvitations.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  email = nativeFromJson<String>(json['email']),
  status = invitationStatusDeserializer(json['status']),
  expiresAt = Timestamp.fromJson(json['expiresAt']),
  createdAt = Timestamp.fromJson(json['createdAt']),
  teamNameSnapshot = nativeFromJson<String>(json['teamNameSnapshot']),
  team = GetInvitationByTokenInvitationsTeam.fromJson(json['team']),
  invitedBy = json['invitedBy'] == null ? null : GetInvitationByTokenInvitationsInvitedBy.fromJson(json['invitedBy']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetInvitationByTokenInvitations otherTyped = other as GetInvitationByTokenInvitations;
    return id == otherTyped.id && 
    email == otherTyped.email && 
    status == otherTyped.status && 
    expiresAt == otherTyped.expiresAt && 
    createdAt == otherTyped.createdAt && 
    teamNameSnapshot == otherTyped.teamNameSnapshot && 
    team == otherTyped.team && 
    invitedBy == otherTyped.invitedBy;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, email.hashCode, status.hashCode, expiresAt.hashCode, createdAt.hashCode, teamNameSnapshot.hashCode, team.hashCode, invitedBy.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['email'] = nativeToJson<String>(email);
    json['status'] = 
    invitationStatusSerializer(status)
    ;
    json['expiresAt'] = expiresAt.toJson();
    json['createdAt'] = createdAt.toJson();
    json['teamNameSnapshot'] = nativeToJson<String>(teamNameSnapshot);
    json['team'] = team.toJson();
    if (invitedBy != null) {
      json['invitedBy'] = invitedBy!.toJson();
    }
    return json;
  }

  GetInvitationByTokenInvitations({
    required this.id,
    required this.email,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
    required this.teamNameSnapshot,
    required this.team,
    this.invitedBy,
  });
}

@immutable
class GetInvitationByTokenInvitationsTeam {
  final String id;
  final String name;
  GetInvitationByTokenInvitationsTeam.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  name = nativeFromJson<String>(json['name']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetInvitationByTokenInvitationsTeam otherTyped = other as GetInvitationByTokenInvitationsTeam;
    return id == otherTyped.id && 
    name == otherTyped.name;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, name.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    return json;
  }

  GetInvitationByTokenInvitationsTeam({
    required this.id,
    required this.name,
  });
}

@immutable
class GetInvitationByTokenInvitationsInvitedBy {
  final String id;
  final String email;
  GetInvitationByTokenInvitationsInvitedBy.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  email = nativeFromJson<String>(json['email']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetInvitationByTokenInvitationsInvitedBy otherTyped = other as GetInvitationByTokenInvitationsInvitedBy;
    return id == otherTyped.id && 
    email == otherTyped.email;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, email.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['email'] = nativeToJson<String>(email);
    return json;
  }

  GetInvitationByTokenInvitationsInvitedBy({
    required this.id,
    required this.email,
  });
}

@immutable
class GetInvitationByTokenData {
  final List<GetInvitationByTokenInvitations> invitations;
  GetInvitationByTokenData.fromJson(dynamic json):
  
  invitations = (json['invitations'] as List<dynamic>)
        .map((e) => GetInvitationByTokenInvitations.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetInvitationByTokenData otherTyped = other as GetInvitationByTokenData;
    return invitations == otherTyped.invitations;
    
  }
  @override
  int get hashCode => invitations.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['invitations'] = invitations.map((e) => e.toJson()).toList();
    return json;
  }

  GetInvitationByTokenData({
    required this.invitations,
  });
}

@immutable
class GetInvitationByTokenVariables {
  final String token;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetInvitationByTokenVariables.fromJson(Map<String, dynamic> json):
  
  token = nativeFromJson<String>(json['token']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetInvitationByTokenVariables otherTyped = other as GetInvitationByTokenVariables;
    return token == otherTyped.token;
    
  }
  @override
  int get hashCode => token.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['token'] = nativeToJson<String>(token);
    return json;
  }

  GetInvitationByTokenVariables({
    required this.token,
  });
}

