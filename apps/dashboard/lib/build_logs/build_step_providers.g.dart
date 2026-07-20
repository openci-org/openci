// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../cicd_log/detail/build_step_providers.dart';

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
          AsyncValue<List<BuildStepSummary>>,
          List<BuildStepSummary>,
          FutureOr<List<BuildStepSummary>>
        >
    with
        $FutureModifier<List<BuildStepSummary>>,
        $FutureProvider<List<BuildStepSummary>> {
  BuildStepSummariesProvider._({
    required BuildStepSummariesFamily super.from,
    required String super.argument,
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
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<BuildStepSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<BuildStepSummary>> create(Ref ref) {
    final argument = this.argument as String;
    return buildStepSummaries(ref, argument);
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
    r'5ccd91fe2c206dc9f590750587cd1cc626baa726';

final class BuildStepSummariesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<BuildStepSummary>>, String> {
  BuildStepSummariesFamily._()
    : super(
        retry: null,
        name: r'buildStepSummariesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BuildStepSummariesProvider call(String buildJobId) =>
      BuildStepSummariesProvider._(argument: buildJobId, from: this);

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
    required String super.argument,
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
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    final argument = this.argument as String;
    return buildStepLogDetail(ref, argument);
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
    r'498ff1a4a85024504e5c08bdf34eb5a7975ff65e';

final class BuildStepLogDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<String>>, String> {
  BuildStepLogDetailFamily._()
    : super(
        retry: null,
        name: r'buildStepLogDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BuildStepLogDetailProvider call(String stepId) =>
      BuildStepLogDetailProvider._(argument: stepId, from: this);

  @override
  String toString() => r'buildStepLogDetailProvider';
}
