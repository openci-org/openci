part of 'default.dart';

class UpsertTeamFromFirestoreVariablesBuilder {
  String id;
  String name;
  Optional<bool> _aiEnabled = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _githubApiBaseUrl = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _githubBaseUrl = Optional.optional(nativeFromJson, nativeToJson);
  Optional<List<int>> _installationIds = Optional.optional(listDeserializer(nativeFromJson), listSerializer(nativeToJson));
  Optional<List<String>> _members = Optional.optional(listDeserializer(nativeFromJson), listSerializer(nativeToJson));

  final FirebaseDataConnect _dataConnect;  UpsertTeamFromFirestoreVariablesBuilder aiEnabled(bool? t) {
   _aiEnabled.value = t;
   return this;
  }
  UpsertTeamFromFirestoreVariablesBuilder githubApiBaseUrl(String? t) {
   _githubApiBaseUrl.value = t;
   return this;
  }
  UpsertTeamFromFirestoreVariablesBuilder githubBaseUrl(String? t) {
   _githubBaseUrl.value = t;
   return this;
  }
  UpsertTeamFromFirestoreVariablesBuilder installationIds(List<int>? t) {
   _installationIds.value = t;
   return this;
  }
  UpsertTeamFromFirestoreVariablesBuilder members(List<String>? t) {
   _members.value = t;
   return this;
  }

  UpsertTeamFromFirestoreVariablesBuilder(this._dataConnect, {required  this.id,required  this.name,});
  Deserializer<UpsertTeamFromFirestoreData> dataDeserializer = (dynamic json)  => UpsertTeamFromFirestoreData.fromJson(jsonDecode(json));
  Serializer<UpsertTeamFromFirestoreVariables> varsSerializer = (UpsertTeamFromFirestoreVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpsertTeamFromFirestoreData, UpsertTeamFromFirestoreVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpsertTeamFromFirestoreData, UpsertTeamFromFirestoreVariables> ref() {
    UpsertTeamFromFirestoreVariables vars= UpsertTeamFromFirestoreVariables(id: id,name: name,aiEnabled: _aiEnabled,githubApiBaseUrl: _githubApiBaseUrl,githubBaseUrl: _githubBaseUrl,installationIds: _installationIds,members: _members,);
    return _dataConnect.mutation("UpsertTeamFromFirestore", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpsertTeamFromFirestoreTeamUpsert {
  final String id;
  UpsertTeamFromFirestoreTeamUpsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertTeamFromFirestoreTeamUpsert otherTyped = other as UpsertTeamFromFirestoreTeamUpsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpsertTeamFromFirestoreTeamUpsert({
    required this.id,
  });
}

@immutable
class UpsertTeamFromFirestoreData {
  final UpsertTeamFromFirestoreTeamUpsert team_upsert;
  UpsertTeamFromFirestoreData.fromJson(dynamic json):
  
  team_upsert = UpsertTeamFromFirestoreTeamUpsert.fromJson(json['team_upsert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertTeamFromFirestoreData otherTyped = other as UpsertTeamFromFirestoreData;
    return team_upsert == otherTyped.team_upsert;
    
  }
  @override
  int get hashCode => team_upsert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['team_upsert'] = team_upsert.toJson();
    return json;
  }

  UpsertTeamFromFirestoreData({
    required this.team_upsert,
  });
}

@immutable
class UpsertTeamFromFirestoreVariables {
  final String id;
  final String name;
  late final Optional<bool>aiEnabled;
  late final Optional<String>githubApiBaseUrl;
  late final Optional<String>githubBaseUrl;
  late final Optional<List<int>>installationIds;
  late final Optional<List<String>>members;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpsertTeamFromFirestoreVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  name = nativeFromJson<String>(json['name']) {
  
  
  
  
    aiEnabled = Optional.optional(nativeFromJson, nativeToJson);
    aiEnabled.value = json['aiEnabled'] == null ? null : nativeFromJson<bool>(json['aiEnabled']);
  
  
    githubApiBaseUrl = Optional.optional(nativeFromJson, nativeToJson);
    githubApiBaseUrl.value = json['githubApiBaseUrl'] == null ? null : nativeFromJson<String>(json['githubApiBaseUrl']);
  
  
    githubBaseUrl = Optional.optional(nativeFromJson, nativeToJson);
    githubBaseUrl.value = json['githubBaseUrl'] == null ? null : nativeFromJson<String>(json['githubBaseUrl']);
  
  
    installationIds = Optional.optional(listDeserializer(nativeFromJson), listSerializer(nativeToJson));
    installationIds.value = json['installationIds'] == null ? null : (json['installationIds'] as List<dynamic>)
        .map((e) => nativeFromJson<int>(e))
        .toList();
  
  
    members = Optional.optional(listDeserializer(nativeFromJson), listSerializer(nativeToJson));
    members.value = json['members'] == null ? null : (json['members'] as List<dynamic>)
        .map((e) => nativeFromJson<String>(e))
        .toList();
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertTeamFromFirestoreVariables otherTyped = other as UpsertTeamFromFirestoreVariables;
    return id == otherTyped.id && 
    name == otherTyped.name && 
    aiEnabled == otherTyped.aiEnabled && 
    githubApiBaseUrl == otherTyped.githubApiBaseUrl && 
    githubBaseUrl == otherTyped.githubBaseUrl && 
    installationIds == otherTyped.installationIds && 
    members == otherTyped.members;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, name.hashCode, aiEnabled.hashCode, githubApiBaseUrl.hashCode, githubBaseUrl.hashCode, installationIds.hashCode, members.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    if(aiEnabled.state == OptionalState.set) {
      json['aiEnabled'] = aiEnabled.toJson();
    }
    if(githubApiBaseUrl.state == OptionalState.set) {
      json['githubApiBaseUrl'] = githubApiBaseUrl.toJson();
    }
    if(githubBaseUrl.state == OptionalState.set) {
      json['githubBaseUrl'] = githubBaseUrl.toJson();
    }
    if(installationIds.state == OptionalState.set) {
      json['installationIds'] = installationIds.toJson();
    }
    if(members.state == OptionalState.set) {
      json['members'] = members.toJson();
    }
    return json;
  }

  UpsertTeamFromFirestoreVariables({
    required this.id,
    required this.name,
    required this.aiEnabled,
    required this.githubApiBaseUrl,
    required this.githubBaseUrl,
    required this.installationIds,
    required this.members,
  });
}

