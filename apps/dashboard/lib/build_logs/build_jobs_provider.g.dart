// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_jobs_provider.dart';

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

String _$buildJobsHash() => r'800e66539f2d96f85d8c0a32f554ddde55132a07';

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

@ProviderFor(OtaBuildJobs)
final otaBuildJobsProvider = OtaBuildJobsProvider._();

final class OtaBuildJobsProvider
    extends $StreamNotifierProvider<OtaBuildJobs, List<BuildJob>> {
  OtaBuildJobsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'otaBuildJobsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$otaBuildJobsHash();

  @$internal
  @override
  OtaBuildJobs create() => OtaBuildJobs();
}

String _$otaBuildJobsHash() => r'a57525e69d2400ee46f0c886a829ba8e547db116';

abstract class _$OtaBuildJobs extends $StreamNotifier<List<BuildJob>> {
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

@ProviderFor(buildJobById)
final buildJobByIdProvider = BuildJobByIdFamily._();

final class BuildJobByIdProvider
    extends
        $FunctionalProvider<AsyncValue<BuildJob?>, BuildJob?, Stream<BuildJob?>>
    with $FutureModifier<BuildJob?>, $StreamProvider<BuildJob?> {
  BuildJobByIdProvider._({
    required BuildJobByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'buildJobByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$buildJobByIdHash();

  @override
  String toString() {
    return r'buildJobByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<BuildJob?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<BuildJob?> create(Ref ref) {
    final argument = this.argument as String;
    return buildJobById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BuildJobByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$buildJobByIdHash() => r'c1ce631e86c3f1e31b0b54f95492f262ee3b3302';

final class BuildJobByIdFamily extends $Family
    with $FunctionalFamilyOverride<Stream<BuildJob?>, String> {
  BuildJobByIdFamily._()
    : super(
        retry: null,
        name: r'buildJobByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BuildJobByIdProvider call(String buildJobId) =>
      BuildJobByIdProvider._(argument: buildJobId, from: this);

  @override
  String toString() => r'buildJobByIdProvider';
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

String _$runDurationHash() => r'ba337f70f379080b9c8bf5ccce034a8fa48bcfc2';

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
