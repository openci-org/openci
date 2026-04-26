part of 'default.dart';

class UpsertUserFromFirestoreVariablesBuilder {
  String id;
  String email;
  Optional<String> _displayName = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _photoUrl = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _notificationPreference = Optional.optional(nativeFromJson, nativeToJson);
  Optional<List<String>> _fcmTokens = Optional.optional(listDeserializer(nativeFromJson), listSerializer(nativeToJson));
  Optional<String> _selectedTeamId = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _selectedRepository = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _selectedBranch = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  UpsertUserFromFirestoreVariablesBuilder displayName(String? t) {
   _displayName.value = t;
   return this;
  }
  UpsertUserFromFirestoreVariablesBuilder photoUrl(String? t) {
   _photoUrl.value = t;
   return this;
  }
  UpsertUserFromFirestoreVariablesBuilder notificationPreference(String? t) {
   _notificationPreference.value = t;
   return this;
  }
  UpsertUserFromFirestoreVariablesBuilder fcmTokens(List<String>? t) {
   _fcmTokens.value = t;
   return this;
  }
  UpsertUserFromFirestoreVariablesBuilder selectedTeamId(String? t) {
   _selectedTeamId.value = t;
   return this;
  }
  UpsertUserFromFirestoreVariablesBuilder selectedRepository(String? t) {
   _selectedRepository.value = t;
   return this;
  }
  UpsertUserFromFirestoreVariablesBuilder selectedBranch(String? t) {
   _selectedBranch.value = t;
   return this;
  }

  UpsertUserFromFirestoreVariablesBuilder(this._dataConnect, {required  this.id,required  this.email,});
  Deserializer<UpsertUserFromFirestoreData> dataDeserializer = (dynamic json)  => UpsertUserFromFirestoreData.fromJson(jsonDecode(json));
  Serializer<UpsertUserFromFirestoreVariables> varsSerializer = (UpsertUserFromFirestoreVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpsertUserFromFirestoreData, UpsertUserFromFirestoreVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpsertUserFromFirestoreData, UpsertUserFromFirestoreVariables> ref() {
    UpsertUserFromFirestoreVariables vars= UpsertUserFromFirestoreVariables(id: id,email: email,displayName: _displayName,photoUrl: _photoUrl,notificationPreference: _notificationPreference,fcmTokens: _fcmTokens,selectedTeamId: _selectedTeamId,selectedRepository: _selectedRepository,selectedBranch: _selectedBranch,);
    return _dataConnect.mutation("UpsertUserFromFirestore", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpsertUserFromFirestoreUserUpsert {
  final String id;
  UpsertUserFromFirestoreUserUpsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertUserFromFirestoreUserUpsert otherTyped = other as UpsertUserFromFirestoreUserUpsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpsertUserFromFirestoreUserUpsert({
    required this.id,
  });
}

@immutable
class UpsertUserFromFirestoreData {
  final UpsertUserFromFirestoreUserUpsert user_upsert;
  UpsertUserFromFirestoreData.fromJson(dynamic json):
  
  user_upsert = UpsertUserFromFirestoreUserUpsert.fromJson(json['user_upsert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertUserFromFirestoreData otherTyped = other as UpsertUserFromFirestoreData;
    return user_upsert == otherTyped.user_upsert;
    
  }
  @override
  int get hashCode => user_upsert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['user_upsert'] = user_upsert.toJson();
    return json;
  }

  UpsertUserFromFirestoreData({
    required this.user_upsert,
  });
}

@immutable
class UpsertUserFromFirestoreVariables {
  final String id;
  final String email;
  late final Optional<String>displayName;
  late final Optional<String>photoUrl;
  late final Optional<String>notificationPreference;
  late final Optional<List<String>>fcmTokens;
  late final Optional<String>selectedTeamId;
  late final Optional<String>selectedRepository;
  late final Optional<String>selectedBranch;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpsertUserFromFirestoreVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  email = nativeFromJson<String>(json['email']) {
  
  
  
  
    displayName = Optional.optional(nativeFromJson, nativeToJson);
    displayName.value = json['displayName'] == null ? null : nativeFromJson<String>(json['displayName']);
  
  
    photoUrl = Optional.optional(nativeFromJson, nativeToJson);
    photoUrl.value = json['photoUrl'] == null ? null : nativeFromJson<String>(json['photoUrl']);
  
  
    notificationPreference = Optional.optional(nativeFromJson, nativeToJson);
    notificationPreference.value = json['notificationPreference'] == null ? null : nativeFromJson<String>(json['notificationPreference']);
  
  
    fcmTokens = Optional.optional(listDeserializer(nativeFromJson), listSerializer(nativeToJson));
    fcmTokens.value = json['fcmTokens'] == null ? null : (json['fcmTokens'] as List<dynamic>)
        .map((e) => nativeFromJson<String>(e))
        .toList();
  
  
    selectedTeamId = Optional.optional(nativeFromJson, nativeToJson);
    selectedTeamId.value = json['selectedTeamId'] == null ? null : nativeFromJson<String>(json['selectedTeamId']);
  
  
    selectedRepository = Optional.optional(nativeFromJson, nativeToJson);
    selectedRepository.value = json['selectedRepository'] == null ? null : nativeFromJson<String>(json['selectedRepository']);
  
  
    selectedBranch = Optional.optional(nativeFromJson, nativeToJson);
    selectedBranch.value = json['selectedBranch'] == null ? null : nativeFromJson<String>(json['selectedBranch']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertUserFromFirestoreVariables otherTyped = other as UpsertUserFromFirestoreVariables;
    return id == otherTyped.id && 
    email == otherTyped.email && 
    displayName == otherTyped.displayName && 
    photoUrl == otherTyped.photoUrl && 
    notificationPreference == otherTyped.notificationPreference && 
    fcmTokens == otherTyped.fcmTokens && 
    selectedTeamId == otherTyped.selectedTeamId && 
    selectedRepository == otherTyped.selectedRepository && 
    selectedBranch == otherTyped.selectedBranch;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, email.hashCode, displayName.hashCode, photoUrl.hashCode, notificationPreference.hashCode, fcmTokens.hashCode, selectedTeamId.hashCode, selectedRepository.hashCode, selectedBranch.hashCode]);
  

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
    if(notificationPreference.state == OptionalState.set) {
      json['notificationPreference'] = notificationPreference.toJson();
    }
    if(fcmTokens.state == OptionalState.set) {
      json['fcmTokens'] = fcmTokens.toJson();
    }
    if(selectedTeamId.state == OptionalState.set) {
      json['selectedTeamId'] = selectedTeamId.toJson();
    }
    if(selectedRepository.state == OptionalState.set) {
      json['selectedRepository'] = selectedRepository.toJson();
    }
    if(selectedBranch.state == OptionalState.set) {
      json['selectedBranch'] = selectedBranch.toJson();
    }
    return json;
  }

  UpsertUserFromFirestoreVariables({
    required this.id,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.notificationPreference,
    required this.fcmTokens,
    required this.selectedTeamId,
    required this.selectedRepository,
    required this.selectedBranch,
  });
}

