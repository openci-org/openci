part of 'generated.dart';

class UpdateNotificationPreferenceVariablesBuilder {
  NotificationPreference preference;

  final FirebaseDataConnect _dataConnect;
  UpdateNotificationPreferenceVariablesBuilder(this._dataConnect, {required  this.preference,});
  Deserializer<UpdateNotificationPreferenceData> dataDeserializer = (dynamic json)  => UpdateNotificationPreferenceData.fromJson(jsonDecode(json));
  Serializer<UpdateNotificationPreferenceVariables> varsSerializer = (UpdateNotificationPreferenceVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateNotificationPreferenceData, UpdateNotificationPreferenceVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateNotificationPreferenceData, UpdateNotificationPreferenceVariables> ref() {
    UpdateNotificationPreferenceVariables vars= UpdateNotificationPreferenceVariables(preference: preference,);
    return _dataConnect.mutation("UpdateNotificationPreference", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateNotificationPreferenceUserUpdate {
  final String id;
  UpdateNotificationPreferenceUserUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateNotificationPreferenceUserUpdate otherTyped = other as UpdateNotificationPreferenceUserUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateNotificationPreferenceUserUpdate({
    required this.id,
  });
}

@immutable
class UpdateNotificationPreferenceData {
  final UpdateNotificationPreferenceUserUpdate? user_update;
  UpdateNotificationPreferenceData.fromJson(dynamic json):
  
  user_update = json['user_update'] == null ? null : UpdateNotificationPreferenceUserUpdate.fromJson(json['user_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateNotificationPreferenceData otherTyped = other as UpdateNotificationPreferenceData;
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

  UpdateNotificationPreferenceData({
    this.user_update,
  });
}

@immutable
class UpdateNotificationPreferenceVariables {
  final NotificationPreference preference;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateNotificationPreferenceVariables.fromJson(Map<String, dynamic> json):
  
  preference = NotificationPreference.values.byName(json['preference']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateNotificationPreferenceVariables otherTyped = other as UpdateNotificationPreferenceVariables;
    return preference == otherTyped.preference;
    
  }
  @override
  int get hashCode => preference.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['preference'] = 
    preference.name
    ;
    return json;
  }

  UpdateNotificationPreferenceVariables({
    required this.preference,
  });
}

