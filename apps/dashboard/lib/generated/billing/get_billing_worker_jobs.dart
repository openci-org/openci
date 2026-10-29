part of 'billing.dart';

class GetBillingWorkerJobsVariablesBuilder {
  String workerHost;

  final FirebaseDataConnect _dataConnect;
  GetBillingWorkerJobsVariablesBuilder(
    this._dataConnect, {
    required this.workerHost,
  });
  Deserializer<GetBillingWorkerJobsData> dataDeserializer = (dynamic json) =>
      GetBillingWorkerJobsData.fromJson(jsonDecode(json));
  Serializer<GetBillingWorkerJobsVariables> varsSerializer =
      (GetBillingWorkerJobsVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetBillingWorkerJobsData, GetBillingWorkerJobsVariables>>
  execute() {
    return ref().execute();
  }

  QueryRef<GetBillingWorkerJobsData, GetBillingWorkerJobsVariables> ref() {
    GetBillingWorkerJobsVariables vars = GetBillingWorkerJobsVariables(
      workerHost: workerHost,
    );
    return _dataConnect.query(
      "GetBillingWorkerJobs",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetBillingWorkerJobsJobs {
  final String id;
  final String? teamId;
  final String? latestRunId;
  GetBillingWorkerJobsJobs.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']),
      teamId = json['teamId'] == null
          ? null
          : nativeFromJson<String>(json['teamId']),
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

    final GetBillingWorkerJobsJobs otherTyped =
        other as GetBillingWorkerJobsJobs;
    return id == otherTyped.id &&
        teamId == otherTyped.teamId &&
        latestRunId == otherTyped.latestRunId;
  }

  @override
  int get hashCode =>
      Object.hashAll([id.hashCode, teamId.hashCode, latestRunId.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    if (teamId != null) {
      json['teamId'] = nativeToJson<String?>(teamId);
    }
    if (latestRunId != null) {
      json['latestRunId'] = nativeToJson<String?>(latestRunId);
    }
    return json;
  }

  GetBillingWorkerJobsJobs({
    required this.id,
    this.teamId,
    this.latestRunId,
  });
}

@immutable
class GetBillingWorkerJobsData {
  final List<GetBillingWorkerJobsJobs> jobs;
  GetBillingWorkerJobsData.fromJson(dynamic json)
    : jobs = (json['jobs'] as List<dynamic>)
          .map((e) => GetBillingWorkerJobsJobs.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingWorkerJobsData otherTyped =
        other as GetBillingWorkerJobsData;
    return jobs == otherTyped.jobs;
  }

  @override
  int get hashCode => jobs.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['jobs'] = jobs.map((e) => e.toJson()).toList();
    return json;
  }

  GetBillingWorkerJobsData({
    required this.jobs,
  });
}

@immutable
class GetBillingWorkerJobsVariables {
  final String workerHost;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetBillingWorkerJobsVariables.fromJson(Map<String, dynamic> json)
    : workerHost = nativeFromJson<String>(json['workerHost']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingWorkerJobsVariables otherTyped =
        other as GetBillingWorkerJobsVariables;
    return workerHost == otherTyped.workerHost;
  }

  @override
  int get hashCode => workerHost.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['workerHost'] = nativeToJson<String>(workerHost);
    return json;
  }

  GetBillingWorkerJobsVariables({
    required this.workerHost,
  });
}
