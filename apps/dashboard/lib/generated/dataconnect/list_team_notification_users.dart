part of 'default.dart';

class ListTeamNotificationUsersVariablesBuilder {
  String teamId;

  final FirebaseDataConnect _dataConnect;
  ListTeamNotificationUsersVariablesBuilder(this._dataConnect, {required  this.teamId,});
  Deserializer<ListTeamNotificationUsersData> dataDeserializer = (dynamic json)  => ListTeamNotificationUsersData.fromJson(jsonDecode(json));
  Serializer<ListTeamNotificationUsersVariables> varsSerializer = (ListTeamNotificationUsersVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<ListTeamNotificationUsersData, ListTeamNotificationUsersVariables>> execute() {
    return ref().execute();
  }

  QueryRef<ListTeamNotificationUsersData, ListTeamNotificationUsersVariables> ref() {
    ListTeamNotificationUsersVariables vars= ListTeamNotificationUsersVariables(teamId: teamId,);
    return _dataConnect.query("ListTeamNotificationUsers", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class ListTeamNotificationUsersTeamMembers {
  final ListTeamNotificationUsersTeamMembersUser user;
  ListTeamNotificationUsersTeamMembers.fromJson(dynamic json):
  
  user = ListTeamNotificationUsersTeamMembersUser.fromJson(json['user']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListTeamNotificationUsersTeamMembers otherTyped = other as ListTeamNotificationUsersTeamMembers;
    return user == otherTyped.user;
    
  }
  @override
  int get hashCode => user.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['user'] = user.toJson();
    return json;
  }

  ListTeamNotificationUsersTeamMembers({
    required this.user,
  });
}

@immutable
class ListTeamNotificationUsersTeamMembersUser {
  final String id;
  final String? notificationPreference;
  final List<String>? fcmTokens;
  ListTeamNotificationUsersTeamMembersUser.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  notificationPreference = json['notificationPreference'] == null ? null : nativeFromJson<String>(json['notificationPreference']),
  fcmTokens = json['fcmTokens'] == null ? null : (json['fcmTokens'] as List<dynamic>)
        .map((e) => nativeFromJson<String>(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListTeamNotificationUsersTeamMembersUser otherTyped = other as ListTeamNotificationUsersTeamMembersUser;
    return id == otherTyped.id && 
    notificationPreference == otherTyped.notificationPreference && 
    fcmTokens == otherTyped.fcmTokens;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, notificationPreference.hashCode, fcmTokens.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    if (notificationPreference != null) {
      json['notificationPreference'] = nativeToJson<String?>(notificationPreference);
    }
    if (fcmTokens != null) {
      json['fcmTokens'] = fcmTokens?.map((e) => nativeToJson<String>(e)).toList();
    }
    return json;
  }

  ListTeamNotificationUsersTeamMembersUser({
    required this.id,
    this.notificationPreference,
    this.fcmTokens,
  });
}

@immutable
class ListTeamNotificationUsersData {
  final List<ListTeamNotificationUsersTeamMembers> teamMembers;
  ListTeamNotificationUsersData.fromJson(dynamic json):
  
  teamMembers = (json['teamMembers'] as List<dynamic>)
        .map((e) => ListTeamNotificationUsersTeamMembers.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListTeamNotificationUsersData otherTyped = other as ListTeamNotificationUsersData;
    return teamMembers == otherTyped.teamMembers;
    
  }
  @override
  int get hashCode => teamMembers.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamMembers'] = teamMembers.map((e) => e.toJson()).toList();
    return json;
  }

  ListTeamNotificationUsersData({
    required this.teamMembers,
  });
}

@immutable
class ListTeamNotificationUsersVariables {
  final String teamId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ListTeamNotificationUsersVariables.fromJson(Map<String, dynamic> json):
  
  teamId = nativeFromJson<String>(json['teamId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListTeamNotificationUsersVariables otherTyped = other as ListTeamNotificationUsersVariables;
    return teamId == otherTyped.teamId;
    
  }
  @override
  int get hashCode => teamId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['teamId'] = nativeToJson<String>(teamId);
    return json;
  }

  ListTeamNotificationUsersVariables({
    required this.teamId,
  });
}

