// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'openci_api_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(openciApiClient)
final openciApiClientProvider = OpenciApiClientProvider._();

final class OpenciApiClientProvider
    extends
        $FunctionalProvider<
          AsyncValue<ChopperClient>,
          ChopperClient,
          FutureOr<ChopperClient>
        >
    with $FutureModifier<ChopperClient>, $FutureProvider<ChopperClient> {
  OpenciApiClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'openciApiClientProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$openciApiClientHash();

  @$internal
  @override
  $FutureProviderElement<ChopperClient> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ChopperClient> create(Ref ref) {
    return openciApiClient(ref);
  }
}

String _$openciApiClientHash() => r'c3570e5abe685ad2106f0b1486e67002858080ad';

@ProviderFor(openciApiService)
final openciApiServiceProvider = OpenciApiServiceProvider._();

final class OpenciApiServiceProvider
    extends
        $FunctionalProvider<
          AsyncValue<OpenCiApiService>,
          OpenCiApiService,
          FutureOr<OpenCiApiService>
        >
    with $FutureModifier<OpenCiApiService>, $FutureProvider<OpenCiApiService> {
  OpenciApiServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'openciApiServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$openciApiServiceHash();

  @$internal
  @override
  $FutureProviderElement<OpenCiApiService> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<OpenCiApiService> create(Ref ref) {
    return openciApiService(ref);
  }
}

String _$openciApiServiceHash() => r'530f0392c86729d81b954346c867040f5a3e7586';
