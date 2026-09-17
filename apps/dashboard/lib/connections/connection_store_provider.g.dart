// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection_store_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(connectionStore)
final connectionStoreProvider = ConnectionStoreProvider._();

final class ConnectionStoreProvider
    extends
        $FunctionalProvider<ConnectionStore, ConnectionStore, ConnectionStore>
    with $Provider<ConnectionStore> {
  ConnectionStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'connectionStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$connectionStoreHash();

  @$internal
  @override
  $ProviderElement<ConnectionStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ConnectionStore create(Ref ref) {
    return connectionStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConnectionStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConnectionStore>(value),
    );
  }
}

String _$connectionStoreHash() => r'0f7234e5ba91825c6b91ff70829581d54d7ad2c9';
