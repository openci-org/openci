// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workflow_list_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WorkflowListItem _$WorkflowListItemFromJson(Map<String, dynamic> json) =>
    _WorkflowListItem(
      id: json['id'] as String,
      name: json['name'] as String,
      orgId: json['orgId'] as String,
      yamlDefinition: json['yamlDefinition'] as String,
      triggerSummary: json['triggerSummary'] as String,
      repository: json['repository'] as String,
      branch: json['branch'] as String? ?? 'main',
      filePath: json['filePath'] as String? ?? '.openci/workflow.yaml',
      commitSha: json['commitSha'] as String?,
      lastBuildStatus: json['lastBuildStatus'] as String?,
      lastBuildAt: json['lastBuildAt'] == null
          ? null
          : DateTime.parse(json['lastBuildAt'] as String),
      createdAt: const DateTimeConverter().fromJson(json['createdAt']),
      updatedAt: const DateTimeConverter().fromJson(json['updatedAt']),
    );

Map<String, dynamic> _$WorkflowListItemToJson(_WorkflowListItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'orgId': instance.orgId,
      'yamlDefinition': instance.yamlDefinition,
      'triggerSummary': instance.triggerSummary,
      'repository': instance.repository,
      'branch': instance.branch,
      'filePath': instance.filePath,
      'commitSha': instance.commitSha,
      'lastBuildStatus': instance.lastBuildStatus,
      'lastBuildAt': instance.lastBuildAt?.toIso8601String(),
      'createdAt': const DateTimeConverter().toJson(instance.createdAt),
      'updatedAt': const DateTimeConverter().toJson(instance.updatedAt),
    };

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WorkflowList)
final workflowListProvider = WorkflowListProvider._();

final class WorkflowListProvider
    extends $AsyncNotifierProvider<WorkflowList, List<WorkflowListItem>> {
  WorkflowListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workflowListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workflowListHash();

  @$internal
  @override
  WorkflowList create() => WorkflowList();
}

String _$workflowListHash() => r'3a6c405ce6805814ae7fb2a85ad082b2c87026f8';

abstract class _$WorkflowList extends $AsyncNotifier<List<WorkflowListItem>> {
  FutureOr<List<WorkflowListItem>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<WorkflowListItem>>, List<WorkflowListItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<WorkflowListItem>>,
                List<WorkflowListItem>
              >,
              AsyncValue<List<WorkflowListItem>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
