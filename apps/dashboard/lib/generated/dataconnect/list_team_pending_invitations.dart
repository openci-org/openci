part of 'default.dart';

class ListTeamPendingInvitationsVariablesBuilder {
  String teamId;

  final FirebaseDataConnect _dataConnect;
  ListTeamPendingInvitationsVariablesBuilder(this._dataConnect, {required  this.teamId,});
  Deserializer<ListTeamPendingInvitationsData> dataDeserializer = (dynamic json)  => ListTeamPendingInvitationsData.fromJson(jsonDecode(json));
  Serializer<ListTeamPendingInvitationsVariables> varsSerializer = (ListTeamPendingInvitationsVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<ListTeamPendingInvitationsData, ListTeamPendingInvitationsVariables>> execute() {
    return ref().execute();
  }

  QueryRef<ListTeamPendingInvitationsData, ListTeamPendingInvitationsVariables> ref() {
    ListTeamPendingInvitationsVariables vars= ListTeamPendingInvitationsVariables(teamId: teamId,);
    return _dataConnect.query("ListTeamPendingInvitations", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class ListTeamPendingInvitationsTeamMember {
  final String teamId;
  ListTeamPendingInvitationsTeamMember.fromJson(dynamic json):
  
  teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListTeamPendingInvitationsTeamMember otherTyped = other as ListTeamPendingInvitationsTeamMember;
    return teamId == otherTyped.teamId;
    
  }
  @override
  int get hashCode => teamId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  ListTeamPendingInvitationsTeamMember({
    required this.teamId,
  });
}

@immutable
class ListTeamPendingInvitationsInvitations {
  final String id;
  final String email;
  final Timestamp createdAt;
  final Timestamp expiresAt;
  final ListTeamPendingInvitationsInvitationsInvitedBy? invitedBy;
  ListTeamPendingInvitationsInvitations.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  email = nativeFromJson<String>(json['email']),
  createdAt = Timestamp.fromJson(json['createdAt']),
  expiresAt = Timestamp.fromJson(json['expiresAt']),
  invitedBy = json['invitedBy'] == null ? null : ListTeamPendingInvitationsInvitationsInvitedBy.fromJson(json['invitedBy']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListTeamPendingInvitationsInvitations otherTyped = other as ListTeamPendingInvitationsInvitations;
    return id == otherTyped.id && 
    email == otherTyped.email && 
    createdAt == otherTyped.createdAt && 
    expiresAt == otherTyped.expiresAt && 
    invitedBy == otherTyped.invitedBy;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, email.hashCode, createdAt.hashCode, expiresAt.hashCode, invitedBy.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['email'] = nativeToJson<String>(email);
    json['createdAt'] = createdAt.toJson();
    json['expiresAt'] = expiresAt.toJson();
    if (invitedBy != null) {
      json['invitedBy'] = invitedBy!.toJson();
    }
    return json;
  }

  ListTeamPendingInvitationsInvitations({
    required this.id,
    required this.email,
    required this.createdAt,
    required this.expiresAt,
    this.invitedBy,
  });
}

@immutable
class ListTeamPendingInvitationsInvitationsInvitedBy {
  final String id;
  final String email;
  ListTeamPendingInvitationsInvitationsInvitedBy.fromJson(dynamic json):
  
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

    final ListTeamPendingInvitationsInvitationsInvitedBy otherTyped = other as ListTeamPendingInvitationsInvitationsInvitedBy;
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

  ListTeamPendingInvitationsInvitationsInvitedBy({
    required this.id,
    required this.email,
  });
}

@immutable
class ListTeamPendingInvitationsData {
  final ListTeamPendingInvitationsTeamMember? teamMember;
  final List<ListTeamPendingInvitationsInvitations> invitations;
  ListTeamPendingInvitationsData.fromJson(dynamic json):
  
  teamMember = json['teamMember'] == null ? null : ListTeamPendingInvitationsTeamMember.fromJson(json['teamMember']),
  invitations = (json['invitations'] as List<dynamic>)
        .map((e) => ListTeamPendingInvitationsInvitations.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListTeamPendingInvitationsData otherTyped = other as ListTeamPendingInvitationsData;
    return teamMember == otherTyped.teamMember && 
    invitations == otherTyped.invitations;
    
  }
  @override
  int get hashCode => Object.hashAll([teamMember.hashCode, invitations.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (teamMember != null) {
      json['teamMember'] = teamMember!.toJson();
    }
    json['invitations'] = invitations.map((e) => e.toJson()).toList();
    return json;
  }

  ListTeamPendingInvitationsData({
    this.teamMember,
    required this.invitations,
  });
}

@immutable
class ListTeamPendingInvitationsVariables {
  final String teamId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ListTeamPendingInvitationsVariables.fromJson(Map<String, dynamic> json):
  
  teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListTeamPendingInvitationsVariables otherTyped = other as ListTeamPendingInvitationsVariables;
    return teamId == otherTyped.teamId;
    
  }
  @override
  int get hashCode => teamId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  ListTeamPendingInvitationsVariables({
    required this.teamId,
  });
}

