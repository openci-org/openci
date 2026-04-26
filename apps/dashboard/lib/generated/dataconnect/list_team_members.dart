part of 'default.dart';

class ListTeamMembersVariablesBuilder {
  String teamId;

  final FirebaseDataConnect _dataConnect;
  ListTeamMembersVariablesBuilder(this._dataConnect, {required  this.teamId,});
  Deserializer<ListTeamMembersData> dataDeserializer = (dynamic json)  => ListTeamMembersData.fromJson(jsonDecode(json));
  Serializer<ListTeamMembersVariables> varsSerializer = (ListTeamMembersVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<ListTeamMembersData, ListTeamMembersVariables>> execute() {
    return ref().execute();
  }

  QueryRef<ListTeamMembersData, ListTeamMembersVariables> ref() {
    ListTeamMembersVariables vars= ListTeamMembersVariables(teamId: teamId,);
    return _dataConnect.query("ListTeamMembers", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class ListTeamMembersTeamMember {
  final String teamId;
  ListTeamMembersTeamMember.fromJson(dynamic json):
  
  teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListTeamMembersTeamMember otherTyped = other as ListTeamMembersTeamMember;
    return teamId == otherTyped.teamId;
    
  }
  @override
  int get hashCode => teamId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  ListTeamMembersTeamMember({
    required this.teamId,
  });
}

@immutable
class ListTeamMembersTeamMembers {
  final String userId;
  final ListTeamMembersTeamMembersUser user;
  ListTeamMembersTeamMembers.fromJson(dynamic json):
  
  userId = nativeFromJson<String>(json['userId']),
  user = ListTeamMembersTeamMembersUser.fromJson(json['user']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListTeamMembersTeamMembers otherTyped = other as ListTeamMembersTeamMembers;
    return userId == otherTyped.userId && 
    user == otherTyped.user;
    
  }
  @override
  int get hashCode => Object.hashAll([userId.hashCode, user.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userId'] = nativeToJson<String>(userId);
    json['user'] = user.toJson();
    return json;
  }

  ListTeamMembersTeamMembers({
    required this.userId,
    required this.user,
  });
}

@immutable
class ListTeamMembersTeamMembersUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  ListTeamMembersTeamMembersUser.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  email = nativeFromJson<String>(json['email']),
  displayName = json['displayName'] == null ? null : nativeFromJson<String>(json['displayName']),
  photoUrl = json['photoUrl'] == null ? null : nativeFromJson<String>(json['photoUrl']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListTeamMembersTeamMembersUser otherTyped = other as ListTeamMembersTeamMembersUser;
    return id == otherTyped.id && 
    email == otherTyped.email && 
    displayName == otherTyped.displayName && 
    photoUrl == otherTyped.photoUrl;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, email.hashCode, displayName.hashCode, photoUrl.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['email'] = nativeToJson<String>(email);
    if (displayName != null) {
      json['displayName'] = nativeToJson<String?>(displayName);
    }
    if (photoUrl != null) {
      json['photoUrl'] = nativeToJson<String?>(photoUrl);
    }
    return json;
  }

  ListTeamMembersTeamMembersUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
  });
}

@immutable
class ListTeamMembersData {
  final ListTeamMembersTeamMember? teamMember;
  final List<ListTeamMembersTeamMembers> teamMembers;
  ListTeamMembersData.fromJson(dynamic json):
  
  teamMember = json['teamMember'] == null ? null : ListTeamMembersTeamMember.fromJson(json['teamMember']),
  teamMembers = (json['teamMembers'] as List<dynamic>)
        .map((e) => ListTeamMembersTeamMembers.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListTeamMembersData otherTyped = other as ListTeamMembersData;
    return teamMember == otherTyped.teamMember && 
    teamMembers == otherTyped.teamMembers;
    
  }
  @override
  int get hashCode => Object.hashAll([teamMember.hashCode, teamMembers.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (teamMember != null) {
      json['teamMember'] = teamMember!.toJson();
    }
    json['teamMembers'] = teamMembers.map((e) => e.toJson()).toList();
    return json;
  }

  ListTeamMembersData({
    this.teamMember,
    required this.teamMembers,
  });
}

@immutable
class ListTeamMembersVariables {
  final String teamId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ListTeamMembersVariables.fromJson(Map<String, dynamic> json):
  
  teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListTeamMembersVariables otherTyped = other as ListTeamMembersVariables;
    return teamId == otherTyped.teamId;
    
  }
  @override
  int get hashCode => teamId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  ListTeamMembersVariables({
    required this.teamId,
  });
}

