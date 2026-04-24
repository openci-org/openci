part of 'default.dart';

class ListMyPendingInvitationsVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListMyPendingInvitationsVariablesBuilder(this._dataConnect, );
  Deserializer<ListMyPendingInvitationsData> dataDeserializer = (dynamic json)  => ListMyPendingInvitationsData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListMyPendingInvitationsData, void>> execute() {
    return ref().execute();
  }

  QueryRef<ListMyPendingInvitationsData, void> ref() {
    
    return _dataConnect.query("ListMyPendingInvitations", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListMyPendingInvitationsInvitations {
  final String id;
  final String teamNameSnapshot;
  final Timestamp expiresAt;
  final Timestamp createdAt;
  final ListMyPendingInvitationsInvitationsTeam team;
  ListMyPendingInvitationsInvitations.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  teamNameSnapshot = nativeFromJson<String>(json['teamNameSnapshot']),
  expiresAt = Timestamp.fromJson(json['expiresAt']),
  createdAt = Timestamp.fromJson(json['createdAt']),
  team = ListMyPendingInvitationsInvitationsTeam.fromJson(json['team']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListMyPendingInvitationsInvitations otherTyped = other as ListMyPendingInvitationsInvitations;
    return id == otherTyped.id && 
    teamNameSnapshot == otherTyped.teamNameSnapshot && 
    expiresAt == otherTyped.expiresAt && 
    createdAt == otherTyped.createdAt && 
    team == otherTyped.team;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, teamNameSnapshot.hashCode, expiresAt.hashCode, createdAt.hashCode, team.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['teamNameSnapshot'] = nativeToJson<String>(teamNameSnapshot);
    json['expiresAt'] = expiresAt.toJson();
    json['createdAt'] = createdAt.toJson();
    json['team'] = team.toJson();
    return json;
  }

  ListMyPendingInvitationsInvitations({
    required this.id,
    required this.teamNameSnapshot,
    required this.expiresAt,
    required this.createdAt,
    required this.team,
  });
}

@immutable
class ListMyPendingInvitationsInvitationsTeam {
  final String id;
  final String name;
  ListMyPendingInvitationsInvitationsTeam.fromJson(dynamic json):
  
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

    final ListMyPendingInvitationsInvitationsTeam otherTyped = other as ListMyPendingInvitationsInvitationsTeam;
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

  ListMyPendingInvitationsInvitationsTeam({
    required this.id,
    required this.name,
  });
}

@immutable
class ListMyPendingInvitationsData {
  final List<ListMyPendingInvitationsInvitations> invitations;
  ListMyPendingInvitationsData.fromJson(dynamic json):
  
  invitations = (json['invitations'] as List<dynamic>)
        .map((e) => ListMyPendingInvitationsInvitations.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListMyPendingInvitationsData otherTyped = other as ListMyPendingInvitationsData;
    return invitations == otherTyped.invitations;
    
  }
  @override
  int get hashCode => invitations.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['invitations'] = invitations.map((e) => e.toJson()).toList();
    return json;
  }

  ListMyPendingInvitationsData({
    required this.invitations,
  });
}

