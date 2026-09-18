// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_connection_api_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(activeConnectionApiClient)
final activeConnectionApiClientProvider = ActiveConnectionApiClientProvider._();

final class ActiveConnectionApiClientProvider
    extends
        $FunctionalProvider<
          AsyncValue<ChopperClient>,
          ChopperClient,
          FutureOr<ChopperClient>
        >
    with $FutureModifier<ChopperClient>, $FutureProvider<ChopperClient> {
  ActiveConnectionApiClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeConnectionApiClientProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeConnectionApiClientHash();

  @$internal
  @override
  $FutureProviderElement<ChopperClient> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ChopperClient> create(Ref ref) {
    return activeConnectionApiClient(ref);
  }
}

String _$activeConnectionApiClientHash() =>
    r'147953466247792babec275f6b55ab0eec1063d2';
