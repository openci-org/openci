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
  commitSha: json['commitSha'] as String?,
  pullRequestNumber: (json['pullRequestNumber'] as num?)?.toInt(),
  runCount: (json['runCount'] as num?)?.toInt(),
  latestRunId: json['latestRunId'] as String?,
  tagName: json['tagName'] as String?,
  branch: json['branch'] as String?,
  createdAt: const DateTimeConverter().fromJson(json['createdAt']),
  updatedAt: const DateTimeConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$BuildJobToJson(_BuildJob instance) => <String, dynamic>{
  'id': instance.id,
  'status': instance.status,
  'owner': instance.owner,
  'repo': instance.repo,
  'teamId': instance.teamId,
  'workflowId': instance.workflowId,
  'commitSha': instance.commitSha,
  'pullRequestNumber': instance.pullRequestNumber,
  'runCount': instance.runCount,
  'latestRunId': instance.latestRunId,
  'tagName': instance.tagName,
  'branch': instance.branch,
  'createdAt': const DateTimeConverter().toJson(instance.createdAt),
  'updatedAt': const DateTimeConverter().toJson(instance.updatedAt),
};

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

String _$buildJobsHash() => r'd51854e8025a28e4feb9a6e952587f2a8a3b772d';

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
    required String? super.argument,
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
    final argument = this.argument as String?;
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

String _$workflowNameHash() => r'160fc57b4474630dc52db5c71b6463ab6667e34b';

final class WorkflowNameFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, String?> {
  WorkflowNameFamily._()
    : super(
        retry: null,
        name: r'workflowNameProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkflowNameProvider call(String? workflowId) =>
      WorkflowNameProvider._(argument: workflowId, from: this);

  @override
  String toString() => r'workflowNameProvider';
}
