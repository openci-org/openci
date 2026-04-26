part of 'default.dart';

class GetCurrentUserVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  GetCurrentUserVariablesBuilder(this._dataConnect, );
  Deserializer<GetCurrentUserData> dataDeserializer = (dynamic json)  => GetCurrentUserData.fromJson(jsonDecode(json));
  
  Future<QueryResult<GetCurrentUserData, void>> execute() {
    return ref().execute();
  }

  QueryRef<GetCurrentUserData, void> ref() {
    
    return _dataConnect.query("GetCurrentUser", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class GetCurrentUserUser {
  final String id;
  final String? selectedTeamId;
  final String? notificationPreference;
  final List<String>? fcmTokens;
  final String? selectedRepository;
  final String? selectedBranch;
  GetCurrentUserUser.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  selectedTeamId = json['selectedTeamId'] == null ? null : nativeFromJson<String>(json['selectedTeamId']),
  notificationPreference = json['notificationPreference'] == null ? null : nativeFromJson<String>(json['notificationPreference']),
  fcmTokens = json['fcmTokens'] == null ? null : (json['fcmTokens'] as List<dynamic>)
        .map((e) => nativeFromJson<String>(e))
        .toList(),
  selectedRepository = json['selectedRepository'] == null ? null : nativeFromJson<String>(json['selectedRepository']),
  selectedBranch = json['selectedBranch'] == null ? null : nativeFromJson<String>(json['selectedBranch']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetCurrentUserUser otherTyped = other as GetCurrentUserUser;
    return id == otherTyped.id && 
    selectedTeamId == otherTyped.selectedTeamId && 
    notificationPreference == otherTyped.notificationPreference && 
    fcmTokens == otherTyped.fcmTokens && 
    selectedRepository == otherTyped.selectedRepository && 
    selectedBranch == otherTyped.selectedBranch;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, selectedTeamId.hashCode, notificationPreference.hashCode, fcmTokens.hashCode, selectedRepository.hashCode, selectedBranch.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    if (selectedTeamId != null) {
      json['selectedTeamId'] = nativeToJson<String?>(selectedTeamId);
    }
    if (notificationPreference != null) {
      json['notificationPreference'] = nativeToJson<String?>(notificationPreference);
    }
    if (fcmTokens != null) {
      json['fcmTokens'] = fcmTokens?.map((e) => nativeToJson<String>(e)).toList();
    }
    if (selectedRepository != null) {
      json['selectedRepository'] = nativeToJson<String?>(selectedRepository);
    }
    if (selectedBranch != null) {
      json['selectedBranch'] = nativeToJson<String?>(selectedBranch);
    }
    return json;
  }

  GetCurrentUserUser({
    required this.id,
    this.selectedTeamId,
    this.notificationPreference,
    this.fcmTokens,
    this.selectedRepository,
    this.selectedBranch,
  });
}

@immutable
class GetCurrentUserData {
  final GetCurrentUserUser? user;
  GetCurrentUserData.fromJson(dynamic json):
  
  user = json['user'] == null ? null : GetCurrentUserUser.fromJson(json['user']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetCurrentUserData otherTyped = other as GetCurrentUserData;
    return user == otherTyped.user;
    
  }
  @override
  int get hashCode => user.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (user != null) {
      json['user'] = user!.toJson();
    }
    return json;
  }

  GetCurrentUserData({
    this.user,
  });
}

