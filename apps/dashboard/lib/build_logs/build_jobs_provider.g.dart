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
  commitSha: json['commitSha'] as String?,
  pullRequestNumber: (json['pullRequestNumber'] as num?)?.toInt(),
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
  'commitSha': instance.commitSha,
  'pullRequestNumber': instance.pullRequestNumber,
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

String _$buildJobsHash() => r'876197af16100141271f18f40613a3d1e8b1d8c9';

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
