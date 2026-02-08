// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logs_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuildJob _$BuildJobFromJson(Map<String, dynamic> json) => _BuildJob(
  id: json['id'] as String,
  status: json['status'] as String,
  owner: json['owner'] as String,
  repo: json['repo'] as String,
  teamId: json['teamId'] as String?,
  commitSha: json['commitSha'] as String?,
  pullRequestNumber: (json['pullRequestNumber'] as num?)?.toInt(),
  runCount: (json['runCount'] as num?)?.toInt(),
  latestRunId: json['latestRunId'] as String?,
  createdAt: const DateTimeConverter().fromJson(json['createdAt']),
  updatedAt: const DateTimeConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$BuildJobToJson(_BuildJob instance) => <String, dynamic>{
  'id': instance.id,
  'status': instance.status,
  'owner': instance.owner,
  'repo': instance.repo,
  'teamId': instance.teamId,
  'commitSha': instance.commitSha,
  'pullRequestNumber': instance.pullRequestNumber,
  'runCount': instance.runCount,
  'latestRunId': instance.latestRunId,
  'createdAt': const DateTimeConverter().toJson(instance.createdAt),
  'updatedAt': const DateTimeConverter().toJson(instance.updatedAt),
};

_BuildLog _$BuildLogFromJson(Map<String, dynamic> json) => _BuildLog(
  message: json['message'] as String,
  level: json['level'] as String,
  timestamp: const DateTimeConverter().fromJson(json['timestamp']),
);

Map<String, dynamic> _$BuildLogToJson(_BuildLog instance) => <String, dynamic>{
  'message': instance.message,
  'level': instance.level,
  'timestamp': _$JsonConverterToJson<dynamic, DateTime>(
    instance.timestamp,
    const DateTimeConverter().toJson,
  ),
};

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(buildJobsList)
final buildJobsListProvider = BuildJobsListProvider._();

final class BuildJobsListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BuildJob>>,
          List<BuildJob>,
          Stream<List<BuildJob>>
        >
    with $FutureModifier<List<BuildJob>>, $StreamProvider<List<BuildJob>> {
  BuildJobsListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'buildJobsListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$buildJobsListHash();

  @$internal
  @override
  $StreamProviderElement<List<BuildJob>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<BuildJob>> create(Ref ref) {
    return buildJobsList(ref);
  }
}

String _$buildJobsListHash() => r'9dacad2d62525ac9c4bfe9c74b8d12a97eea18e4';

@ProviderFor(buildLogs)
final buildLogsProvider = BuildLogsFamily._();

final class BuildLogsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BuildLog>>,
          List<BuildLog>,
          Stream<List<BuildLog>>
        >
    with $FutureModifier<List<BuildLog>>, $StreamProvider<List<BuildLog>> {
  BuildLogsProvider._({
    required BuildLogsFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'buildLogsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$buildLogsHash();

  @override
  String toString() {
    return r'buildLogsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<List<BuildLog>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<BuildLog>> create(Ref ref) {
    final argument = this.argument as (String, String);
    return buildLogs(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is BuildLogsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$buildLogsHash() => r'55b7b69b0cf6c73b3a52888305ecbd9b5cedd765';

final class BuildLogsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<BuildLog>>, (String, String)> {
  BuildLogsFamily._()
    : super(
        retry: null,
        name: r'buildLogsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BuildLogsProvider call(String buildJobId, String runId) =>
      BuildLogsProvider._(argument: (buildJobId, runId), from: this);

  @override
  String toString() => r'buildLogsProvider';
}
