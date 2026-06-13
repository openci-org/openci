// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_job_logs_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BuildJobLogs)
final buildJobLogsProvider = BuildJobLogsFamily._();

final class BuildJobLogsProvider
    extends $StreamNotifierProvider<BuildJobLogs, List<BuildLog>> {
  BuildJobLogsProvider._({
    required BuildJobLogsFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'buildJobLogsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$buildJobLogsHash();

  @override
  String toString() {
    return r'buildJobLogsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  BuildJobLogs create() => BuildJobLogs();

  @override
  bool operator ==(Object other) {
    return other is BuildJobLogsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$buildJobLogsHash() => r'4d853b49e2a8bdf0ae7009025aa9e73ab9089baa';

final class BuildJobLogsFamily extends $Family
    with
        $ClassFamilyOverride<
          BuildJobLogs,
          AsyncValue<List<BuildLog>>,
          List<BuildLog>,
          Stream<List<BuildLog>>,
          (String, String)
        > {
  BuildJobLogsFamily._()
    : super(
        retry: null,
        name: r'buildJobLogsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BuildJobLogsProvider call(String buildJobId, String runId) =>
      BuildJobLogsProvider._(argument: (buildJobId, runId), from: this);

  @override
  String toString() => r'buildJobLogsProvider';
}

abstract class _$BuildJobLogs extends $StreamNotifier<List<BuildLog>> {
  late final _$args = ref.$arg as (String, String);
  String get buildJobId => _$args.$1;
  String get runId => _$args.$2;

  Stream<List<BuildLog>> build(String buildJobId, String runId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<BuildLog>>, List<BuildLog>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<BuildLog>>, List<BuildLog>>,
              AsyncValue<List<BuildLog>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
