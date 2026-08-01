// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_step_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(buildStepSummaries)
final buildStepSummariesProvider = BuildStepSummariesFamily._();

final class BuildStepSummariesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BuildStep>>,
          List<BuildStep>,
          FutureOr<List<BuildStep>>
        >
    with $FutureModifier<List<BuildStep>>, $FutureProvider<List<BuildStep>> {
  BuildStepSummariesProvider._({
    required BuildStepSummariesFamily super.from,
    required ({String buildJobId, String runId}) super.argument,
  }) : super(
         retry: null,
         name: r'buildStepSummariesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$buildStepSummariesHash();

  @override
  String toString() {
    return r'buildStepSummariesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<BuildStep>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<BuildStep>> create(Ref ref) {
    final argument = this.argument as ({String buildJobId, String runId});
    return buildStepSummaries(
      ref,
      buildJobId: argument.buildJobId,
      runId: argument.runId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BuildStepSummariesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$buildStepSummariesHash() =>
    r'c4a7d30ee0173eb6584bb56d2de0dcd8281f0435';

final class BuildStepSummariesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<BuildStep>>,
          ({String buildJobId, String runId})
        > {
  BuildStepSummariesFamily._()
    : super(
        retry: null,
        name: r'buildStepSummariesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BuildStepSummariesProvider call({
    required String buildJobId,
    required String runId,
  }) => BuildStepSummariesProvider._(
    argument: (buildJobId: buildJobId, runId: runId),
    from: this,
  );

  @override
  String toString() => r'buildStepSummariesProvider';
}

@ProviderFor(buildStepLogDetail)
final buildStepLogDetailProvider = BuildStepLogDetailFamily._();

final class BuildStepLogDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  BuildStepLogDetailProvider._({
    required BuildStepLogDetailFamily super.from,
    required ({String buildJobId, String runId, String stepId}) super.argument,
  }) : super(
         retry: null,
         name: r'buildStepLogDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$buildStepLogDetailHash();

  @override
  String toString() {
    return r'buildStepLogDetailProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    final argument =
        this.argument as ({String buildJobId, String runId, String stepId});
    return buildStepLogDetail(
      ref,
      buildJobId: argument.buildJobId,
      runId: argument.runId,
      stepId: argument.stepId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BuildStepLogDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$buildStepLogDetailHash() =>
    r'165a7571b581f753f5dd332cb3b09f45182e1571';

final class BuildStepLogDetailFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<String>>,
          ({String buildJobId, String runId, String stepId})
        > {
  BuildStepLogDetailFamily._()
    : super(
        retry: null,
        name: r'buildStepLogDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BuildStepLogDetailProvider call({
    required String buildJobId,
    required String runId,
    required String stepId,
  }) => BuildStepLogDetailProvider._(
    argument: (buildJobId: buildJobId, runId: runId, stepId: stepId),
    from: this,
  );

  @override
  String toString() => r'buildStepLogDetailProvider';
}

@ProviderFor(allBuildStepLogs)
final allBuildStepLogsProvider = AllBuildStepLogsFamily._();

final class AllBuildStepLogsProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  AllBuildStepLogsProvider._({
    required AllBuildStepLogsFamily super.from,
    required ({String buildJobId, String runId}) super.argument,
  }) : super(
         retry: null,
         name: r'allBuildStepLogsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$allBuildStepLogsHash();

  @override
  String toString() {
    return r'allBuildStepLogsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    final argument = this.argument as ({String buildJobId, String runId});
    return allBuildStepLogs(
      ref,
      buildJobId: argument.buildJobId,
      runId: argument.runId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AllBuildStepLogsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$allBuildStepLogsHash() => r'fad0dab4645f13a0b1d2d91d86fdc0c4ff686ce8';

final class AllBuildStepLogsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<String>,
          ({String buildJobId, String runId})
        > {
  AllBuildStepLogsFamily._()
    : super(
        retry: null,
        name: r'allBuildStepLogsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AllBuildStepLogsProvider call({
    required String buildJobId,
    required String runId,
  }) => AllBuildStepLogsProvider._(
    argument: (buildJobId: buildJobId, runId: runId),
    from: this,
  );

  @override
  String toString() => r'allBuildStepLogsProvider';
}

@ProviderFor(realtimeRunLogsStream)
final realtimeRunLogsStreamProvider = RealtimeRunLogsStreamFamily._();

final class RealtimeRunLogsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, dynamic>>,
          Map<String, dynamic>,
          Stream<Map<String, dynamic>>
        >
    with
        $FutureModifier<Map<String, dynamic>>,
        $StreamProvider<Map<String, dynamic>> {
  RealtimeRunLogsStreamProvider._({
    required RealtimeRunLogsStreamFamily super.from,
    required ({String buildJobId, String runId}) super.argument,
  }) : super(
         retry: null,
         name: r'realtimeRunLogsStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$realtimeRunLogsStreamHash();

  @override
  String toString() {
    return r'realtimeRunLogsStreamProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<Map<String, dynamic>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, dynamic>> create(Ref ref) {
    final argument = this.argument as ({String buildJobId, String runId});
    return realtimeRunLogsStream(
      ref,
      buildJobId: argument.buildJobId,
      runId: argument.runId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RealtimeRunLogsStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$realtimeRunLogsStreamHash() =>
    r'2476e9e557754c709a03454b7b5b05d2685caf07';

final class RealtimeRunLogsStreamFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<Map<String, dynamic>>,
          ({String buildJobId, String runId})
        > {
  RealtimeRunLogsStreamFamily._()
    : super(
        retry: null,
        name: r'realtimeRunLogsStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RealtimeRunLogsStreamProvider call({
    required String buildJobId,
    required String runId,
  }) => RealtimeRunLogsStreamProvider._(
    argument: (buildJobId: buildJobId, runId: runId),
    from: this,
  );

  @override
  String toString() => r'realtimeRunLogsStreamProvider';
}
