part of 'generated.dart';

class GetMyUserVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  GetMyUserVariablesBuilder(this._dataConnect, );
  Deserializer<GetMyUserData> dataDeserializer = (dynamic json)  => GetMyUserData.fromJson(jsonDecode(json));
  
  Future<QueryResult<GetMyUserData, void>> execute() {
    return ref().execute();
  }

  QueryRef<GetMyUserData, void> ref() {
    
    return _dataConnect.query("GetMyUser", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class GetMyUserUser {
  final String id;
  final String? selectedTeamId;
  final EnumValue<NotificationPreference> notificationPreference;
  final List<String> fcmTokens;
  GetMyUserUser.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  selectedTeamId = json['selectedTeamId'] == null ? null : nativeFromJson<String>(json['selectedTeamId']),
  notificationPreference = notificationPreferenceDeserializer(json['notificationPreference']),
  fcmTokens = (json['fcmTokens'] as List<dynamic>)
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

    final GetMyUserUser otherTyped = other as GetMyUserUser;
    return id == otherTyped.id && 
    selectedTeamId == otherTyped.selectedTeamId && 
    notificationPreference == otherTyped.notificationPreference && 
    fcmTokens == otherTyped.fcmTokens;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, selectedTeamId.hashCode, notificationPreference.hashCode, fcmTokens.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    if (selectedTeamId != null) {
      json['selectedTeamId'] = nativeToJson<String?>(selectedTeamId);
    }
    json['notificationPreference'] = 
    notificationPreferenceSerializer(notificationPreference)
    ;
    json['fcmTokens'] = fcmTokens.map((e) => nativeToJson<String>(e)).toList();
    return json;
  }

  GetMyUserUser({
    required this.id,
    this.selectedTeamId,
    required this.notificationPreference,
    required this.fcmTokens,
  });
}

@immutable
class GetMyUserData {
  final GetMyUserUser? user;
  GetMyUserData.fromJson(dynamic json):
  
  user = json['user'] == null ? null : GetMyUserUser.fromJson(json['user']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyUserData otherTyped = other as GetMyUserData;
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

  GetMyUserData({
    this.user,
  });
}

