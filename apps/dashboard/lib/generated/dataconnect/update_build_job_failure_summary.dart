part of 'default.dart';

class UpdateBuildJobFailureSummaryVariablesBuilder {
  String id;
  String failureSummaryStatus;
  Optional<String> _failureSummary = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _failureSummaryModel = Optional.optional(nativeFromJson, nativeToJson);
  Optional<int> _failureSummaryDurationMs = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  UpdateBuildJobFailureSummaryVariablesBuilder failureSummary(String? t) {
   _failureSummary.value = t;
   return this;
  }
  UpdateBuildJobFailureSummaryVariablesBuilder failureSummaryModel(String? t) {
   _failureSummaryModel.value = t;
   return this;
  }
  UpdateBuildJobFailureSummaryVariablesBuilder failureSummaryDurationMs(int? t) {
   _failureSummaryDurationMs.value = t;
   return this;
  }

  UpdateBuildJobFailureSummaryVariablesBuilder(this._dataConnect, {required  this.id,required  this.failureSummaryStatus,});
  Deserializer<UpdateBuildJobFailureSummaryData> dataDeserializer = (dynamic json)  => UpdateBuildJobFailureSummaryData.fromJson(jsonDecode(json));
  Serializer<UpdateBuildJobFailureSummaryVariables> varsSerializer = (UpdateBuildJobFailureSummaryVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateBuildJobFailureSummaryData, UpdateBuildJobFailureSummaryVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateBuildJobFailureSummaryData, UpdateBuildJobFailureSummaryVariables> ref() {
    UpdateBuildJobFailureSummaryVariables vars= UpdateBuildJobFailureSummaryVariables(id: id,failureSummaryStatus: failureSummaryStatus,failureSummary: _failureSummary,failureSummaryModel: _failureSummaryModel,failureSummaryDurationMs: _failureSummaryDurationMs,);
    return _dataConnect.mutation("UpdateBuildJobFailureSummary", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateBuildJobFailureSummaryBuildJobUpdate {
  final String id;
  UpdateBuildJobFailureSummaryBuildJobUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateBuildJobFailureSummaryBuildJobUpdate otherTyped = other as UpdateBuildJobFailureSummaryBuildJobUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateBuildJobFailureSummaryBuildJobUpdate({
    required this.id,
  });
}

@immutable
class UpdateBuildJobFailureSummaryData {
  final UpdateBuildJobFailureSummaryBuildJobUpdate? buildJob_update;
  UpdateBuildJobFailureSummaryData.fromJson(dynamic json):
  
  buildJob_update = json['buildJob_update'] == null ? null : UpdateBuildJobFailureSummaryBuildJobUpdate.fromJson(json['buildJob_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateBuildJobFailureSummaryData otherTyped = other as UpdateBuildJobFailureSummaryData;
    return buildJob_update == otherTyped.buildJob_update;
    
  }
  @override
  int get hashCode => buildJob_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (buildJob_update != null) {
      json['buildJob_update'] = buildJob_update!.toJson();
    }
    return json;
  }

  UpdateBuildJobFailureSummaryData({
    this.buildJob_update,
  });
}

@immutable
class UpdateBuildJobFailureSummaryVariables {
  final String id;
  final String failureSummaryStatus;
  late final Optional<String>failureSummary;
  late final Optional<String>failureSummaryModel;
  late final Optional<int>failureSummaryDurationMs;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateBuildJobFailureSummaryVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  failureSummaryStatus = nativeFromJson<String>(json['failureSummaryStatus']) {
  
  
  
  
    failureSummary = Optional.optional(nativeFromJson, nativeToJson);
    failureSummary.value = json['failureSummary'] == null ? null : nativeFromJson<String>(json['failureSummary']);
  
  
    failureSummaryModel = Optional.optional(nativeFromJson, nativeToJson);
    failureSummaryModel.value = json['failureSummaryModel'] == null ? null : nativeFromJson<String>(json['failureSummaryModel']);
  
  
    failureSummaryDurationMs = Optional.optional(nativeFromJson, nativeToJson);
    failureSummaryDurationMs.value = json['failureSummaryDurationMs'] == null ? null : nativeFromJson<int>(json['failureSummaryDurationMs']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateBuildJobFailureSummaryVariables otherTyped = other as UpdateBuildJobFailureSummaryVariables;
    return id == otherTyped.id && 
    failureSummaryStatus == otherTyped.failureSummaryStatus && 
    failureSummary == otherTyped.failureSummary && 
    failureSummaryModel == otherTyped.failureSummaryModel && 
    failureSummaryDurationMs == otherTyped.failureSummaryDurationMs;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, failureSummaryStatus.hashCode, failureSummary.hashCode, failureSummaryModel.hashCode, failureSummaryDurationMs.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['failureSummaryStatus'] = nativeToJson<String>(failureSummaryStatus);
    if(failureSummary.state == OptionalState.set) {
      json['failureSummary'] = failureSummary.toJson();
    }
    if(failureSummaryModel.state == OptionalState.set) {
      json['failureSummaryModel'] = failureSummaryModel.toJson();
    }
    if(failureSummaryDurationMs.state == OptionalState.set) {
      json['failureSummaryDurationMs'] = failureSummaryDurationMs.toJson();
    }
    return json;
  }

  UpdateBuildJobFailureSummaryVariables({
    required this.id,
    required this.failureSummaryStatus,
    required this.failureSummary,
    required this.failureSummaryModel,
    required this.failureSummaryDurationMs,
  });
}

