part of 'generated.dart';

class AddFcmTokenVariablesBuilder {
  String token;

  final FirebaseDataConnect _dataConnect;
  AddFcmTokenVariablesBuilder(this._dataConnect, {required  this.token,});
  Deserializer<AddFcmTokenData> dataDeserializer = (dynamic json)  => AddFcmTokenData.fromJson(jsonDecode(json));
  Serializer<AddFcmTokenVariables> varsSerializer = (AddFcmTokenVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<AddFcmTokenData, AddFcmTokenVariables>> execute() {
    return ref().execute();
  }

  MutationRef<AddFcmTokenData, AddFcmTokenVariables> ref() {
    AddFcmTokenVariables vars= AddFcmTokenVariables(token: token,);
    return _dataConnect.mutation("AddFcmToken", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class AddFcmTokenUserUpdate {
  final String id;
  AddFcmTokenUserUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final AddFcmTokenUserUpdate otherTyped = other as AddFcmTokenUserUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  AddFcmTokenUserUpdate({
    required this.id,
  });
}

@immutable
class AddFcmTokenData {
  final AddFcmTokenUserUpdate? user_update;
  AddFcmTokenData.fromJson(dynamic json):
  
  user_update = json['user_update'] == null ? null : AddFcmTokenUserUpdate.fromJson(json['user_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final AddFcmTokenData otherTyped = other as AddFcmTokenData;
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

  AddFcmTokenData({
    this.user_update,
  });
}

@immutable
class AddFcmTokenVariables {
  final String token;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  AddFcmTokenVariables.fromJson(Map<String, dynamic> json):
  
  token = nativeFromJson<String>(json['token']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final AddFcmTokenVariables otherTyped = other as AddFcmTokenVariables;
    return token == otherTyped.token;
    
  }
  @override
  int get hashCode => token.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['token'] = nativeToJson<String>(token);
    return json;
  }

  AddFcmTokenVariables({
    required this.token,
  });
}

