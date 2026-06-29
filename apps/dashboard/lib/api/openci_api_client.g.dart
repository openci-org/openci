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
    extends $FunctionalProvider<ChopperClient, ChopperClient, ChopperClient>
    with $Provider<ChopperClient> {
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
  $ProviderElement<ChopperClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChopperClient create(Ref ref) {
    return openciApiClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChopperClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChopperClient>(value),
    );
  }
}

String _$openciApiClientHash() => r'4e3551f8235459e277cf070dd135c8bbf01a329d';

@ProviderFor(openciApiService)
final openciApiServiceProvider = OpenciApiServiceProvider._();

final class OpenciApiServiceProvider
    extends
        $FunctionalProvider<
          OpenCiApiService,
          OpenCiApiService,
          OpenCiApiService
        >
    with $Provider<OpenCiApiService> {
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
  $ProviderElement<OpenCiApiService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OpenCiApiService create(Ref ref) {
    return openciApiService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OpenCiApiService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OpenCiApiService>(value),
    );
  }
}

String _$openciApiServiceHash() => r'96895aa2b5dbc9cc0859f05f36bd72824c1c257a';
