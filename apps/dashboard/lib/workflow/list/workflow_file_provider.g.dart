// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workflow_file_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WorkflowFile _$WorkflowFileFromJson(Map<String, dynamic> json) =>
    _WorkflowFile(
      name: json['name'] as String,
      path: json['path'] as String,
      content: json['content'] as String,
      repository: json['repository'] as String,
      branch: json['branch'] as String,
    );

Map<String, dynamic> _$WorkflowFileToJson(_WorkflowFile instance) =>
    <String, dynamic>{
      'name': instance.name,
      'path': instance.path,
      'content': instance.content,
      'repository': instance.repository,
      'branch': instance.branch,
    };

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workflowFiles)
final workflowFilesProvider = WorkflowFilesProvider._();

final class WorkflowFilesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WorkflowFile>>,
          List<WorkflowFile>,
          FutureOr<List<WorkflowFile>>
        >
    with
        $FutureModifier<List<WorkflowFile>>,
        $FutureProvider<List<WorkflowFile>> {
  WorkflowFilesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workflowFilesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workflowFilesHash();

  @$internal
  @override
  $FutureProviderElement<List<WorkflowFile>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<WorkflowFile>> create(Ref ref) {
    return workflowFiles(ref);
  }
}

String _$workflowFilesHash() => r'8dd3aef625e9f0d04543c94387e7b95b0c0bd08b';
