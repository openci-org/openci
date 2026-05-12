// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_jobs_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuildJob _$BuildJobFromJson(Map<String, dynamic> json) => _BuildJob(
  id: json['id'] as String,
  status: $enumDecode(_$BuildJobStatusEnumMap, json['status']),
  owner: json['owner'] as String,
  repo: json['repo'] as String,
  teamId: json['teamId'] as String?,
  workflowId: json['workflowId'] as String?,
  workflowName: json['workflowName'] as String?,
  workflowFileName: json['workflowFileName'] as String?,
  commitSha: json['commitSha'] as String?,
  pullRequestNumber: (json['pullRequestNumber'] as num?)?.toInt(),
  runCount: (json['runCount'] as num?)?.toInt(),
  latestRunId: json['latestRunId'] as String?,
  tagName: json['tagName'] as String?,
  branch: json['branch'] as String?,
  jobKey: json['jobKey'] as String?,
  workflowRunId: json['workflowRunId'] as String?,
  needs: (json['needs'] as List<dynamic>?)?.map((e) => e as String).toList(),
  failureSummary: json['failureSummary'] as String?,
  failureSummaryModel: json['failureSummaryModel'] as String?,
  failureSummaryStatus: json['failureSummaryStatus'] as String?,
  failureSummaryDurationMs: (json['failureSummaryDurationMs'] as num?)?.toInt(),
  createdAt: const DateTimeConverter().fromJson(json['createdAt'] as Object),
  updatedAt: const DateTimeConverter().fromJson(json['updatedAt'] as Object),
  completedAt: _$JsonConverterFromJson<Object, DateTime>(
    json['completedAt'],
    const DateTimeConverter().fromJson,
  ),
);

Map<String, dynamic> _$BuildJobToJson(_BuildJob instance) => <String, dynamic>{
  'id': instance.id,
  'status': _$BuildJobStatusEnumMap[instance.status]!,
  'owner': instance.owner,
  'repo': instance.repo,
  'teamId': instance.teamId,
  'workflowId': instance.workflowId,
  'workflowName': instance.workflowName,
  'workflowFileName': instance.workflowFileName,
  'commitSha': instance.commitSha,
  'pullRequestNumber': instance.pullRequestNumber,
  'runCount': instance.runCount,
  'latestRunId': instance.latestRunId,
  'tagName': instance.tagName,
  'branch': instance.branch,
  'jobKey': instance.jobKey,
  'workflowRunId': instance.workflowRunId,
  'needs': instance.needs,
  'failureSummary': instance.failureSummary,
  'failureSummaryModel': instance.failureSummaryModel,
  'failureSummaryStatus': instance.failureSummaryStatus,
  'failureSummaryDurationMs': instance.failureSummaryDurationMs,
  'createdAt': const DateTimeConverter().toJson(instance.createdAt),
  'updatedAt': const DateTimeConverter().toJson(instance.updatedAt),
  'completedAt': _$JsonConverterToJson<Object, DateTime>(
    instance.completedAt,
    const DateTimeConverter().toJson,
  ),
};

const _$BuildJobStatusEnumMap = {
  BuildJobStatus.WAITING: 'WAITING',
  BuildJobStatus.QUEUED: 'QUEUED',
  BuildJobStatus.IN_PROGRESS: 'IN_PROGRESS',
  BuildJobStatus.SUCCESS: 'SUCCESS',
  BuildJobStatus.FAILURE: 'FAILURE',
  BuildJobStatus.CANCELLED: 'CANCELLED',
  BuildJobStatus.SKIPPED: 'SKIPPED',
  BuildJobStatus.TIMED_OUT: 'TIMED_OUT',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BuildJobs)
final buildJobsProvider = BuildJobsProvider._();

final class BuildJobsProvider
    extends $StreamNotifierProvider<BuildJobs, List<BuildJob>> {
  BuildJobsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'buildJobsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$buildJobsHash();

  @$internal
  @override
  BuildJobs create() => BuildJobs();
}

String _$buildJobsHash() => r'a0dec681577d38e0f608848e6a725a9c0c6cb6bb';

abstract class _$BuildJobs extends $StreamNotifier<List<BuildJob>> {
  Stream<List<BuildJob>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<BuildJob>>, List<BuildJob>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<BuildJob>>, List<BuildJob>>,
              AsyncValue<List<BuildJob>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(buildJobById)
final buildJobByIdProvider = BuildJobByIdFamily._();

final class BuildJobByIdProvider
    extends
        $FunctionalProvider<AsyncValue<BuildJob?>, BuildJob?, Stream<BuildJob?>>
    with $FutureModifier<BuildJob?>, $StreamProvider<BuildJob?> {
  BuildJobByIdProvider._({
    required BuildJobByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'buildJobByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$buildJobByIdHash();

  @override
  String toString() {
    return r'buildJobByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<BuildJob?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<BuildJob?> create(Ref ref) {
    final argument = this.argument as String;
    return buildJobById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BuildJobByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$buildJobByIdHash() => r'35326cdd3f2be0ba48daf213a85099f60b4f83df';

final class BuildJobByIdFamily extends $Family
    with $FunctionalFamilyOverride<Stream<BuildJob?>, String> {
  BuildJobByIdFamily._()
    : super(
        retry: null,
        name: r'buildJobByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BuildJobByIdProvider call(String buildJobId) =>
      BuildJobByIdProvider._(argument: buildJobId, from: this);

  @override
  String toString() => r'buildJobByIdProvider';
}

@ProviderFor(workflowName)
final workflowNameProvider = WorkflowNameFamily._();

final class WorkflowNameProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  WorkflowNameProvider._({
    required WorkflowNameFamily super.from,
    required BuildJob super.argument,
  }) : super(
         retry: null,
         name: r'workflowNameProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workflowNameHash();

  @override
  String toString() {
    return r'workflowNameProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as BuildJob;
    return workflowName(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkflowNameProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workflowNameHash() => r'07633eebc89139fcd641639d010777ca4a97f3c2';

final class WorkflowNameFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, BuildJob> {
  WorkflowNameFamily._()
    : super(
        retry: null,
        name: r'workflowNameProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkflowNameProvider call(BuildJob buildJob) =>
      WorkflowNameProvider._(argument: buildJob, from: this);

  @override
  String toString() => r'workflowNameProvider';
}

@ProviderFor(runDuration)
final runDurationProvider = RunDurationFamily._();

final class RunDurationProvider
    extends
        $FunctionalProvider<AsyncValue<Duration?>, Duration?, Stream<Duration?>>
    with $FutureModifier<Duration?>, $StreamProvider<Duration?> {
  RunDurationProvider._({
    required RunDurationFamily super.from,
    required BuildJob super.argument,
  }) : super(
         retry: null,
         name: r'runDurationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$runDurationHash();

  @override
  String toString() {
    return r'runDurationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Duration?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Duration?> create(Ref ref) {
    final argument = this.argument as BuildJob;
    return runDuration(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RunDurationProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$runDurationHash() => r'23723096ca7c2054b11f75794f67269463db89d0';

final class RunDurationFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Duration?>, BuildJob> {
  RunDurationFamily._()
    : super(
        retry: null,
        name: r'runDurationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RunDurationProvider call(BuildJob buildJob) =>
      RunDurationProvider._(argument: buildJob, from: this);

  @override
  String toString() => r'runDurationProvider';
}
