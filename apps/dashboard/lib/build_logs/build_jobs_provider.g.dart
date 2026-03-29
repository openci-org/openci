// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_jobs_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuildJob _$BuildJobFromJson(Map<String, dynamic> json) => _BuildJob(
  id: json['id'] as String,
  status: json['status'] as String,
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
  createdAt: const DateTimeConverter().fromJson(json['createdAt'] as Object),
  updatedAt: const DateTimeConverter().fromJson(json['updatedAt'] as Object),
  completedAt: _$JsonConverterFromJson<Object, DateTime>(
    json['completedAt'],
    const DateTimeConverter().fromJson,
  ),
);

Map<String, dynamic> _$BuildJobToJson(_BuildJob instance) => <String, dynamic>{
  'id': instance.id,
  'status': instance.status,
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
  'createdAt': const DateTimeConverter().toJson(instance.createdAt),
  'updatedAt': const DateTimeConverter().toJson(instance.updatedAt),
  'completedAt': _$JsonConverterToJson<Object, DateTime>(
    instance.completedAt,
    const DateTimeConverter().toJson,
  ),
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

String _$buildJobsHash() => r'766ab61033585232aa31672083cc54b7e9a71cc8';

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

String _$workflowNameHash() => r'89cac88b703712ec91685bf0ccf7a7834bb6c1a2';

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

String _$runDurationHash() => r'31cac367ccc60f3aa8ed243a17da20e03e27e4b5';

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
