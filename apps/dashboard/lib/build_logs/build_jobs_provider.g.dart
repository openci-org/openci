// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_jobs_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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

String _$buildJobByIdHash() => r'59ac94384ae967630ac7759405dde65c7b019940';

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
