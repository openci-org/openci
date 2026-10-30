// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_step_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(buildRunLogs)
final buildRunLogsProvider = BuildRunLogsFamily._();

final class BuildRunLogsProvider
    extends $FunctionalProvider<AsyncValue<RunLogs>, RunLogs, Stream<RunLogs>>
    with $FutureModifier<RunLogs>, $StreamProvider<RunLogs> {
  BuildRunLogsProvider._({
    required BuildRunLogsFamily super.from,
    required ({String buildJobId, String runId}) super.argument,
  }) : super(
         retry: null,
         name: r'buildRunLogsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$buildRunLogsHash();

  @override
  String toString() {
    return r'buildRunLogsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<RunLogs> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<RunLogs> create(Ref ref) {
    final argument = this.argument as ({String buildJobId, String runId});
    return buildRunLogs(
      ref,
      buildJobId: argument.buildJobId,
      runId: argument.runId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BuildRunLogsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$buildRunLogsHash() => r'59cb74e80dc4e02b123eef3022f2e27281ec4459';

final class BuildRunLogsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<RunLogs>,
          ({String buildJobId, String runId})
        > {
  BuildRunLogsFamily._()
    : super(
        retry: null,
        name: r'buildRunLogsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BuildRunLogsProvider call({
    required String buildJobId,
    required String runId,
  }) => BuildRunLogsProvider._(
    argument: (buildJobId: buildJobId, runId: runId),
    from: this,
  );

  @override
  String toString() => r'buildRunLogsProvider';
}

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
    r'f3ff514f409ba007fc81942ee8e30b13bad64c78';

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
    r'b83875399aff82bf4d23f0995cdbbb2994b9d991';

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

String _$allBuildStepLogsHash() => r'2d73a79433250772034b2e651c0a48f818da55c6';

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
