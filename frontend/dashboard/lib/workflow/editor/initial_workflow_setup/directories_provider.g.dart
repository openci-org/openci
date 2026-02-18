// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'directories_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(selectedRepository)
final selectedRepositoryProvider = SelectedRepositoryProvider._();

final class SelectedRepositoryProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  SelectedRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedRepositoryHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return selectedRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$selectedRepositoryHash() =>
    r'a4e20dc42f5d72bbb6dd7e5b1a0b3e858b2385ae';

@ProviderFor(directories)
final directoriesProvider = DirectoriesProvider._();

final class DirectoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  DirectoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'directoriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$directoriesHash();

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    return directories(ref);
  }
}

String _$directoriesHash() => r'6a6f37df49392b831c9bec1db1083a2e1c6a1bb8';
