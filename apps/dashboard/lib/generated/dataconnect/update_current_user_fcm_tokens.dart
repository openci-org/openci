part of 'default.dart';

class UpdateCurrentUserFcmTokensVariablesBuilder {
  List<String> fcmTokens;

  final FirebaseDataConnect _dataConnect;
  UpdateCurrentUserFcmTokensVariablesBuilder(this._dataConnect, {required  this.fcmTokens,});
  Deserializer<UpdateCurrentUserFcmTokensData> dataDeserializer = (dynamic json)  => UpdateCurrentUserFcmTokensData.fromJson(jsonDecode(json));
  Serializer<UpdateCurrentUserFcmTokensVariables> varsSerializer = (UpdateCurrentUserFcmTokensVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateCurrentUserFcmTokensData, UpdateCurrentUserFcmTokensVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateCurrentUserFcmTokensData, UpdateCurrentUserFcmTokensVariables> ref() {
    UpdateCurrentUserFcmTokensVariables vars= UpdateCurrentUserFcmTokensVariables(fcmTokens: fcmTokens,);
    return _dataConnect.mutation("UpdateCurrentUserFcmTokens", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateCurrentUserFcmTokensUserUpdate {
  final String id;
  UpdateCurrentUserFcmTokensUserUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateCurrentUserFcmTokensUserUpdate otherTyped = other as UpdateCurrentUserFcmTokensUserUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateCurrentUserFcmTokensUserUpdate({
    required this.id,
  });
}

@immutable
class UpdateCurrentUserFcmTokensData {
  final UpdateCurrentUserFcmTokensUserUpdate? user_update;
  UpdateCurrentUserFcmTokensData.fromJson(dynamic json):
  
  user_update = json['user_update'] == null ? null : UpdateCurrentUserFcmTokensUserUpdate.fromJson(json['user_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateCurrentUserFcmTokensData otherTyped = other as UpdateCurrentUserFcmTokensData;
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

  UpdateCurrentUserFcmTokensData({
    this.user_update,
  });
}

@immutable
class UpdateCurrentUserFcmTokensVariables {
  final List<String> fcmTokens;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateCurrentUserFcmTokensVariables.fromJson(Map<String, dynamic> json):
  
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

    final UpdateCurrentUserFcmTokensVariables otherTyped = other as UpdateCurrentUserFcmTokensVariables;
    return fcmTokens == otherTyped.fcmTokens;
    
  }
  @override
  int get hashCode => fcmTokens.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['fcmTokens'] = fcmTokens.map((e) => nativeToJson<String>(e)).toList();
    return json;
  }

  UpdateCurrentUserFcmTokensVariables({
    required this.fcmTokens,
  });
}

