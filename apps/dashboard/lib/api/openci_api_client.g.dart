// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'openci_api_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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

String _$openciApiServiceHash() => r'c33cdecc69a20d39d1048823fdee7fde48d7f264';
