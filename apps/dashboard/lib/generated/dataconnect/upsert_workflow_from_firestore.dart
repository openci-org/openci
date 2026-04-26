part of 'default.dart';

class UpsertWorkflowFromFirestoreVariablesBuilder {
  String id;
  String teamId;
  Optional<String> _name = Optional.optional(nativeFromJson, nativeToJson);
  Optional<AnyValue> _workflowConfig = Optional.optional(AnyValue.fromJson, defaultSerializer);
  Optional<AnyValue> _workflowSteps = Optional.optional(AnyValue.fromJson, defaultSerializer);
  Optional<bool> _isEditing = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  UpsertWorkflowFromFirestoreVariablesBuilder name(String? t) {
   _name.value = t;
   return this;
  }
  UpsertWorkflowFromFirestoreVariablesBuilder workflowConfig(AnyValue? t) {
   _workflowConfig.value = t;
   return this;
  }
  UpsertWorkflowFromFirestoreVariablesBuilder workflowSteps(AnyValue? t) {
   _workflowSteps.value = t;
   return this;
  }
  UpsertWorkflowFromFirestoreVariablesBuilder isEditing(bool? t) {
   _isEditing.value = t;
   return this;
  }

  UpsertWorkflowFromFirestoreVariablesBuilder(this._dataConnect, {required  this.id,required  this.teamId,});
  Deserializer<UpsertWorkflowFromFirestoreData> dataDeserializer = (dynamic json)  => UpsertWorkflowFromFirestoreData.fromJson(jsonDecode(json));
  Serializer<UpsertWorkflowFromFirestoreVariables> varsSerializer = (UpsertWorkflowFromFirestoreVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpsertWorkflowFromFirestoreData, UpsertWorkflowFromFirestoreVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpsertWorkflowFromFirestoreData, UpsertWorkflowFromFirestoreVariables> ref() {
    UpsertWorkflowFromFirestoreVariables vars= UpsertWorkflowFromFirestoreVariables(id: id,teamId: teamId,name: _name,workflowConfig: _workflowConfig,workflowSteps: _workflowSteps,isEditing: _isEditing,);
    return _dataConnect.mutation("UpsertWorkflowFromFirestore", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpsertWorkflowFromFirestoreWorkflowUpsert {
  final String id;
  UpsertWorkflowFromFirestoreWorkflowUpsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertWorkflowFromFirestoreWorkflowUpsert otherTyped = other as UpsertWorkflowFromFirestoreWorkflowUpsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpsertWorkflowFromFirestoreWorkflowUpsert({
    required this.id,
  });
}

@immutable
class UpsertWorkflowFromFirestoreData {
  final UpsertWorkflowFromFirestoreWorkflowUpsert workflow_upsert;
  UpsertWorkflowFromFirestoreData.fromJson(dynamic json):
  
  workflow_upsert = UpsertWorkflowFromFirestoreWorkflowUpsert.fromJson(json['workflow_upsert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertWorkflowFromFirestoreData otherTyped = other as UpsertWorkflowFromFirestoreData;
    return workflow_upsert == otherTyped.workflow_upsert;
    
  }
  @override
  int get hashCode => workflow_upsert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['workflow_upsert'] = workflow_upsert.toJson();
    return json;
  }

  UpsertWorkflowFromFirestoreData({
    required this.workflow_upsert,
  });
}

@immutable
class UpsertWorkflowFromFirestoreVariables {
  final String id;
  final String teamId;
  late final Optional<String>name;
  late final Optional<AnyValue>workflowConfig;
  late final Optional<AnyValue>workflowSteps;
  late final Optional<bool>isEditing;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpsertWorkflowFromFirestoreVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  teamId = nativeFromJson<String>(json['teamId']) {
  
  
  
  
    name = Optional.optional(nativeFromJson, nativeToJson);
    name.value = json['name'] == null ? null : nativeFromJson<String>(json['name']);
  
  
    workflowConfig = Optional.optional(AnyValue.fromJson, defaultSerializer);
    workflowConfig.value = json['workflowConfig'] == null ? null : AnyValue.fromJson(json['workflowConfig']);
  
  
    workflowSteps = Optional.optional(AnyValue.fromJson, defaultSerializer);
    workflowSteps.value = json['workflowSteps'] == null ? null : AnyValue.fromJson(json['workflowSteps']);
  
  
    isEditing = Optional.optional(nativeFromJson, nativeToJson);
    isEditing.value = json['isEditing'] == null ? null : nativeFromJson<bool>(json['isEditing']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertWorkflowFromFirestoreVariables otherTyped = other as UpsertWorkflowFromFirestoreVariables;
    return id == otherTyped.id && 
    teamId == otherTyped.teamId && 
    name == otherTyped.name && 
    workflowConfig == otherTyped.workflowConfig && 
    workflowSteps == otherTyped.workflowSteps && 
    isEditing == otherTyped.isEditing;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, teamId.hashCode, name.hashCode, workflowConfig.hashCode, workflowSteps.hashCode, isEditing.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['teamId'] = nativeToJson<String>(teamId);
    if(name.state == OptionalState.set) {
      json['name'] = name.toJson();
    }
    if(workflowConfig.state == OptionalState.set) {
      json['workflowConfig'] = workflowConfig.toJson();
    }
    if(workflowSteps.state == OptionalState.set) {
      json['workflowSteps'] = workflowSteps.toJson();
    }
    if(isEditing.state == OptionalState.set) {
      json['isEditing'] = isEditing.toJson();
    }
    return json;
  }

  UpsertWorkflowFromFirestoreVariables({
    required this.id,
    required this.teamId,
    required this.name,
    required this.workflowConfig,
    required this.workflowSteps,
    required this.isEditing,
  });
}

