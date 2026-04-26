part of 'default.dart';

class ClaimQueuedBuildJobVariablesBuilder {
  String runsOnPattern;

  final FirebaseDataConnect _dataConnect;
  ClaimQueuedBuildJobVariablesBuilder(this._dataConnect, {required  this.runsOnPattern,});
  Deserializer<ClaimQueuedBuildJobData> dataDeserializer = (dynamic json)  => ClaimQueuedBuildJobData.fromJson(jsonDecode(json));
  Serializer<ClaimQueuedBuildJobVariables> varsSerializer = (ClaimQueuedBuildJobVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<ClaimQueuedBuildJobData, ClaimQueuedBuildJobVariables>> execute() {
    return ref().execute();
  }

  MutationRef<ClaimQueuedBuildJobData, ClaimQueuedBuildJobVariables> ref() {
    ClaimQueuedBuildJobVariables vars= ClaimQueuedBuildJobVariables(runsOnPattern: runsOnPattern,);
    return _dataConnect.mutation("ClaimQueuedBuildJob", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class ClaimQueuedBuildJobData {
  final AnyValue? job;
  ClaimQueuedBuildJobData.fromJson(dynamic json):
  
  job = json['job'] == null ? null : AnyValue.fromJson(json['job']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ClaimQueuedBuildJobData otherTyped = other as ClaimQueuedBuildJobData;
    return job == otherTyped.job;
    
  }
  @override
  int get hashCode => job.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (job != null) {
      json['job'] = job!.toJson();
    }
    return json;
  }

  ClaimQueuedBuildJobData({
    this.job,
  });
}

@immutable
class ClaimQueuedBuildJobVariables {
  final String runsOnPattern;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ClaimQueuedBuildJobVariables.fromJson(Map<String, dynamic> json):
  
  runsOnPattern = nativeFromJson<String>(json['runsOnPattern']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ClaimQueuedBuildJobVariables otherTyped = other as ClaimQueuedBuildJobVariables;
    return runsOnPattern == otherTyped.runsOnPattern;
    
  }
  @override
  int get hashCode => runsOnPattern.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['runsOnPattern'] = nativeToJson<String>(runsOnPattern);
    return json;
  }

  ClaimQueuedBuildJobVariables({
    required this.runsOnPattern,
  });
}

