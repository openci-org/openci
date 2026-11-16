part of 'builds.dart';

class RetryBuildJobVariablesBuilder {
  String id;
  int expectedRetryCount;

  final FirebaseDataConnect _dataConnect;
  RetryBuildJobVariablesBuilder(
    this._dataConnect, {
    required this.id,
    required this.expectedRetryCount,
  });
  Deserializer<RetryBuildJobData> dataDeserializer = (dynamic json) =>
      RetryBuildJobData.fromJson(jsonDecode(json));
  Serializer<RetryBuildJobVariables> varsSerializer =
      (RetryBuildJobVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<RetryBuildJobData, RetryBuildJobVariables>> execute() {
    return ref().execute();
  }

  MutationRef<RetryBuildJobData, RetryBuildJobVariables> ref() {
    RetryBuildJobVariables vars = RetryBuildJobVariables(
      id: id,
      expectedRetryCount: expectedRetryCount,
    );
    return _dataConnect.mutation(
      "RetryBuildJob",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class RetryBuildJobResult {
  final RetryBuildJobResultJob? job;
  RetryBuildJobResult.fromJson(dynamic json)
    : job = json['job'] == null
          ? null
          : RetryBuildJobResultJob.fromJson(json['job']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final RetryBuildJobResult otherTyped = other as RetryBuildJobResult;
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

  RetryBuildJobResult({
    this.job,
  });
}

@immutable
class RetryBuildJobResultJob {
  final String id;
  final String status;
  final int retryCount;
  final BigInt? runCount;
  final String? latestRunId;
  RetryBuildJobResultJob.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']),
      status = nativeFromJson<String>(json['status']),
      retryCount = nativeFromJson<int>(json['retryCount']),
      runCount = json['runCount'] == null
          ? null
          : bigIntFromJson(json['runCount']),
      latestRunId = json['latestRunId'] == null
          ? null
          : nativeFromJson<String>(json['latestRunId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final RetryBuildJobResultJob otherTyped = other as RetryBuildJobResultJob;
    return id == otherTyped.id &&
        status == otherTyped.status &&
        retryCount == otherTyped.retryCount &&
        runCount == otherTyped.runCount &&
        latestRunId == otherTyped.latestRunId;
  }

  @override
  int get hashCode => Object.hashAll([
    id.hashCode,
    status.hashCode,
    retryCount.hashCode,
    runCount.hashCode,
    latestRunId.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['status'] = nativeToJson<String>(status);
    json['retryCount'] = nativeToJson<int>(retryCount);
    if (runCount != null) {
      json['runCount'] = bigIntToJson(runCount);
    }
    if (latestRunId != null) {
      json['latestRunId'] = nativeToJson<String?>(latestRunId);
    }
    return json;
  }

  RetryBuildJobResultJob({
    required this.id,
    required this.status,
    required this.retryCount,
    this.runCount,
    this.latestRunId,
  });
}

@immutable
class RetryBuildJobData {
  final int retried;
  final RetryBuildJobResult? result;
  RetryBuildJobData.fromJson(dynamic json)
    : retried = nativeFromJson<int>(json['retried']),
      result = json['result'] == null
          ? null
          : RetryBuildJobResult.fromJson(json['result']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final RetryBuildJobData otherTyped = other as RetryBuildJobData;
    return retried == otherTyped.retried && result == otherTyped.result;
  }

  @override
  int get hashCode => Object.hashAll([retried.hashCode, result.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['retried'] = nativeToJson<int>(retried);
    if (result != null) {
      json['result'] = result!.toJson();
    }
    return json;
  }

  RetryBuildJobData({
    required this.retried,
    this.result,
  });
}

@immutable
class RetryBuildJobVariables {
  final String id;
  final int expectedRetryCount;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  RetryBuildJobVariables.fromJson(Map<String, dynamic> json)
    : id = nativeFromJson<String>(json['id']),
      expectedRetryCount = nativeFromJson<int>(json['expectedRetryCount']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final RetryBuildJobVariables otherTyped = other as RetryBuildJobVariables;
    return id == otherTyped.id &&
        expectedRetryCount == otherTyped.expectedRetryCount;
  }

  @override
  int get hashCode =>
      Object.hashAll([id.hashCode, expectedRetryCount.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['expectedRetryCount'] = nativeToJson<int>(expectedRetryCount);
    return json;
  }

  RetryBuildJobVariables({
    required this.id,
    required this.expectedRetryCount,
  });
}
