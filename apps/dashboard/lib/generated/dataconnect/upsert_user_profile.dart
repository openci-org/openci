part of 'default.dart';

class UpsertUserProfileVariablesBuilder {
  String id;
  String email;
  Optional<String> _displayName = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _photoUrl = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  UpsertUserProfileVariablesBuilder displayName(String? t) {
   _displayName.value = t;
   return this;
  }
  UpsertUserProfileVariablesBuilder photoUrl(String? t) {
   _photoUrl.value = t;
   return this;
  }

  UpsertUserProfileVariablesBuilder(this._dataConnect, {required  this.id,required  this.email,});
  Deserializer<UpsertUserProfileData> dataDeserializer = (dynamic json)  => UpsertUserProfileData.fromJson(jsonDecode(json));
  Serializer<UpsertUserProfileVariables> varsSerializer = (UpsertUserProfileVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpsertUserProfileData, UpsertUserProfileVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpsertUserProfileData, UpsertUserProfileVariables> ref() {
    UpsertUserProfileVariables vars= UpsertUserProfileVariables(id: id,email: email,displayName: _displayName,photoUrl: _photoUrl,);
    return _dataConnect.mutation("UpsertUserProfile", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpsertUserProfileUserUpsert {
  final String id;
  UpsertUserProfileUserUpsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertUserProfileUserUpsert otherTyped = other as UpsertUserProfileUserUpsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpsertUserProfileUserUpsert({
    required this.id,
  });
}

@immutable
class UpsertUserProfileData {
  final UpsertUserProfileUserUpsert user_upsert;
  UpsertUserProfileData.fromJson(dynamic json):
  
  user_upsert = UpsertUserProfileUserUpsert.fromJson(json['user_upsert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertUserProfileData otherTyped = other as UpsertUserProfileData;
    return user_upsert == otherTyped.user_upsert;
    
  }
  @override
  int get hashCode => user_upsert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['user_upsert'] = user_upsert.toJson();
    return json;
  }

  UpsertUserProfileData({
    required this.user_upsert,
  });
}

@immutable
class UpsertUserProfileVariables {
  final String id;
  final String email;
  late final Optional<String>displayName;
  late final Optional<String>photoUrl;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpsertUserProfileVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  email = nativeFromJson<String>(json['email']) {
  
  
  
  
    displayName = Optional.optional(nativeFromJson, nativeToJson);
    displayName.value = json['displayName'] == null ? null : nativeFromJson<String>(json['displayName']);
  
  
    photoUrl = Optional.optional(nativeFromJson, nativeToJson);
    photoUrl.value = json['photoUrl'] == null ? null : nativeFromJson<String>(json['photoUrl']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertUserProfileVariables otherTyped = other as UpsertUserProfileVariables;
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
    if(displayName.state == OptionalState.set) {
      json['displayName'] = displayName.toJson();
    }
    if(photoUrl.state == OptionalState.set) {
      json['photoUrl'] = photoUrl.toJson();
    }
    return json;
  }

  UpsertUserProfileVariables({
    required this.id,
    required this.email,
    required this.displayName,
    required this.photoUrl,
  });
}

