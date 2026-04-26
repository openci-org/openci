part of 'default.dart';

class UpdateCurrentUserNotificationPreferenceVariablesBuilder {
  String notificationPreference;

  final FirebaseDataConnect _dataConnect;
  UpdateCurrentUserNotificationPreferenceVariablesBuilder(this._dataConnect, {required  this.notificationPreference,});
  Deserializer<UpdateCurrentUserNotificationPreferenceData> dataDeserializer = (dynamic json)  => UpdateCurrentUserNotificationPreferenceData.fromJson(jsonDecode(json));
  Serializer<UpdateCurrentUserNotificationPreferenceVariables> varsSerializer = (UpdateCurrentUserNotificationPreferenceVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateCurrentUserNotificationPreferenceData, UpdateCurrentUserNotificationPreferenceVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateCurrentUserNotificationPreferenceData, UpdateCurrentUserNotificationPreferenceVariables> ref() {
    UpdateCurrentUserNotificationPreferenceVariables vars= UpdateCurrentUserNotificationPreferenceVariables(notificationPreference: notificationPreference,);
    return _dataConnect.mutation("UpdateCurrentUserNotificationPreference", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateCurrentUserNotificationPreferenceUserUpdate {
  final String id;
  UpdateCurrentUserNotificationPreferenceUserUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateCurrentUserNotificationPreferenceUserUpdate otherTyped = other as UpdateCurrentUserNotificationPreferenceUserUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateCurrentUserNotificationPreferenceUserUpdate({
    required this.id,
  });
}

@immutable
class UpdateCurrentUserNotificationPreferenceData {
  final UpdateCurrentUserNotificationPreferenceUserUpdate? user_update;
  UpdateCurrentUserNotificationPreferenceData.fromJson(dynamic json):
  
  user_update = json['user_update'] == null ? null : UpdateCurrentUserNotificationPreferenceUserUpdate.fromJson(json['user_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateCurrentUserNotificationPreferenceData otherTyped = other as UpdateCurrentUserNotificationPreferenceData;
    return user_update == otherTyped.user_update;
    
  }
  @override
  int get hashCode => user_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (user_update != null) {
      json['user_update'] = user_update!.toJson();
    }
    return json;
  }

  UpdateCurrentUserNotificationPreferenceData({
    this.user_update,
  });
}

@immutable
class UpdateCurrentUserNotificationPreferenceVariables {
  final String notificationPreference;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateCurrentUserNotificationPreferenceVariables.fromJson(Map<String, dynamic> json):
  
  notificationPreference = nativeFromJson<String>(json['notificationPreference']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateCurrentUserNotificationPreferenceVariables otherTyped = other as UpdateCurrentUserNotificationPreferenceVariables;
    return notificationPreference == otherTyped.notificationPreference;
    
  }
  @override
  int get hashCode => notificationPreference.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['notificationPreference'] = nativeToJson<String>(notificationPreference);
    return json;
  }

  UpdateCurrentUserNotificationPreferenceVariables({
    required this.notificationPreference,
  });
}

