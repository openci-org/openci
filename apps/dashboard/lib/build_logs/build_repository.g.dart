// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(buildRepository)
final buildRepositoryProvider = BuildRepositoryProvider._();

final class BuildRepositoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<BuildRepository>,
          BuildRepository,
          FutureOr<BuildRepository>
        >
    with $FutureModifier<BuildRepository>, $FutureProvider<BuildRepository> {
  BuildRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'buildRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$buildRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<BuildRepository> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<BuildRepository> create(Ref ref) {
    return buildRepository(ref);
  }
}

String _$buildRepositoryHash() => r'334b86e0db1818efc4ed8cbef4c55ecc3a817de4';
