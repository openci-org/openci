part of 'billing.dart';

class GetBillingJobVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  GetBillingJobVariablesBuilder(
    this._dataConnect, {
    required this.id,
  });
  Deserializer<GetBillingJobData> dataDeserializer = (dynamic json) =>
      GetBillingJobData.fromJson(jsonDecode(json));
  Serializer<GetBillingJobVariables> varsSerializer =
      (GetBillingJobVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetBillingJobData, GetBillingJobVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetBillingJobData, GetBillingJobVariables> ref() {
    GetBillingJobVariables vars = GetBillingJobVariables(
      id: id,
    );
    return _dataConnect.query(
      "GetBillingJob",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetBillingJobJob {
  final String id;
  final String? teamId;
  final String status;
  final String? workerHost;
  final String? latestRunId;
  GetBillingJobJob.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']),
      teamId = json['teamId'] == null
          ? null
          : nativeFromJson<String>(json['teamId']),
      status = nativeFromJson<String>(json['status']),
      workerHost = json['workerHost'] == null
          ? null
          : nativeFromJson<String>(json['workerHost']),
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

    final GetBillingJobJob otherTyped = other as GetBillingJobJob;
    return id == otherTyped.id &&
        teamId == otherTyped.teamId &&
        status == otherTyped.status &&
        workerHost == otherTyped.workerHost &&
        latestRunId == otherTyped.latestRunId;
  }

  @override
  int get hashCode => Object.hashAll([
    id.hashCode,
    teamId.hashCode,
    status.hashCode,
    workerHost.hashCode,
    latestRunId.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    if (teamId != null) {
      json['teamId'] = nativeToJson<String?>(teamId);
    }
    json['status'] = nativeToJson<String>(status);
    if (workerHost != null) {
      json['workerHost'] = nativeToJson<String?>(workerHost);
    }
    if (latestRunId != null) {
      json['latestRunId'] = nativeToJson<String?>(latestRunId);
    }
    return json;
  }

  GetBillingJobJob({
    required this.id,
    this.teamId,
    required this.status,
    this.workerHost,
    this.latestRunId,
  });
}

@immutable
class GetBillingJobData {
  final GetBillingJobJob? job;
  GetBillingJobData.fromJson(dynamic json)
    : job = json['job'] == null ? null : GetBillingJobJob.fromJson(json['job']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingJobData otherTyped = other as GetBillingJobData;
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

  GetBillingJobData({
    this.job,
  });
}

@immutable
class GetBillingJobVariables {
  final String id;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetBillingJobVariables.fromJson(Map<String, dynamic> json)
    : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBillingJobVariables otherTyped = other as GetBillingJobVariables;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetBillingJobVariables({
    required this.id,
  });
}
