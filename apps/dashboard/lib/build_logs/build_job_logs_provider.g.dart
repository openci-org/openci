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
    required (String, String, BuildJobStatus) super.argument,
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

String _$buildJobLogsHash() => r'7e0753ceb0a24ca9b5df5cfaf514279fdb3a9759';

final class BuildJobLogsFamily extends $Family
    with
        $ClassFamilyOverride<
          BuildJobLogs,
          AsyncValue<List<BuildLog>>,
          List<BuildLog>,
          Stream<List<BuildLog>>,
          (String, String, BuildJobStatus)
        > {
  BuildJobLogsFamily._()
    : super(
        retry: null,
        name: r'buildJobLogsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BuildJobLogsProvider call(
    String buildJobId,
    String runId,
    BuildJobStatus buildStatus,
  ) => BuildJobLogsProvider._(
    argument: (buildJobId, runId, buildStatus),
    from: this,
  );

  @override
  String toString() => r'buildJobLogsProvider';
}

abstract class _$BuildJobLogs extends $StreamNotifier<List<BuildLog>> {
  late final _$args = ref.$arg as (String, String, BuildJobStatus);
  String get buildJobId => _$args.$1;
  String get runId => _$args.$2;
  BuildJobStatus get buildStatus => _$args.$3;

  Stream<List<BuildLog>> build(
    String buildJobId,
    String runId,
    BuildJobStatus buildStatus,
  );
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
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2, _$args.$3));
  }
}
