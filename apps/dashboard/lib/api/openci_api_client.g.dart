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
          AsyncValue<OpenCIApiService>,
          OpenCIApiService,
          FutureOr<OpenCIApiService>
        >
    with $FutureModifier<OpenCIApiService>, $FutureProvider<OpenCIApiService> {
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
  $FutureProviderElement<OpenCIApiService> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<OpenCIApiService> create(Ref ref) {
    return openciApiService(ref);
  }
}

String _$openciApiServiceHash() => r'7de91b68d9a5b5f75cbab04f265c2d2275a480cb';
